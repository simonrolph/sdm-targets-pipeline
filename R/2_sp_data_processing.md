---
title: "sp_data_processing"
author: "Simon Rolph"
date: "2023-01-24"
output: html_document
---

### Load packages


```r
library(rgbif)
library(dplyr)
#library(spThin)
```

### Species list

The species list is stored as a text file of GBIF taxon IDs in `sp_list.txt`. You can add more species by looking up their taxon key on gbif and adding it to the list. This list is used to define the values in `tar_map()`.


```r
sp_list_taxon_id <- readLines("data/raw/species/sp_list.txt")
aoi_wkt <- readLines("data/derived/environmental/AOI_WKT.txt") # the area of interest
```


### Download data

This code chunk downloads the data from GBIF using R package `rgbif` 


```r
#make data request
sp_data_request <- occ_download(pred_in("taxonKey",sp_list_taxon_id),
                                pred("gadm","GBR.3_1"),
                                pred_lt("coordinateUncertaintyInMeters",101),
                                pred_within(aoi_wkt))

#wait until the download is ready
occ_download_wait(sp_data_request[1])

# get data
d <- occ_download_get(sp_data_request[1],path = "data/raw/occurence/") %>% 
    occ_download_import()

#save the full data
saveRDS(d,"data/raw/occurence/sp_data_raw.rds")

#read it back in
d <- readRDS("data/raw/occurence/sp_data_raw.rds")

#split the data into taxa
for (sp in sp_list_taxon_id){
  d %>% 
    dplyr::filter(taxonKey == sp) %>%
    saveRDS(paste0("data/raw/occurence/",sp,".rds"))
}

# create a species info table
d %>% 
  group_by(taxonKey,species) %>% 
  filter(vernacularName != "") %>%
  summarise(vernacularName = first(vernacularName)) %>%
  saveRDS("data/raw/species/species_names.rds")


# list of contributors
d %>% 
  group_by(species,rightsHolder,license) %>% 
  summarise(n_records = n()) %>%
  saveRDS("data/derived/occurence/rightsholders.rds")

#text version of list of contributors
d %>% 
  group_by(species,rightsHolder,license) %>% 
  summarise(n_records = n()) %>%
  mutate(human_readable = paste0(n_records," record(s) of ",species," recorded by ",rightsHolder," with license: ",license)) %>%
  pull(human_readable) %>%
  writeLines("data/derived/occurence/species_data_rights_holders.txt")
```

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
  d <- st_as_sf(d,coords =c("decimalLongitude","decimalLatitude"),crs = 4326) %>% 
    st_transform(27700) 
  d
}

#generate a list of species
species_list <- function(d){
  unique(d$speciesKey)
}

#saveRDS(d,"data/derived/occurence/5334220.rds")
```



