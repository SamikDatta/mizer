# Initialise --------------------------------------------------------------

# North sea
params <- newMultispeciesParams(NS_species_params_gears, inter,
                                n = 2/3, p = 0.7, lambda = 2.8 - 2/3,
                                info_level = 0)
no_gear <- dim(params@catchability)[1]
no_sp <- dim(params@catchability)[2]
no_w <- length(params@w)
no_w_full <- length(params@w_full)
sim <- project(params, effort = 1, t_max = 20, dt = 0.5, t_save = 0.5)

# Rescaled
params_r <- params
volume <- 1e-13
params_r@initial_n <- params@initial_n * volume
params_r@initial_n_pp <- params@initial_n_pp * volume
for (res in names(params@initial_n_other)) {
    params_r@initial_n_other[[res]] <- params@initial_n_other[[res]] * volume
}

params_r@species_params$gamma <- params@species_params$gamma / volume
params_r <- setSearchVolume(params_r)
params_r@species_params$R_max <- params_r@species_params$R_max * volume

# Random abundances
set.seed(0)
n <- abs(array(rnorm(no_w * no_sp), dim = c(no_sp, no_w))) * 1e9
n_full <- abs(rnorm(no_w_full)) * 1e9

params2 <- params
params2@initial_n <- params2@initial_n / 2
params2@initial_n_pp <- params2@initial_n_pp / 2
params2@initial_n_other <- list(test = 1)
params2@initial_effort <- params2@initial_effort / 2

# getRates ----
test_that("getRates works", {
    r <- getRates(params)
    expect_identical(names(r), 
                     c("encounter", "feeding_level", "e", "e_repro", 
                       "e_growth", "pred_rate", "pred_mort", "f_mort",
                       "mort", "rdi", "rdd", "resource_mort"))
    # test that the optional parameters take the correct defaults
    expect_identical(r, 
                     getRates(params, n = params@initial_n,
                              n_pp = params@initial_n_pp,
                              n_other  = params@initial_n_other, 
                              effort = params@initial_effort,
                              t = 0))
    # test that getRates actually uses its optional arguments
    expect_identical(getRates(params2), 
                     getRates(params, n = params2@initial_n,
                              n_pp = params2@initial_n_pp,
                              n_other  = params2@initial_n_other, 
                              effort = params2@initial_effort,
                              t = 0))
})

# getEncounter --------------------------------------------------------------

test_that("getEncounter returns with correct dimnames", {
    enc <- getEncounter(params)
    expect_identical(dimnames(enc), 
                     dimnames(params@initial_n))
})
test_that("mizerEncounter is independent of volume", {
    enc <- getEncounter(params)
    enc_r <- getEncounter(params_r)
    expect_equal(enc, enc_r)
})
test_that("External encounter is included", {
    enc <- getEncounter(params)
    # add something of the right dimension
    extra_enc <- params@mu_b
    ext_encounter(params) <- ext_encounter(params) + extra_enc
    expect_identical(getEncounter(params), enc + extra_enc)
})

# getFeedingLevel -----------------------------------------

test_that("getFeedingLevel for MizerParams", {
    fl <- getFeedingLevel(params, n, n_full)
    # test dim
    expect_identical(dim(fl), c(no_sp, no_w))
    expect_identical(dimnames(fl), dimnames(params@initial_n))
    # A crap test - just returns what's already in the function
    encounter <- getEncounter(params, n = n, n_pp = n_full)
    f <- encounter / (encounter + params@intake_max)
    expect_identical(fl, f)
    # test value
    # expect_known_value(fl, "values/getFeedingLevel")
    # expect_snapshot(round(fl, 5)) # round to take into account different rounding errors depending on OS
    expect_snapshot_value(fl, style = 'json2', tolerance = 1e-5) # round to take into account different rounding errors depending on OS
})

