library(targets)
library(tarchetypes)
library(knitr)



# file 1_ is not targetted due to compications with using terra and targets. See https://github.com/ropensci/targets/discussions/809
knit('R/2_sp_data_processing.Rmd',output = 'R/2_sp_data_processing.md',quiet = T)
knit('R/3_model_prep.Rmd',output = 'R/3_model_prep.md',quiet = T)
knit('R/4_model_run.Rmd',output = 'R/4_model_run.md',quiet = T)

tar_option_set(packages = c("terra","sf","dplyr","rgbif"))

sp_list_location <- "inputs/species_list/sp_list.txt"

#define the different species
values <- data.frame(taxon_id = readLines(sp_list_location),
                     data_location = paste0("inputs/species_data/",readLines(sp_list_location),".rds"))


# map the different species
mapped <- tar_map(values = values,
                  names = taxon_id,
                  
                  #load in the raw gbif data (with files for each species)
                  tar_target(gbif_data_raw, data_location, format = "file"),
                  
                  #process the raw gbif data
                  tar_target(species_metadata,get_species_metadata(gbif_data_raw)),
                  tar_target(gbif_data_processed, process_gbif_data(gbif_data_raw)),
                  
                  #model_prep
                  tar_target(sdm_data,generate_samples(env_layers,gbif_data_processed)),
                  
                  # fitting models
                  tar_target(full_model,fit_model(sdm_data)),
                  tar_target(sdm_pred,sp_probability(full_model,
                                                     env_layers,
                                                     taxon_id,
                                                     species_metadata),format ="file"), 
                  
                  # model variability (for determining recording priority)
                  tar_target(bs_models,fit_bs_models(sdm_data)),
                  tar_target(sdm_var,sp_variability(bs_models,
                                                    env_layers,
                                                    taxon_id,
                                                    species_metadata),format ="file"),
                  
                  #produce report
                  tar_render(sdm_report,
                             params = list(species_metadata = species_metadata,
                                           sdm_data = sdm_data,
                                           full_model = full_model,
                                           sdm_pred = sdm_pred,
                                           bs_models = bs_models,
                                           sdm_var = sdm_var),
                             "R/5_model_eval_report.Rmd",
                             output_file = paste0("../outputs/by_species/reports/",taxon_id, ".html"))
                  
                  
)


list(
  #env_data_load
  tar_target(env_layers, "inputs/environmental/env-layers.tif",format="file"),
  
  mapped,
  
  tar_combine(name = sp_richness, 
              mapped$sdm_pred,
              command = build_sp_richness(c(!!!.x)),
              use_names = F,
              format="file"),
  tar_combine(name = recording_priority,
              mapped$sdm_var,
              command= build_rec_priority(c(!!!.x)),
              use_names = F,
              format="file")
)








