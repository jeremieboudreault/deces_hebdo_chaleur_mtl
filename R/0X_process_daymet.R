# 0X_process_daymet.R


# Step 0X : Process daymet database into a spatially aggregated time series.


# Project : deces_hebdo_chaleur_mtl
# Author  : Jeremie Boudreault
# Email   : Prenom.Nom@inrs.ca
# Depends : R (v4.2.1)
# Imports : jtheme (https://github.com/jeremieboudreault/jtheme)
# License : CC BY-NC-ND 4.0


# Packages ---------------------------------------------------------------------


library(data.table)
library(sf)
library(ggplot2)
library(terra)


# Import a sample of Daymet NetCDF ---------------------------------------------


# Path to daymet NetCDF.
daymet_path <- "/Users/jeremieboudreault/Downloads/"

# Set parameters.
year <- 2021
var <- "tmax"

# File name.
filename <- sprintf("daymet_v4_daily_na_%s_%s.nc", var, year)

# Load a unique raster of Daymet.
daymet <- terra::rast(file.path(daymet_path, filename))


