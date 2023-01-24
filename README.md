# An example {targets} pipeline for species distribution modelling

(This is a work in progress)

## Overview

This is a pipeline for modelling species distributions using open data: occurrence data from GBIF and environmental data sourced from Google Earth Engine (GEE) to produce maps of predicted species distributions, and maps of model variability. The maps of model variability can then be used to decide where to collect extra information to improve the model (as trialled in the DECIDE project).

The {targets package} is a Make-like pipeline tool for Statistics and data science in R. This code outlines how targets can be used to implement and track a SDM pipeline in R. The manual can be found here: https://books.ropensci.org/targets/

In this example, raster processing is implemented using the {terra} package and other geometry processing s implemented using {sf}.

The statistical models in this example are intentionally very simple as this aims to showcase a SDM pipeline rather than get bogged down in the complicated modelling. The models are fitted as GLMs using a `glm(family="binomial")` call. This uses a single species modelling approach, rather than joint species distribution modelling, and combines model outputs to produce a stacked-SDM estimate of species richness.

The example region, species and environmental data relate to the Cairngorms National Park as this work is developed as part of a cultural ecosystem services use-case within the EU BioDT project.

## Starting requirements data

### Environmental data

The inital processing of environmental data is currently not pipelined with targets and is run as via `1_env_data_processing.Rmd`. It uses `.tif` files that have been downloaded from GEE using a GEE script which you can find a copy of in `GEE/export_end_data.js`. You can find an online copy of it here: https://code.earthengine.google.com/ea6fd222f8137ed0e61466742892db74 

### Species

The target species to model are defined in a `.txt` file `data/raw/species/sp_list.txt` which just lists (one line per key) the GBIF taxonKeys which is simply a number eg https://www.gbif.org/occurrence/search?taxon_key=7412043

Species data is then downloaded from GBIF using the code chunks in `R/2_sp_data_processing.Rmd`

## Pipeline

The pipeline is defined in `_targets.R`. It uses static branching (https://books.ropensci.org/targets/static.html) to create branches for each species based on the taxon keys defined in `sp_list.txt`.

The pipeline is started with `targets::tar_make()`

The pipeline can be visualised with `tar_visnetwork(targets_only = T)`:

![image](https://user-images.githubusercontent.com/17750766/214363002-0c057b06-3753-406a-9521-2667b5e84b23.png)

It does't always look as neat as that, I had to move the blobs about a bit.

### Process gbif data

Remove occurrence records with too much spatial uncertainty and reproject to OSBG (epsg:27700)

### Generate samples

generate some background samples for each species and then extract the environmental co-variates for both the occurrence data and the background samples.

### Fitting models

First, fit one model to all the data.

Second, fit k models to k-folded data. Using k=5 in the current set-up. This is to be able to calculate model variability.

### Making predictions with models

Using the environmental layers, we use the models to predict probability of occurrence across the entire spatial extent. We do this once with the full model then k times with the models fitted to the k-folded data.

### Combining species outputs

Each of the by-species outputs (model prediction and model variability) are combined into single layers. Species richness is calculated by summing the predicted probability of occurence of each model and 'recording priority' is the mean of the model variabilities.

## Outputs

Here you can see some example outputs which may not make much sense as models are simple and currently got 5 unrelated species probabilities stacked.

![image](https://user-images.githubusercontent.com/17750766/214363557-92b4509c-3bf4-4d58-93c4-bbb5da8e2e2e.png)

Species richness values have been rounded to a whole number to a terra/leaflet issue.
