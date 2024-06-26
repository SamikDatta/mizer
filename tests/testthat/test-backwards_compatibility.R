# The known values below were calculated with mizer version 1.0.1

# In version 1.0.1 it was still necessary to use data()
data(NS_species_params_gears)
data(inter)

test_that("MizerParams() works as in version 2.5.1", {
  # expect_warning(params <- MizerParams(NS_species_params_gears, inter), "deprecated") 
  # warning no longer thrown - NS_species_params_gears is now 2.5.1 (see `params@mizer_version`)
  params <- newMultispeciesParams(NS_species_params_gears, inter, info_level = 0)
  # expect_known_value(params@search_vol, "values/set_multispecies_model_search_vol")
  # expect_known_value(params@intake_max, "values/set_multispecies_model_intake_max")
  # expect_known_value(params@psi,        "values/set_multispecies_model_psi")
  #expect_known_value(params@std_metab + params@activity, "values/set_multispecies_model_metab")
  # expect_known_value(params@metab,      "values/set_multispecies_model_metab")
  # expect_known_value(params@mu_b,      "values/set_multispecies_model_mu_b")
  # expect_known_value(params@rr_pp, "values/set_multispecies_model_rr_pp")
  # expect_known_value(params@cc_pp, "values/set_multispecies_model_cc_pp")
  # expect_known_value(params@initial_n, "values/set_multispecies_model_initial_n")
  # expect_known_value(params@initial_n_pp, "values/set_multispecies_model_initial_n_pp")
  
  expect_snapshot(params@search_vol)
  expect_snapshot(params@intake_max)
  expect_snapshot(params@psi)
  expect_snapshot(params@metab)
  expect_snapshot(params@mu_b)
  expect_snapshot(params@rr_pp)
  expect_snapshot(params@cc_pp)
  expect_snapshot(params@initial_n)
  expect_snapshot(params@initial_n_pp)
  
  # The predation rate is different because in the old version the predation
  # kernel was cut off at beta + 3 sigma
  # new <- getPredRate(params)
  # df <- melt(new) %>% mutate(type = "new")
  # old <- readRDS("values/set_multispecies_model_pred_rate")
  # dimnames(old) <- dimnames(new)
  # dfo <- melt(old) %>% mutate(type = "old")
  # dfs <- rbind(df, dfo)
  # dfs$sp <- as.factor(dfs$sp)
  # ggplot(dfs) +
  #     geom_line((aes(x = w_prey, y = value, colour = sp, linetype = type))) +
  #     scale_x_log10() +
  #     scale_y_log10()
  # max(abs(old - new))
  # expect_warning(gpp <- getPhiPrey(params, n = initialN(params), 
  #                                  n_pp = initialNResource(params)),
  #                "deprecated")
  # expect_known_value(gpp, "values/set_multispecies_model_phi_prey",
  #                    check.attributes = FALSE,
  #                    tolerance = 0.0005)
  expect_snapshot(getPhiPrey(params, n = initialN(params), n_pp = initialNResource(params)))
  # The discrepancy is small, see the following graph:
  # new <- getPhiPrey(params, n = initialN(params), n_pp = initialNResource(params))
  # df <- melt(new) %>% mutate(type = "new")
  # old <- readRDS("values/set_multispecies_model_phi_prey")
  # dimnames(old) <- dimnames(new)
  # dfo <- melt(old) %>% mutate(type = "old")
  # dfs <- rbind(df, dfo)
  # dfs$sp <- as.factor(dfs$sp)
  # ggplot(dfs) +
  #     geom_line((aes(x = w, y = value, colour = sp, linetype = type))) +
  #     scale_x_log10() +
  #     scale_y_log10()
  # max(abs(old - new))
})

