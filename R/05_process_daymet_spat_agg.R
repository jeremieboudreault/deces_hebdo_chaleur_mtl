# 05_process_daymet_spat_agg.R


# Step 05 : Process daymet database into a spatially aggregated time series.


# Project : deces_hebdo_chaleur_mtl
# Author  : Jeremie Boudreault
# Email   : Prenom.Nom@inrs.ca
# Depends : R (v4.2.1)
# License : CC BY-NC-ND 4.0


# Note : User must first download DayMet NetCDF using the bash script located
#        in data/daymet/. Then, user must update the path to daymet NetCDF
#        variable 'daymet_path' in the "Settings for Daymet" section below.


# Packages ---------------------------------------------------------------------


library(data.table)
library(sf)
library(ggplot2)
library(terra)


# Globals ----------------------------------------------------------------------


# Should the plot be displayed of not (slowing down the running of the code).
show_plot <- FALSE

# Extend cache size of GDAL to 5gb to handle DayMet NetCDF.
terra::gdalCache(5000L)


# Settings for DayMET ----------------------------------------------------------


# Path to daymet NetCDF.
daymet_path <- "/Volumes/ExtDataPhD/daymet/"

# Period.
year_start <- 1980L
year_end <- 2021L

# Variables.
vars <- c("tmax", "tmin", "srad", "prcp", "swe", "dayl", "vp")

# File name.
filename <- sprintf("daymet_v4_daily_na_%s_%s.nc", vars[1L], year_end)

# Load a sample raster from Daymet.
daymet <- terra::rast(file.path(daymet_path, filename))


# Settings for the mask --------------------------------------------------------


# Load mask using RSS of Quebec.
mask <- sf::read_sf("data/rss/Territoires_RSS_2022.shp")

# Subset only Montreal and Laval RSS.
mask <- mask[mask$RSS_code %in% c("06", "13"), ]

# Project mask to CRS of Daymet.
mask_proj <- sf::st_transform(mask, terra::crs(daymet)) |> sf::st_union()

# Extract limits from the mask
limits <- sf::st_bbox(mask_proj)

# Create extent from the mask.
extent <- terra::ext(c(
    limits[1L],
    limits[3L],
    limits[2L],
    limits[4L]
))


# Plot a sample of Daymet ------------------------------------------------------


if (show_plot) {

    # Extract RdBu palette colors.
    pal <- rev(RColorBrewer::brewer.pal(9, "RdBu")[-5L])
    #pal <- RColorBrewer::brewer.pal(9, "Blues") # For precip.

    # Brew 50 more colors using the palette "pal".
    pal <- grDevices::colorRampPalette(colors = pal)(50L)

    # Plot DayMet raster for the day 150.
    day <- 120L
    terra::plot(
        x    = daymet[[day]],
        main = sprintf("%s from Daymet, day %s of year %s.", vars[1L], day, year_end),
        col  = pal
    )

    # Add mask.
    plot(mask_proj[, 1L], add = TRUE, lwd = 2)

}


# Batch processing of DayMet NetCDF --------------------------------------------


# Loop all variables.
for (var in vars) {

# Loop on all years.
for (year in year_start:year_end) {

    # Message.
    message("Processing ", var, " of DayMet, year ", year, ".")

    # File name.
    filename <- sprintf("daymet_v4_daily_na_%s_%s.nc", var, year)

    # Load a the corresponding DayMet NetCDF.
    daymet <- terra::rast(file.path(daymet_path, filename))

    # Extract values and take the spatial mean value over each layer.
    values_exext <- exactextractr::exact_extract(
        x       = daymet,
        y       = mask_proj,
        fun     = "mean"
    )

    # Create a data.table of the resulting time series.
    daymet_values <- data.table(
        YEAR   = year,
        DOY    = 1:365,
        VAR    = var,
        VALUES = values
    )

    # Export to cache.
    qs::qsave(
        x    = daymet_values,
        file = file.path("cache", sprintf("daymet_spat_agg_%s_%s.qs", var, year))
    )

# End of loop for <year>.
}

# End of loop for <var>.
}


# Create a nice table with all values ------------------------------------------


# Load all Daymet values.
daymet_values <- do.call(
    what = rbind,
    args = lapply(file.path(list.files("cache", full.names = TRUE)), qs::qread)
)

# Create <DATE>, <MONTH>, <DAY> features.
daymet_values[, DATE  := as.Date(DOY - 1L, origin = paste0(YEAR, "-01-01"))]
daymet_values[, MONTH := as.integer(format(DATE, "%m"))]
daymet_values[, DAY   := as.integer(format(DATE, "%d"))]