test_that("getFeedingLevel for MizerSim", {
    time_range <- 15:20
    fl <- getFeedingLevel(sim, time_range = time_range)
    expect_length(dim(fl), 3)
    # because t_save is 0.5, there should be 11 time steps in the range 15:20
    expect_equal(dim(fl), c(11, dim(params@initial_n)))
    expect_identical(dimnames(fl)$sp, dimnames(params@initial_n)$sp)
    expect_identical(dimnames(fl)$w, dimnames(params@initial_n)$w)
    time_range <- 20
    expect_length(dim(getFeedingLevel(sim, time_range = time_range)), 3)
    expect_identical(
        getFeedingLevel(sim, time_range = time_range)[1, , ],
        getFeedingLevel(sim@params, sim@n[as.character(time_range), , ], 
                        sim@n_pp[as.character(time_range), ])
    )
})

test_that("getFeedingLevel passes correct time", {
    # Here we will check that when getFeedingLevel() is called with
    # a sim object, it passes the correct values of t and n at each time step.
    # To do this we replace mizerFeedingLevel() with a simpler function that
    # just returns t * n
    time_range <- 15:20
    time_elements <- get_time_elements(sim, time_range)
    times <- as.numeric(dimnames(sim@effort)$time[time_elements])
    e <- globalenv() # We need to define the following functions in the
    # global environment so that mizer can find them
    e$testFeedingLevel <- function(params, n, t, ...) {
        n * t
    }
    sim@params <- setRateFunction(sim@params, "FeedingLevel", 
                                  "testFeedingLevel")
    expect_identical(getFeedingLevel(sim, time_range = time_range),
                     sweep(sim@n[time_elements, , ], 1, times, "*"))
})

test_that("getFeedingLevel is independent of volume", {
    fl <- getFeedingLevel(params)
    fl_r <- getFeedingLevel(params_r)
    expect_equal(fl, fl_r)
})

# getPredRate -------------------------------------------------------------

test_that("getPredRate for MizerParams", {
    pr <- getPredRate(params, n, n_full)
    # test dim
    expect_identical(dim(pr), c(no_sp, no_w_full))
    expect_identical(dimnames(pr)$sp, dimnames(params@initial_n)$sp)
    expect_identical(dimnames(pr)$w_prey, as.character(signif(params@w_full, 3)))
    # test value
    # expect_known_value(pr, "values/getPredRate")
    # expect_snapshot(pr)
    expect_snapshot_value(pr, style = 'json2', tolerance = 1e-5) # round to take into account different rounding errors depending on OS
})

test_that("getPredRate is independent of volume", {
    pr <- getPredRate(params)
    pr_r <- getPredRate(params_r)
    expect_equal(pr, pr_r)
})


# getPredMort -------------------------------------------------------------------

test_that("getPredMort for MizerParams", {
    # Randomize selectivity and catchability for proper test
    set.seed(0)
    params@catchability[] <-
        runif(prod(dim(params@catchability)), min = 0, max = 1)
    params@selectivity[] <-
        runif(prod(dim(params@selectivity)), min = 0, max = 1)
    m <- getPredMort(params, n, n_full)
    # expect_known_value(m, "values/getPredMort")
    # expect_snapshot(m)
    expect_snapshot_value(m, style = 'json2', tolerance = 1e-5) # round to take into account different rounding errors depending on OS
    
    # Look at numbers in a single prey
    w_offset <- no_w_full - no_w
    m2temp <- rep(NA, no_w)
    pred_rate <- getPredRate(params, n, n_full)
    sp <- runif(1, min = 1, max = no_sp)
    for (i in 1:no_w) {
        m2temp[i] <- sum(params@interaction[, sp] * pred_rate[, w_offset + i])
    }
    expect_equal(m2temp, as.numeric(m[sp, ]))
})

