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


# Load mask to crop and mask Daymet --------------------------------------------


# Load RSS of Quebec.
mask <- sf::read_sf("data/rss/Territoires_RSS_2022.shp")

# Subset only Montreal and Laval RSS.
mask <- mask[mask$RSS_code %in% c("06", "13"), ]

# Project mask to CRS of Daymet.
mask_proj <- sf::st_transform(mask, terra::crs(daymet))


# Plot Daymet and mask ---------------------------------------------------------


# Extract RdBu palette colors.
pal <- rev(RColorBrewer::brewer.pal(9, "RdBu")[-5L])

# Brew 50 more colors using the palette "pal".
pal <- grDevices::colorRampPalette(colors = pal)(50L)

# Plot DayMet raster for the day 150.
day <- 120
par(mfrow=c(1, 3))
terra::plot(
    x    = daymet[[day]],
    main = paste0(var, " from Daymet, day ", day, " of year ", year),
    col  = pal
)

# Add mask.
plot(mask_proj, add = TRUE, lwd = 2)


# Crop and mask Daymet given the mask polygon ----------------------------------


# Extract limits from the mask
cma_limits <- sf::st_bbox(mask_proj)

# Create extent from the mask.
extent <- terra::ext(c(
    cma_limits[1L],
    cma_limits[3L],
    cma_limits[2L],
    cma_limits[4L]
))

# Crop daymet.
daymet_crop <- terra::crop(daymet, extent)

# Plot a random day.
terra::plot(daymet_crop[[day]], main = day, col = pal)
plot(mask_proj[, 1L], add = TRUE, col = rgb(1, 1, 1, 0.2), lwd = 1.5)


