# You will need the following libraries
library(rgee, quietly = T)
library(tidyverse)
library(sf)
library(lubridate)
library(stars)
library(raster)
library(cptcity)

# Initialize ee
ee_Initialize(drive = T, quiet = T) # more info on the rgee setup can found here  https://csaybar.github.io/rgee-examples/ 

# get a rough location within a given catchment area (here we use a location within the Upper catchment of Niger basin)
poi <- ee$Geometry$Point(-9.3, 10.38)

# Examples of EE Data Collections 
# you can run `ee_utils_dataset_display()`, a helper functions to open a web browser and search the catalog.


# Hydrosheds -Basins - level 4
hybas4 <- "WWF/HydroSHEDS/v1/Basins/hybas_4"
# River network
ffriver <- "WWF/HydroSHEDS/v1/FreeFlowingRivers"
# SMAP soil moisture 10km
smap10km <- "NASA_USDA/HSL/SMAP10KM_soil_moisture"
# Open land map monthly precip 1km
mth_prcp1km <- "OpenLandMap/CLM/CLM_PRECIPITATION_SM2RAIN_M/v01"
# JRC Global Surface Water Mapping Layers 30m
srfce_wtr30m <- "JRC/GSW1_2/GlobalSurfaceWater"
# Copernicus landcover 100m
cgls100m <- "COPERNICUS/Landcover/100m/Proba-V-C3/Global/2019"
# Sentinel 2- Surface reflectance
S2SR <- "COPERNICUS/S2_SR"

## Get data

# get the basin boundary
basin <- ee$FeatureCollection(hybas4)$filterBounds(poi)
# river network
riverNet <- ee$FeatureCollection(ffriver)$filterBounds(basin)
# get July rainfall over the basin
mth_prcp_jul <- ee$Image(mth_prcp1km)$clip(basin)$select("jul")
# get SMAP soil moisture and select ssm band (layer) over the basin
smap_sm <- ee$ImageCollection(smap10km)$filterBounds(basin)$select("ssm")$first()$clip(basin)
# get the surface Water- select frequency with which water was present
jrc_srfce_wtr <- ee$Image(srfce_wtr30m)$select("occurrence")$clip(basin)
# get land cover CGLC 15-19 and select the landcover classes
clc2019 <- ee$Image(cgls100m)$select("discrete_classification")$clip(basin)


# define visualisation parameters
swater_vis <- list(min = 0, max = 100, palette = c("ffffff", "ffbbbb", "0000ff"))
smap_vis <- list(min = 0.0, max = 28.0, palette = cpt("pj_4_earth"))
prcp_vis <- list(min = 0, max = 380, palette = cpt("ncl_precip3_16lev"))
rivNet_vis <- list(width = 1.0, color = "blue")

# initialize a map and add layers

Map$centerObject(basin)
basin_layer <- Map$addLayer(
  basin,
  {},
  "basin"
)
riverNet_layer <- Map$addLayer(riverNet, rivNet_vis, "River network")
jul_prcp_layer <- Map$addLayer(mth_prcp_jul, prcp_vis, "July Precipitation in mm", legend = T)
smapSl_layer <- Map$addLayer(smap_sm, smap_vis, "SMAP soil moisture in mm")
srfce_water_layer <- Map$addLayer(jrc_srfce_wtr, swater_vis, "Surface water occurrence %")
clc_layer <- Map$addLayer(
  clc2019,
  {},
  "Copernicus Land Cover 100m"
)

## Add layers to map
# use slider to visualize
basin_layer + jul_prcp_layer
# with map spliter
smapSl_layer | srfce_water_layer

# add all layers
basin_layer + riverNet_layer + srfce_water_layer + smapSl_layer + clc_layer

# GEE and ggplot
# Here, we use the basin geometry to locally download the gridded rainfall data at the basin level

# basin to ee Geometry
ee_basin <- basin$geometry()
# smap sm to ratser
prcp_raster <- ee_as_raster(mth_prcp_jul, region = ee_basin, quiet = T)
# raster to df
ras_todf <- as.data.frame(prcp_raster, xy = T) %>%
  drop_na() %>%
  filter(jul > 0)
# basin to sf
basin_sf <- ee_as_sf(basin)

# Integrate GEE data with other ggplot layers
ggplot(basin_sf) +
  geom_raster(
    data = ras_todf,
    aes(x = x, y = y, fill = jul)
  ) +
  scale_fill_gradientn(colours = cpt("ncl_precip3_16lev")) +
  geom_sf(fill = NA, color = "red") +
  labs(fill = "July precip [mm]") +
  theme_bw()


