# 05_merge_death_weather.R


# Step 05 : Merge weather and death data at the weekly level.


# Project : deces_isq_chaleur
# Author  : Jeremie Boudreault
# Email   : Prenom.Nom@inrs.ca
# Depends : R (v4.2.1)
# Imports : jtheme (https://github.com/jeremieboudreault/jtheme)
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
weather_mtl <- qs::qread("data/eccc/mtl_data_daily_agg.qs")


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
    by    = c("DATE", "YEAR"),
    all.x = TRUE
)

# Remove missing.
weather_w_week <- weather_w_week[!is.na(T_MEAN), ]

# Summarize with weekly temperature values.
weather_weekly <- weather_w_week[, .(
    T_MIN_WMEAN      = round(mean(T_MIN,      na.rm = TRUE), 2L),
    T_MEAN_WMEAN     = round(mean(T_MEAN,     na.rm = TRUE), 2L),
    T_MAX_WMEAN      = round(mean(T_MAX,      na.rm = TRUE), 2L),
    HMDX_MIN_WMEAN   = round(mean(HMDX_MIN,   na.rm = TRUE), 2L),
    HMDX_MEAN_WMEAN  = round(mean(HMDX_MEAN,  na.rm = TRUE), 2L),
    HMDX_MAX_WMEAN   = round(mean(HMDX_MAX,   na.rm = TRUE), 2L),
    TDEW_MEAN_WMEAN  = round(mean(TDEW_MEAN,  na.rm = TRUE), 2L),
    WDCHL_MEAN_WMEAN = round(mean(WDCHL_MEAN, na.rm = TRUE), 2L),
    RELH_MEAN_WMEAN  = round(mean(RELH_MEAN,  na.rm = TRUE), 2L),
    PRES_MEAN_WMEAN  = round(mean(PRES_MEAN,  na.rm = TRUE), 2L),
    WDSPD_MEAN_WMEAN = round(mean(WDSPD_MEAN, na.rm = TRUE), 2L),
    PRCIP_SUM_WSUM   = round(sum(PRCIP_SUM,   na.rm = TRUE), 2L),
    VISB_MEAN_WMEAN  = round(mean(VISB_MEAN,  na.rm = TRUE), 2L)
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
    YEAR,
    WEEK,
    START_DATE,
    MID_DATE,
    END_DATE,
    N_DEATH,
    T_MIN_WMEAN,
    T_MEAN_WMEAN,
    T_MAX_WMEAN,
    HMDX_MIN_WMEAN,
    HMDX_MEAN_WMEAN,
    HMDX_MAX_WMEAN,
    TDEW_MEAN_WMEAN,
    WDCHL_MEAN_WMEAN,
    RELH_MEAN_WMEAN,
    PRES_MEAN_WMEAN,
    WDSPD_MEAN_WMEAN,
    PRCIP_SUM_WSUM,
    VISB_MEAN_WMEAN
)]


# Export -----------------------------------------------------------------------


data.table::fwrite(
    x    = table_final,
    file = "data/weekly_death_weather.csv",
    sep  = ";",
    dec  = ","
)

