
[Details](#Details) 
/ [Slides](#Slides) 
/ [Check](#Checks) 
/ [Resources](#Resources) 
/ [R at vEGU2021](#r-at-egu2021)
/ [Citation](#Citation)

# Using R in Hydrology - vEGU2021 Short Course

Conveners: Katie Smith, Louise Slater, Guillaume Thirel, Ilaria Prosdocimi and Abdou Khouakhi


## Details 
- **Where?** Wednesday 28 April, 10:00-11:00 CEST using [Zoom](https://zoom.us/ "Link to zoom webpage") webinar platform (link to zoom meeting in the session page)
- [Using R in Hydrology vEGU21 (link to session)](https://meetingorganizer.copernicus.org/EGU21/session/38926 "Link to vEGU Session Description")
- **What?** This session is aimed at hydrologists who are interested in hearing more about R as well as those who are advanced R programmers wanting to discuss recent developments in an open environment. 
- The session is organised in cooperation with the [Young Hydrologic Society (YHS)](https://younghs.com/ "Young Hydrologic Society website") .
- Participants are invited to post and discuss questions in the [Hydrology in R Facebook group](https://www.facebook.com/groups/1130214777123909/ "link to Hydro-R Facebook group")


## Slides
All materials to reproduce the slides and analyses are available on this repository.
To get everything (slides, data, code, etc.) onto your local machine, we recommend to [download the whole github course repository](https://github.com/hydrosoc/rhydro_vEGU21/archive/refs/heads/main.zip). 

Individual presentations (*.html* or PDF files) can be downloaded from the [presentations folder](./presentations) and viewed in a web browser.

Links to individual presentations (for direct view in browser) are below:


- [Course intro](https://hydrosoc.github.io/rhydro_vEGU21/presentations/00.%20intro_slides/rhydro_intro_slides) // K. Smith
- [Data Retrieval](https://hydrosoc.github.io/rhydro_vEGU21/presentations/01.%20data_retrieval_LS/DataRetrieval) // L. Slater 
- [Extremes Modelling](https://hydrosoc.github.io/rhydro_vEGU21/presentations/02.extremes_IP/02_StatModExtremes) // I. Prosdocimi
- [Hydrological Modelling ](https://hydrosoc.github.io/rhydro_vEGU21/presentations/03.%20hydro_model_GT/hydro_modelling.html) // G. Thirel
- [Hydrological Forecasting](https://hydrosoc.github.io/rhydro_vEGU21/presentations/04.hydro_forecasting_KAS/hydro_forecasting_slides) // K. Smith
- [Google Earth Enigne](https://hydrosoc.github.io/rhydro_vEGU21/presentations/05.GEE_AK/GEE_AK) // A.Khouakhi

## Checks

To follow along during the session, participants need: 

- A [Google Earth Engine (GEE) account](https://signup.earthengine.google.com/#!/) to be able to use rgee to access GEE data and computational capabilities. 
- To [install](https://github.com/r-spatial/sf#installing) `rgee` package and its dependencies - install.packages ("rgee")- and run `ee_install()` in the console to help setup `rgee`. Details on how to setup and initialize GEE from within R can be found [here](https://csaybar.github.io/rgee-examples/#Installation) 

participants may wish also to install the following packages before the session: install.packages(c( "tidyverse", "sf",  "leaflet", "ncdf4","lubridate", "ggplot2", "raster", "rgdal", "stars","rgee","cptcity"))


## Resources:
- Slater et al. 2019, [Using R in Hydrology: a review of recent developments and future directions](https://hess.copernicus.org/articles/23/2939/2019/), HESS
- Astagneau et al. 2021, [Hydrology modelling R packages: a unified analysis of models and practicalities from a user perspective](https://hess.copernicus.org/preprints/hess-2020-498/), HESSD
- [CRAN Hydrology TaskView](https://cran.r-project.org/web/views/Hydrology.html "Hydrology TaskView on CRAN")
- <a href="https://odelaigue.github.io/airGR/" rel="nofollow">airGR</a> - a description of the airGR package (INRAE GR Hydrological Models)
- <a href="https://ropensci.github.io/hddtools/" rel="nofollow">hddtools</a> - an R package to facilitate access to a variety of online open data sources for hydrologists
- <a href="https://r-spatial.github.io/rgee/index.html" rel="nofollow">rgee</a> - An R binding package for calling Google Earth Engine API from within R


## R at vEGU2021

There are a number of other short courses using R that may be of interest to you:

- <a href="https://meetingorganizer.copernicus.org/EGU21/session/38943 " rel="nofollow"> CoSMoS R-package: Simulating random fields and univariate or multivariate timeseries in hydroclimatology and beyond</a>


## Citation

Please refer to this course as:

- Katie Smith, Louise Slater, Guillaume Thirel, Ilaria Prosdocimi, Abdou Khouakhi. (2021, April). Using R in Hydrology at vEGU2021 
