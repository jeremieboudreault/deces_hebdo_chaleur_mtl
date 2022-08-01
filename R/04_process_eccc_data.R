# 04_process_eccc_data.R


# Step 04 : Process ECCC data in a clean format.


# Project : deces_isq_chaleur
# Author  : Jeremie Boudreault
# Email   : Prenom.Nom@inrs.ca
# Depends : R (v4.2.1)
# Imports : jtheme (https://github.com/jeremieboudreault/jtheme)
# License : CC BY-NC-ND 4.0


# Packages ---------------------------------------------------------------------


library(data.table)
library(ggplot2)
library(jtheme)


# Imports ----------------------------------------------------------------------


# Path to files.
files_path <- "data/eccc/raw/"

# List files.
files <- list.files(files_path)
length(files)

# Load all files in a list.
eccc_raw <- lapply(
    X    = file.path(files_path, files),
    FUN  = data.table::fread,
    sep  = ",",
    fill = TRUE
)

# Bind all files.
eccc_raw <- data.table::rbindlist(
    l         = eccc_raw,
    fill      = TRUE,
    use.names = TRUE
)


# Basic exploration ------------------------------------------------------------


# Number of row.
nrow(eccc_raw)

# Names of columns.
colnames(eccc_raw)

# Class of columns.
data.frame(sapply(eccc_raw, class))

# Percentage of missing per columns.
t(data.frame(lapply(eccc_raw, function(w) round(mean(is.na(w)), 2L))))

# First top 10 rows.
head(eccc_raw)


# Processing hourly to daily values --------------------------------------------


# Extract <Date> from <Date/Time (LST)>.
eccc_raw[, Date := as.Date(substr(`Date/Time (LST)`, 1L, 10L))]

# Compute daily values by station, return NA when >= 1 value is missing per day.
eccc_daily <- eccc_raw[, .(
    T_MIN      = min(`Temp (°C)`),
    T_MEAN     = mean(`Temp (°C)`),
    T_MAX      = max(`Temp (°C)`),
    HMDX_MIN   = min(`Hmdx`),
    HMDX_MEAN  = mean(`Hmdx`),
    HMDX_MAX   = max(`Hmdx`),
    TDEW_MEAN  = mean(`Dew Point Temp (°C)`),
    WDCHL_MEAN = mean(`Wind Chill`),
    RELH_MEAN  = mean(`Rel Hum (%)`),
    PRES_MEAN  = mean(`Stn Press (kPa)`),
    WDSPD_MEAN = mean(`Wind Spd (km/h)`),
    PRCIP_SUM  = sum(`Precip. Amount (mm)`),
    VISB_MEAN  = mean(`Visibility (km)`)
), by = c("Station Name", "Climate ID", "Date", "Year", "Month", "Day")]

# Compute spatial aggregation of daily values for Montreal/Laval.
eccc_mtl_daily <- eccc_daily[, .(
    T_MIN      = mean(T_MIN,      na.rm = TRUE),
    T_MEAN     = mean(T_MEAN,     na.rm = TRUE),
    T_MAX      = mean(T_MAX,      na.rm = TRUE),
    HMDX_MIN   = mean(HMDX_MIN,   na.rm = TRUE),
    HMDX_MEAN  = mean(HMDX_MEAN,  na.rm = TRUE),
    HMDX_MAX   = mean(HMDX_MAX,   na.rm = TRUE),
    TDEW_MEAN  = mean(TDEW_MEAN,  na.rm = TRUE),
    WDCHL_MEAN = mean(WDCHL_MEAN, na.rm = TRUE),
    RELH_MEAN  = mean(RELH_MEAN,  na.rm = TRUE),
    PRES_MEAN  = mean(PRES_MEAN,  na.rm = TRUE),
    WDSPD_MEAN = mean(WDSPD_MEAN, na.rm = TRUE),
    PRCIP_SUM  = mean(PRCIP_SUM,   na.rm = TRUE),
    VISB_MEAN  = mean(VISB_MEAN,  na.rm = TRUE)
), by = c("Date", "Year", "Month", "Day")]

# Update name of the resulting dataset.
data.table::setnames(eccc_mtl_daily,
    old = c("Date", "Year", "Month", "Day"),
    new = c("DATE", "YEAR", "MONTH", "DAY")
)

# Reorder data using <DATE>.
eccc_mtl_daily <- eccc_mtl_daily[order(DATE), ]

# Remove data after July 27 (Date of download from ECCC).
eccc_mtl_daily <- eccc_mtl_daily[DATE <= "2022/07/27", ]

# Final percentage of missing.
t(data.frame(lapply(eccc_mtl_daily, function(w) round(mean(is.na(w)), 2L))))


# Plots ------------------------------------------------------------------------


# Temperature metrics.
ggplot(eccc_mtl_daily[DATE > "2010-01-01", ], mapping = aes(x = DATE)) +
    geom_line(aes(y = T_MAX,  col = "Max"), lwd = 0.3) +
    geom_line(aes(y = T_MIN,  col = "Min"), lwd = 0.3) +
    geom_line(aes(y = T_MEAN, col = "Moy"), lwd = 0.3) +
    scale_x_date(expand = expansion(mult = c(0.01, 0.02))) +
    scale_color_manual(values = c(colors$red, colors$blue, "black")) +
    ggtitle("Températures enregistrées à Montréal et Laval") +
    labs(x = "Date", y = "Température (ºC)") +
    jtheme(legend.title = FALSE)

# Save plot.
jtheme::save_ggplot("plots/fig_3_1_montreal_temp.jpg", size = "rect")

# Humidex values.
ggplot(eccc_mtl_daily[DATE > "2010-01-01", ], mapping = aes(x = DATE)) +
    geom_point(aes(y = HMDX_MIN,  col = "Min"), lwd = 0.3) +
    geom_point(aes(y = HMDX_MEAN, col = "Moy"), lwd = 0.3) +
    geom_point(aes(y = HMDX_MAX,  col = "Max"), lwd = 0.3) +
    scale_x_date(expand = expansion(mult = c(0.01, 0.02))) +
    scale_color_manual(values = c(colors$red, colors$blue, "black")) +
    ggtitle("Valeurs d'Humidex enregistrées à Montréal et Laval") +
    labs(x = "Date", y = "Humidex") +
    jtheme(legend.title = FALSE)

# Save plot.
jtheme::save_ggplot("plots/fig_3_2_montreal_hmdx.jpg", size = "rect")


# Exports ----------------------------------------------------------------------


# Spatially aggregated daily data for Montreal/Laval.
qs::qsave(eccc_mtl_daily, "data/eccc/mtl_data_daily_agg.qs")

