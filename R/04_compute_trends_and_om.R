# 04_compute_trends_and_om.R


# Step 04 : Compute trends in data and over-mortality (OM).


# Project : deces_isq_chaleur
# Author  : Jeremie Boudreault
# Email   : Jeremie.Boudreault [at] inrs [dot] ca
# Depends : R (v4.1.2)
# License : CC BY-NC-ND 4.0


# Packages ---------------------------------------------------------------------


library(data.table)
library(ggplot2)
library(ggpubr)
library(jtheme)


# Imports ----------------------------------------------------------------------


data <- data.table::fread("data/weekly_death_weather_cleaned.csv", dec = ",")


# Method 1) Monthly trends -----------------------------------------------------


# First, we create a copy the dataset with the period prior to COVID-19.
data_wout_covid <- data.table::copy(data[YEAR < 2020, ])

# Extract <MONTH> from the mid-date.
data_wout_covid[, MONTH := as.integer(format(MID_DATE, "%m"))]
data[,            MONTH := as.integer(format(MID_DATE, "%m"))]

# Summary trend by month.
trend_month <- data_wout_covid[
    j  = .(TREND_MONTH = mean(N_DEATH, na.rm = TRUE)),
    by = "MONTH"
]

# Merge trend with month in the original dataset.
data <- data.table::merge.data.table(
    x     = data,
    y     = trend_month,
    by    = "MONTH",
    all.x = TRUE
)

# Plot resulting trend.
p1 <- ggplot(data, aes(y = N_DEATH, x = MID_DATE)) +
    geom_line() +
    geom_line(aes(x = MID_DATE, y = TREND_MONTH), col = colors$blue) +
    ggtitle("a) Tendances mensuelles") +
    labs(y = "Décès hebdomadaires", x = "") +
    jtheme(facets = TRUE)
p1

