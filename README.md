# An example {targets} pipeline for species distribution modelling

## Overview

This is a pipeline for modelling species distributions using open data: occurrence data from GBIF and environmental data sourced from Google Earth Engine (GEE) to produce maps of predicted species distributions, and maps of model variability. The maps of model variability can then be used to decide where to collect extra information to improve the model (as trialled in the DECIDE project).

The aim of this repository is to:

 * A simple demonstration of {targets} for SDMs
 * Provide a extensible template for anyone wanting to build a SDM pipeline with {targets}

The {targets package} is a Make-like pipeline tool for Statistics and data science in R. This code outlines how targets can be used to implement and track a SDM pipeline in R. The manual can be found here: https://books.ropensci.org/targets/

In this example, raster processing is implemented using the {terra} package and other geometry processing s implemented using {sf}.

The statistical models in this example are intentionally very simple as this aims to showcase a SDM pipeline rather than get bogged down in the complicated modelling. The models are fitted as GLMs using a `glm(family="binomial")` call. This uses a single species modelling approach, rather than joint species distribution modelling, and combines model outputs to produce a stacked-SDM estimate of species richness.

The example region, species and environmental data relate to the Cairngorms National Park as this work is developed as part of a cultural ecosystem services use-case within the EU BioDT project.

## Starting data requirements

The pipeline requires three pieces of information:

 * A species list as defined by GBIF taxon keys in a `.txt` file. `inputs/species_list/sp_list.txt`
 * Two shapefiles `.shp` (+ associated files), one for the area of interest (AOI) you want to predict to, and one for the wider area you want to fit the model to (these can be the same shapefile). `inputs/regions/`
 * A environmental raster `.tif` covering the area of interest. `inputs/environmental/env_layers.tif`
 
The species list and shapefiles are then used to download occurence data from GBIF for modelling.

### Species

The target species to model are defined in a `.txt` file `data/raw/species/sp_list.txt` which just lists (one line per key) the GBIF taxonKeys which is simply a number eg https://www.gbif.org/occurrence/search?taxon_key=7412043

### Environmental data

The inital processing of environmental data is currently not pipelined with targets and is run as via `1_env_data_processing.Rmd`. It uses `.tif` files that have been downloaded from GEE using a GEE script which you can find a copy of in `GEE/export_end_data.js`. You can find an online copy of it here: https://code.earthengine.google.com/ea6fd222f8137ed0e61466742892db74 

Species data is then downloaded from GBIF using the code chunks in `R/2_sp_data_processing.Rmd`

## Pipeline

### Pre-pipeline stuff

`R/0_data_preparation.Rmd` and `R/1_pipeline_set_up.Rmd` are scripts that I run before the pipeline to create the starting data requirements I set out above. This isn't pipelined because you might do this stage in a completely different manner depending on your data sources. The data preparation script will need to be tweaked to your use-case. It takes the raw shapefile that you might have downloaded from the internet, reprojects it and exports it the to `inputs` directory ready for the pipeline start. It also does a bit of processing for the environmental raster - removing water etc.

You need to run the pipeline_set_up script as it downloads data from GBIF for the species you have specified in `data/raw/species/sp_list.txt`.

### It's pipeline time

The pipeline is defined in `_targets.R`. It uses static branching (https://books.ropensci.org/targets/static.html) to create branches for each species based on the taxon keys defined in `sp_list.txt`.

The pipeline is started with `targets::tar_make()`

The pipeline can be visualised with `tar_visnetwork(targets_only = T)`:

![image](https://user-images.githubusercontent.com/17750766/215775142-78e12954-b3ef-4352-a2c4-c79610ea888d.png)

It does't always look as neat as that, I had to move the blobs about a bit. The blobs are green because this is after the pipeline has been run and the objects are up to date.

Functions are defined in the R markdown files in `/R` folder which contain functions which are then built into a pipeline in `_targets.R`. This readme provides overall sumamries of what each function does. Look in the individual markdown files for more information.

### Species data processing (`sp_data_processing.Rmd`)

 * `process_gbif_data()` - very basic data cleaning to select only presence records and remove spatially inaccurate records. Convert to a sf object.
 * `rights_holders_text()` - produce a human-readable list of all the people who contributed records
 * `get_species_metadata()` - use the `rgbif` package to make a call to the GBIF api to get species data from the GBIF backbone.

### Generate samples (`3_model_prep.Rmd`)

 * `generate_samples()` - Generate some background samples for each species and then extract the environmental co-variates for both the occurrence data and the background samples.

### Fitting models and making predictions with models (`4_model_run.Rmd`)

Fitting the models to the samples then using the environmental layers, we use the models to predict probability of occurrence across the entire spatial extent. We do this once with the full model then k times with the models fitted to the k-folded data (to get a measure of model variability).

 * `fit_model()` - fit one model to all the data.
 * `fit_bs_models()` - fit k models to k-folded data. Using k=5 in the current set-up. This is to be able to calculate model variability.
 * `sp_probability()` - Predict modelled species probability of occurrence across entire environmental raster
 * `sp_variability()` - Calculate model variability in species probability of occurrence across entire environmental raster

### Combining species outputs (also `4_model_run.Rmd`)

Each of the by-species outputs (model prediction and model variability) are combined into single layers. Species richness is calculated by summing the predicted probability of occurence of each model and 'recording priority' is the mean of the model variabilities.

 * `build_sp_richness()` - species richness by summing modelled probability of occurence
 * `build_rec_priority()` - calculated as mean model variability
 
 ## Example run
 
The repository comes with some example data so you can run the pipeline straight away.
 
First, install all the required packages using `renv` 

```
install.packages("renv")
renv::restore()
```

Rename the `data_example` folder to simply `data`. Rename the `data` folder to something else so that you won't overwrite the files in `data`.

Run the pipeline

```
library(targets)
tar_visnetwork(T)
tar_make()
```

When it's finished then you can explore the `\outputs\by_species\reports` folder look at the species reports with content like such:

![image](https://user-images.githubusercontent.com/17750766/215774201-60c0c2c1-766f-47a5-96ff-3272a356ff63.png)




