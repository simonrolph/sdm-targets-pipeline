library(rgbif)
library(dplyr)

# WHAT SPECIES AND WHERE?

#The species list is stored as a text file of GBIF taxon IDs in `sp_list.txt`. You can add more species by looking up their taxon key on gbif and adding it to the list. This list is used to define the values in `tar_map()`.
sp_list_taxon_key <- readLines("inputs/species_list/sp_list.txt")
print(paste0(length(sp_list_taxon_key)," species in species list"))

#where = scotland as defined as
AOI_fit <- readLines("inputs/regions/AOI_fit/AOI_WKT.txt")

# WHAT DO WE HAVE DATA ON ALREADY?

#what species do we have data for?
sp_list_downloaded <- list.files("inputs/species_data",pattern = "*.rds") %>% gsub(".rds","",.)

#which species are missing?
sp_list_missing <- sp_list_taxon_key[!(sp_list_taxon_key %in% sp_list_downloaded)]
print(paste0(length(sp_list_missing)," species have no GBIF data in local data store"))

#download data on missing species
if (length(sp_list_missing)>0){
  #This code chunk downloads the data from GBIF using R package `rgbif` 
  
  #make data request
  sp_data_request <- occ_download(pred_in("taxonKey",sp_list_missing),
                                  pred_within(AOI_fit),
                                  pred_lt("coordinateUncertaintyInMeters",101))
  
  #wait until the download is ready
  occ_download_wait(sp_data_request[1])
  
  # get data
  d <- occ_download_get(sp_data_request[1],path = "data/raw/occurence/") %>% 
    occ_download_import()
  
  #split the data into taxa
  for (sp in sp_list_missing){
    d %>% 
      dplyr::filter(speciesKey == sp) %>%
      saveRDS(paste0("inputs/species_data/",sp,".rds"))
  }
}


# DOES THE DATA WE HAVE NEED UPDATING?
print("Checking for updates in GBIF remote data store...")

# Look for updates to GBIF data
gbif_n <- occ_search(geometry = AOI_fit,
                   taxonKey = sp_list_taxon_key,
                   limit=0,
                   coordinateUncertaintyInMeters='0,100',
                   occurrenceStatus = NULL,
                   hasCoordinate=TRUE,
                   hasGeospatialIssue=FALSE
                   )

#reformat as a table of taxonkey and n_records
gbif_n <- gbif_n %>% lapply(FUN = function(x){x$meta$count}) %>% 
  unlist() %>% 
  as.data.frame() %>% 
  cbind(.,"taxonKey"=rownames(.)) %>%
  rename("n_gbif" = ".") %>%
  data.frame(row.names=NULL)

#get the number of records from GBIF
local_n <- list.files("inputs/species_data",pattern = "*.rds",full.names = T) %>% 
  lapply(FUN = function(x){readRDS(x) %>% nrow}) %>% 
  `names<-`(list.files("inputs/species_data",pattern = "*.rds") %>% gsub(".rds","",.)) %>% 
  unlist() %>% 
  as.data.frame() %>% 
  cbind(.,"taxonKey"=rownames(.)) %>%
  rename("n_local" = ".") %>%
  data.frame(row.names=NULL)

sp_list_to_update <- gbif_n %>% left_join(local_n,by = "taxonKey") %>% filter(n_gbif != n_local) %>% pull(taxonKey)


print(paste0(length(sp_list_to_update)," species have out of date GBIF data in local data store"))

#download data on missing species
if (length(sp_list_to_update)>0){
  #This code chunk downloads the data from GBIF using R package `rgbif` 
  print("Downloading GBIF data")
  
  #make data request
  sp_data_request <- occ_download(pred_in("taxonKey",sp_list_to_update),
                                  pred_lt("coordinateUncertaintyInMeters",101),
                                  pred_within(AOI_fit))
  
  #wait until the download is ready
  occ_download_wait(sp_data_request[1])
  
  # get data
  d <- occ_download_get(sp_data_request[1],path = "data/raw/occurence/") %>% 
    occ_download_import()
  
  #split the data into taxa
  for (sp in sp_list_to_update){
    d %>% 
      dplyr::filter(speciesKey == sp) %>%
      saveRDS(paste0("inputs/species_data/",sp,".rds"))
  }
}

print("GBIF data update complete!")
