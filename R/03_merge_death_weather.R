# 03_merge_death_weather.R


# Step 03 : Merge weather and death data.


# Project : deces_isq_chaleur
# Author  : Jeremie Boudreault
# Email   : Jeremie.Boudreault [at] inrs [dot] ca
# Depends : R (v4.1.2)
# License : CC BY-NC-ND 4.0


# Packages ---------------------------------------------------------------------


library(data.table)


# Imports ----------------------------------------------------------------------


# CDC weeks.
cdc_weeks <- data.table::fread("data/cdc/cdc_weeks.csv")

# Weekly deaths in Montreal.
deaths_mtl <- data.table::fread("data/isq/wdeaths_region.csv")
deaths_mtl <- deaths_mtl[REGION == "Montréal et Laval", ]

# Temperature values in Montreal.
weather_mtl <- qs::qread("data/eccc/mtl_stns_data_agg.qs")


# Expand CDC week to get a data.table ------------------------------------------


# Create a index of <WEEK> and all <DATE>.
cdc_weeks_dates <- lapply(1:nrow(cdc_weeks), FUN = function(i) {
    data.table::data.table(
        YEAR = cdc_weeks[i, YEAR],
        WEEK = cdc_weeks[i, WEEK],
        DATE = cdc_weeks[i, seq(from = START_DATE, to = END_DATE, by = 1L)]
    )
})

# Bind all list.
cdc_weeks_dates <- data.table::rbindlist(cdc_weeks_dates)

# Export for future use.
data.table::fwrite(
    x    = cdc_weeks_dates,
    file = "data/cdc/cdc_weeks_all_dates.csv",
    sep  = ";",
    dec  = ","
)


# Merge weather information with CDC weeks -------------------------------------


# Merge.
weather_w_week <- data.table::merge.data.table(
    x     = cdc_weeks_dates,
    y     = weather_mtl,
    by.y  = "date",
    by.x  = "DATE",
    all.x = TRUE
)

# Remove missing.
weather_w_week <- weather_w_week[!is.na(mean_temp), ]

# Summarize with weekly temperature values.
weather_weekly <- weather_w_week[, .(
    TEMP_MIN_MIN   = round(min(min_temp,   na.rm = TRUE), 2L),
    TEMP_MIN_MEAN  = round(mean(min_temp,  na.rm = TRUE), 2L),
    TEMP_MEAN_MIN  = round(min(mean_temp,  na.rm = TRUE), 2L),
    TEMP_MEAN_MEAN = round(mean(mean_temp, na.rm = TRUE), 2L),
    TEMP_MEAN_MAX  = round(max(mean_temp,  na.rm = TRUE), 2L),
    TEMP_MAX_MEAN  = round(mean(max_temp,  na.rm = TRUE), 2L),
    TEMP_MAX_MAX   = round(max(max_temp,   na.rm = TRUE), 2L)
), by = c("YEAR", "WEEK")]


# Merge weather and deaths -----------------------------------------------------


# Merge.
weather_death_weekly <- data.table::merge.data.table(
    x = weather_weekly,
    y = deaths_mtl,
    by = c("YEAR", "WEEK"),
    all.x = TRUE
)

# Remove empty deaths.
weather_death_weekly <- weather_death_weekly[!is.na(N_DEATH), ]


# Reformat table prior to export -----------------------------------------------


table_final <- weather_death_weekly[, .(
    YEAR, WEEK,
    START_DATE, MID_DATE, END_DATE,
    N_DEATH,
    TEMP_MIN_MIN, TEMP_MIN_MEAN,
    TEMP_MEAN_MIN, TEMP_MEAN_MEAN, TEMP_MEAN_MAX,
    TEMP_MAX_MEAN, TEMP_MAX_MAX
)]


# Export -----------------------------------------------------------------------


data.table::fwrite(
    x    = table_final,
    file = "data/weekly_death_weather.csv",
    sep  = ";",
    dec  = ","
)