test_that("getPredMort for MizerSim", {
    time_range <- 15:20
    expect_length(dim(getPredMort(sim, time_range = time_range)), 3)
    time_range <- 20
    expect_length(dim(getPredMort(sim, time_range = time_range)), 2)
    ##expect_that(getPredMort(sim, time_range=time_range), equals(getPredMort(sim@params, sim@n[as.character(time_range),,], sim@n_pp[as.character(time_range),])))
    aq1 <- getPredMort(sim, time_range = time_range)
    aq2 <- getPredMort(sim@params, sim@n[as.character(time_range), , ],
                 sim@n_pp[as.character(time_range), ])
    
    ttot <- 0
    for (i in seq_len(dim(aq1)[1])) {
        ttot <- ttot + sum(aq1[i, ] != aq2[i, ])
    }
    
    expect_equal(ttot, 0)
})

test_that("getPredMort passes correct time", {
    # Here we will check that when getPredMort() is called with
    # a sim object, it passes the correct values of t and n at each time step.
    # To do this we replace mizerFeedingLevel() with a simpler function that
    # just returns t * n
    times <- as.numeric(dimnames(sim@effort)$time)
    e <- globalenv() # We need to define the following functions in the
    # global environment so that mizer can find them
    e$testPredMort <- function(params, n, n_pp, t, ...) {
        n * t
    }
    sim@params <- setRateFunction(sim@params, "PredMort", 
                                  "testPredMort")
    expect_identical(unname(getPredMort(sim)),
                     unname(sweep(sim@n, 1, times, "*")))
})

test_that("interaction is right way round in getPredMort function", {
    inter[, "Dab"] <- 0  # Dab not eaten by anything
    params <- newMultispeciesParams(NS_species_params_gears, inter, info_level = 0)
    m2 <- getPredMort(params, get_initial_n(params), params@cc_pp)
    expect_true(all(m2["Dab", ] == 0))
})

test_that("getPredMort is independent of volume", {
    pr <- getPredMort(params)
    pr_r <- getPredMort(params_r)
    expect_equal(pr, pr_r)
})


# getResourceMort ---------------------------------------------------------

test_that("getResourceMort", {
    m2 <- getResourceMort(params, n, n_full)
    # test dim
    expect_length(m2, no_w_full)
    # Check number in final prey size group
    m22 <- colSums(getPredRate(params, n, n_full))
    expect_equal(m22, m2, ignore_attr = FALSE)
    m2b1 <- getResourceMort(params, n, n_full)
    # test value
    # expect_known_value(m2b1, "values/getResourceMort")
    # expect_snapshot(m2b1)
    expect_snapshot_value(m2b1, style = 'json2', tolerance = 1e-5) # round to take into account different rounding errors depending on OS
})

test_that("getResourceMort is independent of volume", {
    pm <- getResourceMort(params)
    pm_r <- getResourceMort(params_r)
    expect_equal(pm, pm_r)
})


# getFmortGear ------------------------------------------------------------

