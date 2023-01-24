---
title: "Preparation for running models"
author: "Simon Rolph"
date: "2023-01-24"
output: html_document
---

Generate background samples and extract environmental data for presence occurrence data


```r
generate_samples <- function(env_data,occ_data,k_folds = 5){
  env_data <- rast(env_data)
  
  n_background <- 1000
  set.seed(42)
  data_background <- spatSample(env_data,n_background,xy=TRUE,method =  "random")
  data_background$pres <- 0
  data_background$ID <- NA

  data_background$fold <- rep_len(1:k_folds,n_background)
  data_background

  data_presence <- terra::extract(env_data,occ_data,xy=TRUE)
  data_presence$pres <- 1
  data_presence$fold <- rep_len(1:k_folds,nrow(data_presence))

  data_full <- rbind(data_background,data_presence)
  data_full
}

#saveRDS(data_full,"data/derived/occurence/5334220_presence_absence.RDS")
```




