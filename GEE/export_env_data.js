// Load a landsat image and select three bands.
var landsat = ee.Image('LANDSAT/LC08/C02/T1_TOA/LC08_123032_20140515')
  .select(['B4', 'B3', 'B2']);

// Create a geometry representing an export region.
var geometry = ee.Geometry.Rectangle([-4.477366, 56.740975, -2.800270, 57.410659 ]);

Map.addLayer(geometry, {palette: 'FF0000'}, "Study Area");

// predictor variables
// Load WorldClim BIO Variables (a multiband image) from the data catalog
var BIO = ee.Image("WORLDCLIM/V1/BIO").resample('bicubic');

// Load elevation data from the data catalog and calculate slope, aspect, and a simple hillshade from the terrain Digital Elevation Model.
var Terrain = ee.Algorithms.Terrain(ee.Image("USGS/SRTMGL1_003")).toInt();

// Load NDVI 250 m collection and estimate median annual tree cover value per pixel
var MODIS = ee.ImageCollection("MODIS/006/MOD44B");
var MedianPTC = MODIS.filterDate('2015-01-01', '2015-12-31').select(['Percent_Tree_Cover']).median().toInt();

var dataset = ee.ImageCollection('MODIS/061/MOD13Q1').filter(ee.Filter.date('2018-01-01', '2018-12-01'));
var ndvi = dataset.select('NDVI').median().toInt();

// Combine bands into a single multi-band image

var predictors = Terrain.addBands(MedianPTC).addBands(ndvi);


// Mask out pixels
var predictors = predictors.clip(geometry);
var BIO = BIO.clip(geometry);

print('Band names:', predictors.bandNames());
print(predictors);

// view some of the layers
Map.addLayer(predictors, {bands:['elevation'], min: 0, max: 500,  palette: 'blue,yellow'}, 'Elevation (m)', 0);
Map.addLayer(BIO, {bands:['bio12'], min: 0, max: 2000, palette:'blue,yellow'}, 'Annual Mean Precipitation (mm)', 0); 
Map.addLayer(predictors, {bands:['Percent_Tree_Cover'], min: 0, max: 100, palette:'blue,yellow'}, 'Precent tree cover', 0); 
Map.addLayer(predictors, {bands:['NDVI'],min: 0.0,max: 8000.0,palette:'blue,yellow'}, 'NDVI');

var projection = predictors.select('elevation').projection().getInfo();

// Export the image, specifying the CRS, transform, and region.
Export.image.toDrive({
  image: BIO,
  description: 'bio-image',
  crs: projection.crs,
  crsTransform: projection.transform,
  region: geometry
});

Export.image.toDrive({
  image: predictors,
  description: 'predictors-image',
  crs: projection.crs,
  crsTransform: projection.transform,
  region: geometry
});