# Map <VAR> to standard names.
daymet_values[VAR == "tmax", VAR := "T_MAX"]
daymet_values[VAR == "tmin", VAR := "T_MIN"]
daymet_values[VAR == "srad", VAR := "SRAD"]
daymet_values[VAR == "prcp", VAR := "PRCIP_SUM"]

# Round values prior to export.
daymet_values[, VALUES := round(VALUES, 3L)]

# Create a wider data.table (dcast).
daymet_dt <- data.table::dcast.data.table(
    data      = daymet_values,
    formula   = DATE + YEAR + MONTH + DAY + DOY ~ VAR,
    value.var = "VALUES"
)

# Create <T_MEAN> as a mean of <T_MAX> and <T_MIN>
daymet_dt[, T_MEAN := (T_MAX + T_MIN)/2]

# Export.
data.table::fwrite(
    x    = daymet_dt,
    file = "data/daymet/daymet_data_mtl_spat_agg.csv",
    dec  = ",",
    sep  = ";"
)


# Validation with ECCC data ----------------------------------------------------


# Load daily weather variables for Montreal/Laval of ECCC.
eccc <- qs::qread("data/eccc/mtl_data_daily_agg.qs")

# Filter out some rows and columns.
eccc_sub <- eccc[
    i = YEAR >= year_start & YEAR <= year_end,
    j = .(YEAR, DATE, DOY = as.integer(format(DATE, "%j")),
          T_MAX, T_MIN, T_MEAN, PRCIP_SUM, SRAD = VISB_MEAN)
][DOY != 366L, ]

# Melt ECCC data.
eccc_melt <- data.table::melt.data.table(
    data     = eccc_sub,
    id.vars  = c("YEAR", "DATE", "DOY"),
    var      = "VAR",
    value    = "VALUES"
)[order(DATE), ]

# Melt Daymet data.
daymet_melt <- data.table::melt.data.table(
    data     = daymet_dt[, -c("MONTH", "DAY")],
    id.vars  = c("YEAR", "DATE", "DOY"),
    var      = "VAR",
    value    = "VALUES"
)[order(DATE), ]

# Spot check that both table have the same information.
nrow(daymet_melt) == nrow(eccc_melt)

# Merge both table.
values <- rbind(
    daymet_melt[, .(DOY, YEAR, VAR, VALUES, SOURCE = "Daymet")],
    eccc_melt[,   .(DOY, YEAR, VAR, VALUES, SOURCE = "ECCC")]
)

# Plot all data.
for (var in c("T_MAX", "T_MIN", "T_MEAN", "PRCIP_SUM", "SRAD")) {

    # Create a new table with values of ECCC and Daymet.
    values_sub <- data.table::data.table(
        ECCC   = values[SOURCE == "ECCC" & VAR == var, VALUES],
        Daymet = values[SOURCE == "Daymet" & VAR == var, VALUES]
    )

    # Compute R2.
    R2 <- values_sub[, round(cor(ECCC, Daymet, use = "complete.obs"), 3L)]

    # Set variable name to lower case.
    varl <- tolower(var)

    # First plot --- all data.
    p1 <- ggplot(data = values[VAR == var, ]) +
    geom_line(aes(x = DOY, y = VALUES, col = SOURCE), lwd = 0.2, alpha = 0.8) +
    scale_color_manual(values = c(jtheme::colors$blue, jtheme::colors$red)) +
    ggtitle(
        label  =   paste0("Daymet and ECCC values"),
        subtitle = paste0(varl)
    ) +
    labs(x = "Day of year", y = paste0("Values (", varl, ")")) +
    facet_wrap(facets = "YEAR") +
    jtheme::jtheme(facet = TRUE, show_leg_title = FALSE)

    # Plot.
    print(p1)

    # Save plot to plots/daymet/.
    jtheme::save_ggplot(
        file = paste0("plots/daymet/3_valid_all_values_", varl, ".jpg"),
        size = "sqrbig"
    )

    # Second plot --- scatter plot.
    p2 <- ggplot(data = values_sub, aes(x = ECCC, y = Daymet)) +
    geom_point(alpha = 0.1) +
    ggtitle(
        label    = paste0("Scatterplot of Daymet and ECCC ", varl, " values"),
        subtitle = paste0("R² = ", round(R2, 3L))
    ) +
    geom_abline(intercept = 0L, slope = 1L, col = jtheme::colors$red) +
    labs(x = paste0("ECCC (", varl, ")"), y = paste0("Daymet (", varl, ")")) +
    jtheme::jtheme(facet = TRUE, show_leg_title = FALSE)

    # Plot.
    print(p2)

    # Save plot to plots/daymet/.
    jtheme::save_ggplot(
        file = paste0("plots/daymet/4_valid_scatterplot_", varl, ".jpg"),
        size = "sqr"
    )

}
