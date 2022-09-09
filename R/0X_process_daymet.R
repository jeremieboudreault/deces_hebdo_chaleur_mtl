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
var <- c("tmax", "prcp")[1L]

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
#pal <- RColorBrewer::brewer.pal(9, "Blues") # For precip.

# Brew 50 more colors using the palette "pal".
pal <- grDevices::colorRampPalette(colors = pal)(50L)

# Plot DayMet raster for the day 150.
day <- 120
terra::plot(
    x    = daymet[[day]],
    main = paste0(var, " from Daymet, day ", day, " of year ", year),
    col  = pal
)

# Add mask.
plot(mask_proj[, 1L], add = TRUE, lwd = 2)


# Crop and mask Daymet given the mask polygon ----------------------------------


# Extract limits from the mask
limits <- sf::st_bbox(mask_proj)

# Create extent from the mask.
extent <- terra::ext(c(
    limits[1L],
    limits[3L],
    limits[2L],
    limits[4L]
))

# Crop daymet.
daymet_crop <- terra::crop(daymet, extent)

# Plot a random day.
terra::plot(
    x    = daymet_crop[[day]],
    main = paste0("Cropped ", var, " from Daymet, day ", day, " of year ", year),
    col  = pal
)
plot(mask_proj[, 1L], add = TRUE, col = rgb(1, 1, 1, 0.2), lwd = 1.5)

# Mask daymet.
daymet_mask <- terra::mask(daymet_crop, terra::vect(mask_proj), touches = FALSE)

# Plot a day.
terra::plot(
    x    = daymet_mask[[day]],
    main = paste0("Masked ", var, " from Daymet, day ", day, " of year ", year),
    col  = pal
)
plot(mask_proj[, 1L], add = TRUE, col = NA, lwd = 1.5)


# Spatial aggregation by taking the mean value ---------------------------------


# Take the mean value over each layer.
values <- apply(terra::as.array(daymet_mask), 3L, mean, na.rm = TRUE)

# Create a data.table of the resulting time series.
daymet_values <- data.table(
    YEAR   = year,
    DOY    = 1:365,
    VAR    = var,
    VALUES = values,
    SOURCE = "Daymet"
)


# Validation with ECCC dataset -------------------------------------------------


# Load daily weather variables for Montreal/Laval of ECCC.
eccc <- qs::qread(file.path("data/eccc/mtl_data_daily_agg.qs"))

# Extract daily Tmax values for <YEAR> == year.
eccc_sub <- eccc[YEAR == year, .(YEAR = year, VAR = var, DOY = 1:365, VALUES = T_MAX, SOURCE = "ECCC")]
#eccc_sub <- eccc[YEAR == year, .(YEAR = year, VAR = var, DOY = 1:365, VALUES = PRCIP_SUM, SOURCE = "ECCC")]

# Merge both tables.
values_both <- rbind(daymet_values, eccc_sub)

# Coefficient of determination.
R2 <- cor(
    x = values_both[SOURCE=="Daymet", VALUES],
    y = values_both[SOURCE=="ECCC", VALUES]
)^2

# Plot both data.
ggplot(data = values_both) +
geom_line(aes(x = DOY, y = VALUES, col = SOURCE), alpha = 0.7) +
scale_color_manual(values = c(jtheme::colors$blue, jtheme::colors$red)) +
ggtitle("Daymet and ECCC values", paste0(toupper(var), " - ", year)) +
labs(x = "Day of year", y = "Values") +
annotate("text", x = Inf, y = -Inf, label = paste0("R2 =", round(R2, 3L)), hjust = 1.1, vjust = -1) +
#annotate("text", x = Inf, y = Inf, label = paste0("R2 =", round(R2, 3L)), hjust = 1.1, vjust = 1.6) +  # For precip
jtheme::jtheme(facet = TRUE, legend.title = FALSE)
#jtheme::jtheme(facet = TRUE, legend.title = FALSE, expand.y = FALSE) # For precip


# Exports to cache -------------------------------------------------------------


# To be completed...