test_that("set_trait_model() works as in version 1", {
  # expect_warning(params <- set_trait_model(), "deprecated")
  # warning no longer thrown - default params are now 2.5.1 (see `params@mizer_version`)
  params <- newTraitParams()
  # expect_known_value(params@search_vol, "values/set_trait_model_search_vol")
  # expect_known_value(params@intake_max, "values/set_trait_model_intake_max")
  # expect_known_value(params@psi,        "values/set_trait_model_psi")
  #expect_known_value(params@std_metab + params@activity, "values/set_trait_model_metab")
  # expect_known_value(params@metab,      "values/set_trait_model_metab")
  # expect_known_value(params@mu_b,      "values/set_trait_model_mu_b")
  # expect_known_value(params@rr_pp, "values/set_trait_model_rr_pp")
  # expect_known_value(params@cc_pp, "values/set_trait_model_cc_pp")
  # expect_known_value(params@initial_n, "values/set_trait_model_initial_n")
  # expect_known_value(params@initial_n_pp, "values/set_trait_model_initial_n_pp")
  
  expect_snapshot(params@search_vol)
  expect_snapshot(params@intake_max)
  expect_snapshot(params@psi)
  expect_snapshot(params@metab)
  expect_snapshot(params@mu_b)
  expect_snapshot(params@rr_pp)
  expect_snapshot(params@cc_pp)
  expect_snapshot(params@initial_n)
  expect_snapshot(params@initial_n_pp)
  
  # The predation rate is different because in the old version the predation
  # kernel was cut off at beta + 3 sigma
  # new <- getPredRate(params)
  # df <- melt(new) %>% mutate(type = "new")
  # old <- readRDS("values/set_trait_model_pred_rate")
  # dimnames(old) <- dimnames(new)
  # dfo <- melt(old) %>% mutate(type = "old")
  # dfs <- rbind(df, dfo)
  # dfs$sp <- as.factor(dfs$sp)
  # ggplot(dfs) +
  #     geom_line((aes(x = w_prey, y = value, colour = sp, linetype = type))) +
  #     scale_x_log10() +
  #     scale_y_log10()
  # expect_known_value(getPhiPrey(params, n = initialN(params), n_pp = initialNResource(params)), 
  #                    "values/set_trait_phi_prey",
  #                    check.attributes = FALSE,
  #                    tolerance = 1e-5) # set_trait_phi_prey doesn't have dimnames, needs updating
  expect_snapshot(getPhiPrey(params, n = initialN(params), n_pp = initialNResource(params)))
  
  # The discrepancy is too small to see in the following graph:
  # new <- getPhiPrey(params, n = initialN(params), n_pp = initialNResource(params))
  # df <- melt(new) %>% mutate(type = "new")
  # old <- readRDS("values/set_trait_phi_prey")
  # dimnames(old) <- dimnames(new)
  # dfo <- melt(old) %>% mutate(type = "old")
  # dfs <- rbind(df, dfo)
  # dfs$sp <- as.factor(dfs$sp)
  # ggplot(dfs) +
  #     geom_line((aes(x = w, y = value, colour = sp, linetype = type))) +
  #     scale_x_log10() +
  #     scale_y_log10()
  # max(abs(old - new))
})

test_that("set_community_model() works as in version 1", {
  # expect_warning(params <- set_community_model(), "deprecated")
  # warning no longer thrown - default params are now 2.5.1 (see `params@mizer_version`)
  params <- newCommunityParams()
  # expect_known_value(params@search_vol, "values/set_community_model_search_vol")
  # expect_known_value(params@intake_max, "values/set_community_model_intake_max")
  # expect_known_value(params@psi,        "values/set_community_model_psi")
  #expect_known_value(params@std_metab + params@activity, "values/set_community_model_metab")
  # expect_known_value(params@metab,      "values/set_community_model_metab")
  # expect_known_value(params@mu_b,      "values/set_community_model_mu_b")
  # expect_known_value(params@rr_pp, "values/set_community_model_rr_pp")
  # expect_known_value(params@cc_pp, "values/set_community_model_cc_pp")
  # expect_known_value(params@initial_n, "values/set_community_model_initial_n")
  # expect_known_value(params@initial_n_pp, "values/set_community_model_initial_n_pp")
  
  expect_snapshot(params@search_vol)
  expect_snapshot(params@intake_max)
  expect_snapshot(params@psi)
  expect_snapshot(params@metab)
  expect_snapshot(params@mu_b)
  expect_snapshot(params@rr_pp)
  expect_snapshot(params@cc_pp)
  expect_snapshot(params@initial_n)
  expect_snapshot(params@initial_n_pp)
  
  # The predation rate is different because in the old version the predation
  # kernel was cut off at beta + 3 sigma, see following graph
  # new <- getPredRate(params)
  # df <- melt(new) %>% mutate(type = "new")
  # old <- readRDS("values/set_community_model_pred_rate")
  # dimnames(old) <- dimnames(new)
  # dfo <- melt(old) %>% mutate(type = "old")
  # dfs <- rbind(df, dfo)
  # dfs$sp <- as.factor(dfs$sp)
  # ggplot(dfs) +
  #     geom_line((aes(x = w_prey, y = value, colour = sp, linetype = type))) +
  #     scale_x_log10() +
  #     scale_y_log10()
  # max(abs(new - old))
  # expect_known_value(getPhiPrey(params, n = initialN(params), n_pp = initialNResource(params)), 
  #                    "values/set_community_phi_prey",
  #                    check.attributes = FALSE,
  #                    tolerance = 42)
  expect_snapshot(getPhiPrey(params, n = initialN(params), n_pp = initialNResource(params)))
  # The discrepancy is small, see the following graph:
  # new <- getPhiPrey(params, n = initialN(params), n_pp = initialNResource(params))
  # df <- melt(new) %>% mutate(type = "new")
  # old <- readRDS("values/set_community_phi_prey")
  # dimnames(old) <- dimnames(new)
  # dfo <- melt(old) %>% mutate(type = "old")
  # dfs <- rbind(df, dfo)
  # dfs$sp <- as.factor(dfs$sp)
  # ggplot(dfs) +
  #     geom_line((aes(x = w, y = value, colour = sp, linetype = type))) +
  #     scale_x_log10() +
  #     scale_y_log10()
  # max(abs(new - old))
})
