library(targets)

library(knitr)
knit('R/1_env_data_processing.Rmd',output = "R/1_env_data_processing.md",quiet = T)
knit('R/2_sp_data_processing.Rmd',output = 'R/2_sp_data_processing.md',quiet = T)
knit('R/3_model_prep.Rmd',output = 'R/3_model_prep.md',quiet = T)
#knit('4_model_run.Rmd')

tar_option_set(packages = c("terra","sf","dplyr"))

list(
  #env_data_processing
  tar_target(boundary,"data/raw/boundaries/SG_CairngormsNationalPark_2010/SG_CairngormsNationalPark_2010.shp",format = "file"),
  tar_target(bio_image, "data/raw/environmental/bio-image.tif", format = "file"),
  tar_target(predictors_image, "data/raw/environmental/predictors-image.tif", format = "file"),
  tar_target(env_layers, compile_env_layers(bio_image,predictors_image)),
  
  #sp_data_processing
  tar_target(gbif_data_raw, "data/raw/occurence/5334220.rds", format = "file"),
  tar_target(gbif_data_processed, process_gbif_data(gbif_data_raw)),
  
  #model_prep
  tar_target(samples,generate_samples(species=NULL,
                                      n_background = 1000,
                                      env_data = env_layers,
                                      occ_data = gbif_data_processed))
)