test_that("getFmortGear", {
    # Two methods:
    # MizerParams + numeric
    # MizerParams + matrix
    # Randomize selectivity and catchability for proper test
    set.seed(0)
    params@catchability[] <-
        runif(prod(dim(params@catchability)), min = 0, max = 1)
    params@selectivity[] <-
        runif(prod(dim(params@selectivity)), min = 0, max = 1)
    no_gear <- dim(params@catchability)[1]
    no_sp <- dim(params@catchability)[2]
    no_w <- length(params@w)
    # Single numeric
    effort_num1 <- runif(1, min = 0.1, max = 1)
    # Numeric vector
    effort_num2 <- runif(no_gear, min = 0.1, max = 1)
    # Matrix (or 2D  array) - here with 7 timesteps
    effort_mat <-
        array(runif(no_gear * 7, min = 0.1, max = 1), dim = c(7, no_gear))
    # Call both methods with different effort inputs
    f1 <- getFMortGear(params, effort_num1)
    f2 <- getFMortGear(params, effort_num2)
    f3 <- getFMortGear(params, effort_mat)
    # Check dimnames are right
    expect_named(dimnames(f1), c("gear", "sp", "w"))
    expect_named(dimnames(f2), c("gear", "sp", "w"))
    expect_named(dimnames(f3)[2:4], c("gear", "sp", "w"))
    expect_identical(dim(f3), c(dim(effort_mat)[1], no_gear, no_sp, no_w))
    # check fails if effort is not right size
    bad_effort <- rep(effort_num1, no_gear - 1)
    expect_error(getFMortGear(params, bad_effort))
    # Check contents of output
    widx <- round(runif(1, min = 1, max = no_w))
    sp <- round(runif(1, min = 1, max = no_sp))
    gear <- round(runif(1, min = 1, max = no_gear))
    expect_identical(f1[gear, sp, widx],
                     effort_num1 * params@catchability[gear, sp] * 
                         params@selectivity[gear, sp, widx])
    expect_identical(f2[gear, sp, widx],
                     effort_num2[gear] * params@catchability[gear, sp] * 
                         params@selectivity[gear, sp, widx])
    expect_identical(f3[, gear, sp, widx],
                     effort_mat[, gear] * params@catchability[gear, sp] * 
                         params@selectivity[gear, sp, widx])
    # expect_known_value(f3, "values/getFMortGear")
    # expect_snapshot(f3)
    expect_snapshot_value(f3, style = 'json2', tolerance = 1e-5) # round to take into account different rounding errors depending on OS
    
    expect_equal(getFMortGear(sim)[1, 1, 1, ], 
                 getFMortGear(sim@params, effort = sim@effort[1, ])[1, 1, ])
})


# getFMort ----------------------------------------------------------------

test_that("getFMort", {
    effort1 <- 0.5
    effort2 <- rep(effort1, no_gear)
    effort3 <- array(effort1, dim = c(7, no_gear))
    f1 <- getFMort(params, effort1)
    f2 <- getFMort(params, effort2)
    f3 <- getFMort(params, effort3)
    # check that length of dims is right
    expect_identical(dim(f1), c(no_sp, no_w))
    expect_identical(dim(f2), c(no_sp, no_w))
    expect_identical(dim(f3), c(dim(effort3)[1], no_sp, no_w))
    # Check dimnames are right
    expect_named(dimnames(f3)[2:3], c("sp", "w"))
    # check fails if effort is not right size
    expect_error(getFMort(params, c(1, 2)))
    # check contents of output
    fmg1 <- getFMortGear(params, effort1)
    fmg2 <- getFMortGear(params, effort2)
    fmg3 <- getFMortGear(params, effort3)
    fmg11 <- array(0, dim = c(no_sp, no_w))
    fmg22 <- array(0, dim = c(no_sp, no_w))
    fmg33 <- array(0, dim = c(dim(effort3)[1], no_sp, no_w))
    for (i in 1:no_gear) {
        fmg11 <- fmg11 + fmg1[i, , ]
        fmg22 <- fmg22 + fmg2[i, , ]
        fmg33 <- fmg33 + fmg3[, i, , ]
    }
    expect_equal(f1, fmg11)
    expect_equal(f2, fmg22)
    expect_equal(f3, fmg33)
    # expect_known_value(f1, "values/getFMort")
    # expect_snapshot(f1)
    expect_snapshot_value(f1, style = 'json2', tolerance = 1e-5) # round to take into account different rounding errors depending on OS
})

test_that("getFMort passes correct time", {
    # Here we will check that when getFMort() calls mizerFMort().
    # it passes the correct time. To implement the test we write simple
    # replacement for mizerFMort() that puts the time
    # argument into the returned array.
    times <- as.numeric(dimnames(sim@effort)$time)
    e <- globalenv() # We need to define the following functions in the
    # global environment so that mizer can find them
    e$testFMort <- function(params, n, t, ...) {
        n * t
    }
    sim@params <- setRateFunction(sim@params, "FMort", "testFMort")
    expect_identical(getFMort(sim),
                     sweep(sim@n, 1, times, "*"))
})