## Identify water and non-water
# Here, we are going to train a simple machine learning algorithm to distinguish between water
# and non water areas for a given month at 10 m resolution within our basin using GEE data.
# For training the model, we use Sentinel 2 surface reflectance images, derived the water and
# vegetation indices (NDWI and NDVI) in addition to other Sentinel 2 bands.

# get S2 image collection
getS2Image <- function(date, cldPerc) {
  date <- ee$Date(date)
  S2_collection <- (
    ee$ImageCollection("COPERNICUS/S2_SR")
    $filterBounds(basin)
    $filterDate(date, date$advance(1, "month"))
    $filterBounds(basin)
    $filter(ee$Filter$lt("CLOUDY_PIXEL_PERCENTAGE", cldPerc))
  )
  # print metadata
  print(ee_print(S2_collection), max = 1)
  # reduce using median
  S2_median <- S2_collection$
    reduce(ee$Reducer$median())
  # clip
  S2_median <- S2_median$divide(10000)$clip(basin)
  return(S2_median)
}

## call the function

# select a date
dt <- "2021-01-01"
s2_img <- getS2Image(date = dt, cldPerc = 1)

## Identify water and non-water
## Calculate NDVI and NDWI and add that to the images to use for training

# Normalized difference vegetation index
getNDVI <- function(img) {
  img$normalizedDifference(c("B8_median", "B4_median"))
}
# Normalized difference water index
getNDWI <- function(img) {
  img$normalizedDifference(c("B3_median", "B8_median"))
}

# get NDVI and NDWI
S2_NDVI <- getNDVI(s2_img)$rename("NDVI")
S2_NDWI <- getNDVI(s2_img)$rename("NDWI")
# get info
ee_print(S2_NDVI)

## Identify water and non-water
band_stack <- (
  ee$Image(s2_img)
  $addBands(S2_NDVI)
  $addBands(S2_NDWI)
  $float()
)
# select only bands with 10 resolution
bands <- c("NDWI", "NDVI", "B2_median", "B3_median", "B4_median", "B8_median")
band_stack <- band_stack$select(bands)
# get info
ee_print(band_stack)


# Display the classification result and the input image.
s2Image_vis <- list(bands = c("B4_median", "B3_median", "B2_median"), min = 0, max = 0.3)
class_vis <- list(min = 0, max = 1, palette = cpt("neota_base_blue"))


# Visualize the S2 image and the NDWI layers
Map$centerObject(basin, zoom = 10)
Map$addLayer(
  eeObject = s2_img,
  visParams = s2Image_vis,
  name = "S2 RGB"
) +
  Map$addLayer(
    eeObject = S2_NDWI,
    visParams = class_vis,
    name = "NDWI"
  )

## Get training datasets

## Create some training polygons for water and non water areas based on the JRC surface water
# and S2 image layers

# Manually created polygons.
water1 <- ee$Geometry$Rectangle(-08.1944, 11.5764, -08.1869, 11.5817)
water2 <- ee$Geometry$Rectangle(-08.8728, 10.9167, -08.8714, 10.9174)
nonWater1 <- ee$Geometry$Rectangle(-10.6078, 10.0973, -10.6034, 10.1003)
nonWater2 <- ee$Geometry$Rectangle(-07.9872, 12.5496, -7.9740, 12.5674)

# Make a FeatureCollection from the above geometries.
tr_polygons <- ee$FeatureCollection(c(
  ee$Feature(water1, list(class = 0)),
  ee$Feature(water2, list(class = 0)),
  ee$Feature(nonWater1, list(class = 1)),
  ee$Feature(nonWater2, list(class = 1))
))

## Get training datasets
# Here we sample data for training using the created polygon
# We use use the Random Forest classifier to train the model

# Get the values for all pixels in each polygon in the training.
training <- band_stack$sampleRegions(
  # Get the sample from the polygons FeatureCollection
  collection = tr_polygons,
  # Keep this list of properties from the polygons.
  properties = list("class"),
  # Set the scale to get S2 image pixels in the polygons
  scale = 10
)
# Create a Random Forest classifier
rf_classifier <- ee$Classifier$smileRandomForest(numberOfTrees = 50)
# Train the classifier.
trained <- rf_classifier$train(training, "class", bands)
# Classify the image.
classified_img <- band_stack$classify(trained)
# get class #1 of surface water
Water_class <- classified_img$eq(0)
water <- classified_img$updateMask(Water_class)