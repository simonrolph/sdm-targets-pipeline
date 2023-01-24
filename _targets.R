library(targets)
library(tarchetypes)
library(knitr)

# file 1_ is not targetted due to compications with using terra and targets. See https://github.com/ropensci/targets/discussions/809
knit('R/2_sp_data_processing.Rmd',output = 'R/2_sp_data_processing.md',quiet = T)
knit('R/3_model_prep.Rmd',output = 'R/3_model_prep.md',quiet = T)
knit('R/4_model_run.Rmd',output = 'R/4_model_run.md',quiet = T)

tar_option_set(packages = c("terra","sf","dplyr"))

#define the different species
values <- data.frame(taxon_id = readLines("data/raw/species/sp_list.txt"),
                     data_location = paste0("data/raw/occurence/",readLines("data/raw/species/sp_list.txt"),".rds"))


# map the different species
mapped <- tar_map(values = values,
                  names = taxon_id,
                  tar_target(gbif_data_raw, data_location, format = "file"),
                  tar_target(gbif_data_processed, process_gbif_data(gbif_data_raw)),
                  #model_prep
                  tar_target(sdm_data,generate_samples(env_layers,gbif_data_processed)),
                  
                  # fitting models
                  tar_target(full_model,fit_model(sdm_data)),
                  tar_target(sdm_pred,sp_probability(full_model,env_layers,taxon_id),format ="file"), 
                  
                  # model variability (for determining recording priority)
                  tar_target(bs_models,fit_bs_models(sdm_data)),
                  tar_target(sdm_var,sp_variability(bs_models,env_layers,taxon_id),format ="file")
                  
)


list(
  #env_data_load
  tar_target(env_layers, "data/derived/environmental/env-layers-OSGB.tif",format="file"),
  
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