test_that("getFMort passes correct time", {
    # Here we will check that when getFMort() calls getEGrowth().
    # it passes the correct time. To implement the test we write simple
    # replacements for mizerFMort() and mizerEGrowth that put the time
    # argument into the returned array.
    times <- as.numeric(dimnames(sim@effort)$time)
    e <- globalenv() # We need to define the following functions in the
    # global environment so that mizer can find them
    e$testEGrowth <- function(params, n, t, ...) {
        n * t
    }
    e$testFMort <- function(params, e_growth, pred_mort, t, ...) {
        e_growth
    }
    sim@params <- setRateFunction(sim@params, "EGrowth", "testEGrowth")
    sim@params <- setRateFunction(sim@params, "FMort", "testFMort")
    expect_identical(getFMort(sim),
                     sweep(sim@n, 1, times, "*"))
    
    # Now we do the same for when getFMort() calls getPredMort()
    e$testPredMort <- function(params, n, t, ...) {
        n * t
    }
    e$testFMort <- function(params, e_growth, pred_mort, t, ...) {
        pred_mort
    }
    sim@params <- setRateFunction(sim@params, "PredMort", "testPredMort")
    sim@params <- setRateFunction(sim@params, "FMort", "testFMort")
    expect_identical(getFMort(sim),
                     sweep(sim@n, 1, times, "*"))
})


# getMort --------------------------------------------------------------------

test_that("getMort", {
    no_gear <- dim(params@catchability)[1]
    effort1 <- 0.5
    effort2 <- rep(effort1, no_gear)
    z <- getMort(params, n, n_full, effort = effort2)
    # test dim
    expect_identical(dim(z), c(no_sp, no_w))
    expect_identical(dimnames(z)$prey, dimnames(params@initial_n)$sp)
    expect_identical(dimnames(z)$w_prey, dimnames(params@initial_n)$w)
    # Look at numbers in species 1
    f <- getFMort(params, effort2)
    m2 <- getPredMort(params, n, n_full)
    z1 <- f[1, ] + m2[1, ] + params@species_params$z0[1]
    expect_equal(z1, z[1, ])
    # expect_known_value(z, "values/getMort")
    # expect_snapshot(z)
    expect_snapshot_value(z, style = 'json2', tolerance = 1e-5) # round to take into account different rounding errors depending on OS
})

test_that("getMort is independent of volume", {
    m <- getMort(params, effort = 1)
    m_r <- getMort(params_r, effort = 1)
    expect_equal(m, m_r)
})


# getEReproAndGrowth ------------------------------------------------------

test_that("getEReproAndGrowth", {
    erg <- getEReproAndGrowth(params, n, n_full)
    # test dim
    expect_identical(dim(erg), c(no_sp, no_w))
    expect_identical(dimnames(erg), dimnames(params@initial_n))
    # Check number in final prey size group
    f <- getFeedingLevel(params, n = n, n_pp = n_full)
    e <-  (f[1, ] * params@intake_max[1, ]) * params@species_params$alpha[1]
    e <- e - params@metab[1, ]
    expect_equal(e, erg[1, ])
    # Can be used with infinite intake_max
    params@intake_max[] <- Inf
    expect_true(!any(is.na(getEReproAndGrowth(params, n = n, n_pp = n_full))))
    
    erg[erg <= 0] <- 0
    # expect_known_value(erg, "values/getEReproAndGrowth")
    # expect_snapshot(erg)
    expect_snapshot_value(erg, style = 'json2', tolerance = 1e-5) # round to take into account different rounding errors depending on OS
})

test_that("getEReproAndGrowth is independent of volume", {
    g <- getEReproAndGrowth(params)
    g_r <- getEReproAndGrowth(params_r)
    expect_equal(g, g_r)
})


# getERepro ------------------------------------------------------------

