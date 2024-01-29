### Pre-flight checks
#do we have a species list?
sp_list <- readLines("inputs/species_list/sp_list.txt")
print(paste0(length(sp_list)," species"))

#do we have data for all the species
gsub(".rds","",list.files("inputs/species_data/")) %in% sp_list

#do we have an environmental raster?
library(terra)
library(sf)

plot <- F
if(plot){
  env_rast <- rast("inputs/environmental/env-layers.tif")
  print(paste0(length(names(env_rast))," layers:"))
  names(env_rast)
  
  # overlay raster and shapefile to check overlap
  AOI_fit <- st_read("inputs/regions/AOI_fit/AOI_fit.shp") %>% vect()
  AOI_pred <- st_read("inputs/regions/AOI_predict/AOI_predict.shp") %>% vect()
  
  plot(env_rast[[1]])
  lines(AOI_fit,col = "red")
  lines(AOI_pred,col = "blue")
}


#update GBIF data
source("R/1_gbif_refresh.R")


## Run pipeline
library(targets)
tar_visnetwork(T,exclude = starts_with("effort"))
tar_visnetwork(T,exclude = !starts_with("effort"))
tar_make()
tar_prune()
