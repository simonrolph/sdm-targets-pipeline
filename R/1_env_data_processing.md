---
title: "Environmental data processing"
author: "Simon Rolph"
date: "2023-01-20"
output: html_document
---

packages


```r
library(sf)
```

```
## Linking to GEOS 3.9.3, GDAL 3.5.2, PROJ 8.2.1; sf_use_s2() is TRUE
```

```r
library(terra)
```

```
## terra 1.6.47
```

```
## 
## Attaching package: 'terra'
```

```
## The following object is masked from 'package:knitr':
## 
##     spin
```

Define extent


```r
boundary <- st_read("data/raw/boundaries/SG_CairngormsNationalPark_2010/SG_CairngormsNationalPark_2010.shp")
```

```
## Error: Cannot open "data/raw/boundaries/SG_CairngormsNationalPark_2010/SG_CairngormsNationalPark_2010.shp"; The file doesn't seem to exist.
```

```r
bbox <- st_bbox(boundary)
```

```
## Error in st_bbox(boundary): object 'boundary' not found
```

```r
boundary %>% st_transform(4326) %>% st_bbox()
```

```
## Error in st_transform(., 4326): object 'boundary' not found
```

```r
print("blob")
```

```
## [1] "blob"
```

Load layers which have been downloaded from google earth engine and reproject to OSGB


```r
compile_env_layers <- function(bio_image,predictors_image){
  # env_layers <- rast(c("data/raw/environmental/bio-image.tif",
  #                    "data/raw/environmental/predictors-image.tif"))
  env_layers <- rast(c(bio_image,
                     predictors_image))

  env_layers <- project(env_layers,"EPSG:27700")
  
  env_layers
  
}

#writeRaster(env_layers,filename = "data/derived/environmental/env-layers-OSGB.tif")
```