test_that("getERepro", {
    es <- getERepro(params, n, n_full)
    # test dim
    expect_identical(dim(es), c(no_sp, no_w))
    expect_identical(dimnames(es), dimnames(params@initial_n))
    
    e <- getEReproAndGrowth(params, n = n, n_pp = n_full)
    e_repro <- params@psi * e
    e_repro[e_repro <= 0] <- 0
    expect_identical(es, e_repro)
    e_growth <- getEGrowth(params, n, n_full)
    e_growth_man <- e - es
    e_growth_man[e_growth_man <= 0] <- 0
    expect_identical(e_growth, e_growth_man)
    # expect_known_value(es, "values/getERepro")
    # expect_snapshot(es)
    expect_snapshot_value(es, style = 'json2', tolerance = 1e-5) # round to take into account different rounding errors depending on OS
})


# getRDI ------------------------------------------------------------------

test_that("getRDI", {
    sex_ratio <- 0.5
    rdi <- getRDI(params, n, n_full)
    # test dim
    expect_length(rdi, no_sp)
    expect_named(rdi, as.character(params@species_params$species))
    # test values
    e_repro <- getERepro(params, n = n, n_pp = n_full)
    e_repro_pop <- apply(sweep(e_repro * n, 2, params@dw, "*"), 1, sum)
    rdix <- sex_ratio * (e_repro_pop * params@species_params$erepro) / 
        params@w[params@w_min_idx]
    expect_equal(rdix, rdi, tolerance = 1e-15)
    # expect_known_value(rdi, "values/getRDI")
    # expect_snapshot(rdi)
    expect_snapshot_value(rdi, style = 'json2', tolerance = 1e-5) # round to take into account different rounding errors depending on OS
})

test_that("getRDI is proportional to volume", {
    rdi <- getRDI(params)
    rdi_r <- getRDI(params_r)
    expect_equal(rdi * volume, rdi_r)
})


# getRDD ------------------------------------------------------------------

test_that("getRDD", {
    rdd <- getRDD(params, n, n_full)
    expect_length(rdd, no_sp)
    expect_named(rdd, as.character(params@species_params$species))
    rdi <- getRDI(params, n, n_full)
    rdd2 <- getRDD(params, n, n_full, rdi = rdi)
    expect_identical(rdd, rdd2)
    rdd2 <- do.call(params@rates_funcs$RDD,
                    list(rdi = rdi, species_params = params@species_params))
    expect_identical(rdd, rdd2)
    # expect_known_value(rdd, "values/getRDD")
    # expect_snapshot(rdd)
    expect_snapshot_value(rdd, style = 'json2', tolerance = 1e-5) # round to take into account different rounding errors depending on OS
})

test_that("getRDD is proportional to volume", {
    rdd <- getRDD(params)
    rdd_r <- getRDD(params_r)
    expect_equal(rdd * volume, rdd_r)
})


# getEGrowth --------------------------------------------------------------

test_that("getEGrowth is working", {
    eg1 <- getEGrowth(params, n = n, n_pp = n_full)
    # test dim
    expect_identical(dim(eg1), c(no_sp, no_w))
    expect_identical(dimnames(eg1), dimnames(params@initial_n))
    # expect_known_value(eg1, "values/getEGrowth")
    # expect_snapshot(eg1)
    expect_snapshot_value(eg1, style = 'json2', tolerance = 1e-5) # round to take into account different rounding errors depending on OS
})


