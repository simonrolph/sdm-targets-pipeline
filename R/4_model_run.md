---
title: "Running models and making predictions"
author: "Simon Rolph"
date: "2023-01-31"
output: html_document
---

Fit models


```r
#model on all data
fit_model <- function(sdm_data){
  
  n_pres <- sum(sdm_data$pres == 1)
  n_background <- sum(sdm_data$pres == 0)
  pres_weight <- 1
  back_weight <- n_pres/n_background
  sdm_data$weighting <- back_weight
  sdm_data$weighting[sdm_data$pres == 1] <- pres_weight
  
  m1 <- glm(reformulate(names(sdm_data)[3:(ncol(sdm_data)-3)], response = 'pres'), data=sdm_data, family="binomial",weights = weighting)
  
  m1
}

#fit k models on k-folded data and return as a list of models
fit_bs_models <- function(sdm_data){
  bs_models <- list()
  
  #k fold models
  for(i in 1:max(sdm_data$fold)){
    #90% of data
    sdm_data_fold <- sdm_data[sdm_data$fold != i,]
    
    n_pres <- sum(sdm_data_fold$pres == 1)
    n_background <- sum(sdm_data_fold$pres == 0)
    pres_weight <- 1
    back_weight <- n_pres/n_background
    sdm_data_fold$weighting <- back_weight
    sdm_data_fold$weighting[sdm_data_fold$pres == 1] <- pres_weight
    
    bs_models[[i]] <- glm(reformulate(names(sdm_data_fold)[3:(ncol(sdm_data)-3)], response = 'pres'), data=sdm_data_fold,family="binomial",weights = weighting)
  }
  
  bs_models
}
```

Make predictions in space


```r
#prediction of probability of being in a location
sp_probability <- function(model,env_data,taxon_id,sp_meta){
  env_data <- rast(env_data) #load in the environmental data from file
  p <- predict(env_data, model,type="response") #make predictions
  file_name <- paste0("outputs/by_species/prediction/",taxon_id,".tif") #string for filename
  writeRaster(p,file_name,overwrite =T,names = sp_meta$species %>% gsub(" ","_",x=.)) # write out the raster tile
  file_name #return the file name 
}
```

Calculate model variability based on the k-fold bootstrapped models.


```r
# model uncertainty
sp_variability <- function(models,env_data,taxon_id,sp_meta){
  env_data <- rast(env_data) #load in the environmental data from file
  file_name <- paste0("outputs/by_species/model_variability/",taxon_id,".tif")  #string for filename
  lapply(models,FUN = function(x){predict(env_data, x,type="response")}) %>%
    rast() %>%
    stdev() %>%
    writeRaster(filename = file_name, overwrite=T,names = sp_meta$species %>% gsub(" ","_",x=.))
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
sp_richness <- rast("outputs/combined/richness/sp_richness.tif") #%>% project("epsg:4326")
plet(sp_richness %>% round(digits = 0),y = "sum",tiles = "Streets")

sp_priority <- rast("outputs/combined/recording_priority/rec_richness.tif") #%>% project("epsg:4326")
plet(sp_priority,tiles = "Streets")



#species maps
rast(list.files("outputs/by_species/prediction",full.names = T)[1]) %>% plet(tiles = "Streets")
rast(list.files("outputs/by_species/model_variability",full.names = T)[3]) %>% plet(tiles = "Streets")

rast(list.files("outputs/by_species/prediction",full.names = T)) %>% plot()
rast(list.files("outputs/by_species/model_variability",full.names = T)) %>% plot()
```

Look at models


```r
m1 <- readRDS("_targets/objects/full_model_5285637")
```

```
## Warning in gzfile(file, "rb"): cannot open compressed file
## '_targets/objects/full_model_5285637', probable reason 'No such file or
## directory'
```

```
## Error in gzfile(file, "rb"): cannot open the connection
```

```r
m1
```

```
## Error in eval(expr, envir, enclos): object 'm1' not found
```

```r
summary(m1)
```

```
## Error in summary(m1): object 'm1' not found
```

```r
plot(m1)
```

```
## Error in plot(m1): object 'm1' not found
```

```r
m1$data
```

```
## Error in eval(expr, envir, enclos): object 'm1' not found
```

```r
plot(m1$data$water,m1$data$pres)
```

```
## Error in plot(m1$data$water, m1$data$pres): object 'm1' not found
```








