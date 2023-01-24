---
title: "4_model_run"
author: "Simon Rolph"
date: "2023-01-24"
output: html_document
---

Fit models


```r
#model on all data
fit_model <- function(sdm_data){
  m1 <- glm(reformulate(names(sdm_data)[3:27], response = 'pres'), data=sdm_data, family="binomial")
  
  m1
}

#fit k models on k-folded data and return as a list of models
fit_bs_models <- function(sdm_data){
  bs_models <- list()
  
  #k fold models
  for(i in 1:max(sdm_data$fold)){
    #90% of data
    sdm_data_fold <- sdm_data[sdm_data$fold != i,]
    bs_models[[i]] <- glm(reformulate(names(sdm_data_fold)[3:27], response = 'pres'), data=sdm_data_fold,family="binomial")
  }
  
  bs_models
}
```

Make predictions in space


```r
#prediction of probability of being in a location
sp_probability <- function(model,env_data,taxon_id){
  env_data <- rast(env_data) #load in the environmental data from file
  p <- predict(env_data, model,type="response") #make predictions
  file_name <- paste0("outputs/by_species/prediction/",taxon_id,".tif") #string for filename
  writeRaster(p,file_name,overwrite =T) # write out the raster tile
  file_name #return the file name 
}
```

Calculate model variability based on the k-fold bootstrapped models.


```r
# model uncertainty
sp_variability <- function(models,env_data,taxon_id){
  env_data <- rast(env_data) #load in the environmental data from file
  file_name <- paste0("outputs/by_species/model_variability/",taxon_id,".tif")  #string for filename
  lapply(models,FUN = function(x){predict(env_data, x,type="response")}) %>%
    rast() %>%
    stdev(filename = file_name, overwrite=T)
  file_name
}
```

Combine the single species outputs into stacked species richness and average model variability


```r
build_sp_richness <- function(rasters){
  file_name <- "outputs/combined/richness/sp_richness.tif"
  rast(rasters) %>% 
    sum(filename = file_name,overwrite=T)
  
  file_name
}

build_rec_priority <- function(rasters){
  file_name <- "outputs/combined/recording_priority/rec_richness.tif"
  rast(rasters) %>% 
    mean(filename = file_name,overwrite=T)
  
  file_name
}
```


### The following is not pipelined


Packages


```r
library(terra)
library(magrittr)

#alternative models to explore
library(mgcv)
library(Hmsc)

library(predicts)
```


```r
#boundary
boundary <- st_read("data/raw/boundaries/SG_CairngormsNationalPark_2010/SG_CairngormsNationalPark_2010.shp")

#plotting
sp_richness <- rast("outputs/combined/richness/sp_richness.tif") %>% project("epsg:4326")
plet(sp_richness %>% round(digits = 0),y = "sum",tiles = "Streets")

sp_priority <- rast("outputs/combined/recording_priority/rec_richness.tif") %>% project("epsg:4326")
plet(sp_priority,tiles = "Streets")

#species maps
rast(list.files("outputs/by_species/prediction",full.names = T)) %>% plot()
rast(list.files("outputs/by_species/model_variability",full.names = T)) %>% plot()
```




```r
model_variability <- readRDS("outputs/model_variability/variability1.RDS")
sample_points <- sample(1:length(values(p)),1000)
plot(values(p)[sample_points],values(model_variability)[sample_points])


#plot raster and add points map
plot(p)
points(sdmdata$x[sdmdata$pres==1],sdmdata$y[sdmdata$pres==1],col = "blue",pch=20)
points(sdmdata$x[sdmdata$pres==0],sdmdata$y[sdmdata$pres==0],col = "black",pch=20)


plot(model_variability)
points(sdmdata$x[sdmdata$pres==1],sdmdata$y[sdmdata$pres==1],col = "blue",pch=20)
points(sdmdata$x[sdmdata$pres==0],sdmdata$y[sdmdata$pres==0],col = "black",pch=20)

#remotes::install_github("rstudio/leaflet")

#plet(model_variability)
```