# fft ----
test_that("Test that fft based integrator gives similar result as old code", {
    # Make it harder by working with kernels that need a lot of cutoff
    species_params <- NS_species_params_gears
    species_params$pred_kernel_type <- "truncated_lognormal"
    species_params$sigma[3] <- 3
    species_params$beta[4] <- species_params$beta[4] * 100
    species_params$beta[5] <- species_params$beta[5] / 1000
    # and use different egg sizes
    species_params$w_min <- seq(0.001, 1, length.out = no_sp)
    params <- newMultispeciesParams(species_params, inter, 
                                        no_w = 30, min_w_pp = 1e-12,
                                        info_level = 0)
    # create a second params object that does not use fft
    params2 <- setPredKernel(params, pred_kernel = getPredKernel(params))
    # Test encounter rate integral
    efft <- getEncounter(params, params@initial_n, params@initial_n_pp)
    e <- getEncounter(params2, params@initial_n, params@initial_n_pp)
    # Only check values at fish sizes
    fish <- outer(1:no_sp, 1:no_w, function(i, a) a >= params@w_min_idx[i])
    expect_equal(efft[fish], e[fish], tolerance = 3e-14, ignore_attr = TRUE)
    # Test available energy integral
    prfft <- getPredRate(params, params@initial_n, params@initial_n_pp)
    pr <- getPredRate(params2, params@initial_n, params@initial_n_pp)
    expect_equal(prfft, pr, tolerance = 1e-15, ignore_attr = TRUE)
})

# One species only ----
test_that("project function returns objects of correct dimension when community only has one species", {
    params <- newCommunityParams(z0 = 0.2, f0 = 0.7, alpha = 0.2)
    t_max <- 50
    sim <- project(params, t_max = t_max, effort = 0)
    n <- array(sim@n[t_max + 1, , ], dim = dim(sim@n)[2:3])
    dimnames(n) <- dimnames(sim@n)[2:3]
    n_pp <- sim@n_pp[1, ]
    no_w <- length(params@w)
    no_w_full <- length(params@w_full)
    # MizerParams functions
    expect_equal(dim(getEncounter(params, n, n_pp)), c(1, no_w))
    expect_equal(dim(getFeedingLevel(params, n, n_pp)), c(1, no_w))
    expect_equal(dim(getPredRate(params, n, n_pp)), c(1, no_w_full))
    expect_equal(dim(getPredMort(params, n, n_pp)), c(1, no_w))
    expect_length(getResourceMort(params, n, n_pp), no_w_full)
    expect_equal(dim(getFMortGear(params, 0)), c(1, 1, no_w)) # 3D time x species x size
    expect_equal(dim(getFMortGear(params, matrix(c(0, 0), nrow = 2))), 
                     c(2, 1, 1, no_w)) # 4D time x gear x species x size
    expect_equal(dim(getFMort(params, 0)), c(1, no_w)) # 2D species x size
    expect_equal(dim(getFMort(params, matrix(c(0, 0), nrow = 2))), 
                     c(2, 1, no_w)) # 3D time x species x size
    expect_equal(dim(getMort(params, n, n_pp, effort = 0)), c(1, no_w))
    expect_equal(dim(getEReproAndGrowth(params, n, n_pp)), c(1, no_w))
    expect_equal(dim(getERepro(params, n, n_pp)), c(1, no_w))
    expect_equal(dim(getEGrowth(params, n, n_pp)), c(1, no_w))
    expect_length(getRDI(params, n, n_pp), 1)
    expect_length(getRDD(params, n, n_pp), 1)

    # MizerSim functions
    # time x species x size
    expect_equal(dim(getFeedingLevel(sim)), c(t_max + 1, 1, no_w))
    # time x species x size - default drop is TRUE, if called from 
    # plots drop = FALSE
    expect_equal(dim(getPredMort(sim)), c(t_max + 1, no_w))
    # time x species x size
    expect_equal(dim(getPredMort(sim, drop = FALSE)), c(t_max + 1, 1, no_w))
    # time x gear x species x size
    expect_equal(dim(getFMortGear(sim)), c(t_max + 1, 1, 1, no_w))
    # time x species x size - note drop = TRUE
    expect_equal(dim(getFMort(sim)), c(t_max + 1, no_w))
    # time x species x size 
    expect_equal(dim(getFMort(sim, drop = FALSE)), c(t_max + 1, 1, no_w))
})
