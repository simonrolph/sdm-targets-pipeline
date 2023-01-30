---
title: "Species data processing"
author: "Simon Rolph"
date: "2023-01-30"
output: html_document
---


### Pipeline functions start

From this point forward, R scripts are written as functions and used the the {targets} pipeline.

This script cleans and projects the gbif data to OSGB


```r
#d <- readRDS("data/raw/occurence/5334220.rds")

# process the data
process_gbif_data <- function(d){
  d <- readRDS(d)
  d<- d %>% dplyr::filter(occurrenceStatus == "PRESENT",
         coordinateUncertaintyInMeters <= 100)
  d <- st_as_sf(d,coords =c("decimalLongitude","decimalLatitude"),crs = 4326) #%>% 
    #st_transform(27700) (optional)
  d
}

#generate a list of species
species_list <- function(d){
  unique(d$speciesKey)
}

#saveRDS(d,"data/derived/occurence/5334220.rds")
```

Species data rights holders text output to fulfil CC-BY usage


```r
rights_holders_text <- function(sp_data){
  readRDS(sp_data) %>% 
    group_by(species,rightsHolder,license) %>% 
    summarise(n_records = n()) %>%
    mutate(human_readable = paste0(n_records," record(s) of ",species," recorded by ",rightsHolder," with license: ",license)) %>%
    pull(human_readable) %>%
    writeLines("data/derived/occurence/species_data_rights_holders.txt")
  "data/derived/occurence/species_data_rights_holders.txt"
}
```

Get species meta data


```r
get_species_metadata <- function(d){
  d <- readRDS(d)
  taxonKey <- d$taxonKey[1]
  res <- name_usage(taxonKey)
  res$data
}
```

A look-up table with species names 


```r
species_names_table <- function(sp_data){
  readRDS(sp_data) %>% 
    group_by(taxonKey,species) %>% 
    filter(vernacularName != "") %>%
    summarise(vernacularName = first(vernacularName)) %>%
    saveRDS("data/derived/species/species_names.rds")
  "data/derived/species/species_names.rds"
}
```
