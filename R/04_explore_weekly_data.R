# 04_explore_weekly_data.R


# Step 04 : Explore weekly data.


# Project : deces_isq_chaleur
# Author  : Jeremie Boudreault
# Email   : Jeremie.Boudreault [at] inrs [dot] ca
# Depends : R (v4.1.2)
# License : CC BY-NC-ND 4.0


# Packages ---------------------------------------------------------------------


library(corrplot)
library(data.table)
library(ggplot2)
library(jtheme)


# Function ---------------------------------------------------------------------


corrplot_full <- function(mcor, title = NA) {
    corrplot::corrplot(
        corr   = mcor,
        method = "number",
        title  = title,
        type   = "lower",
        tl.pos = "lt",
        tl.col = "black",
        tl.cex = 0.8,
        tl.srt = 30,
        cl.pos = "n",
        mar    = if(is.na(title)) c(0, 0, 0.2, 0) else c(0, 0, 2, 0)
    )
    corrplot::corrplot(
        corr   = mcor,
        method = "ellipse",
        type   = "upper",
        tl.col = "black",
        tl.pos = "n",
        add = TRUE
    )
}


# Imports ----------------------------------------------------------------------


data <- data.table::fread("data/weekly_death_weather_cleaned.csv", dec = ",")


# Correlation analysis between temperature data --------------------------------


# Initial analysis with all months.
mcor <- cor(data[, .(N_DEATH, TEMP_MIN_MIN, TEMP_MIN_MEAN, TEMP_MEAN_MIN,
                     TEMP_MEAN_MEAN, TEMP_MEAN_MAX, TEMP_MAX_MEAN, TEMP_MAX_MAX)])
corrplot_full(mcor, "Correlation matrix (all months)")

# Analysis with summer months only.
mcor_summer <- cor(data[WEEK > 16 & WEEK < 38,
                        .(N_DEATH, TEMP_MIN_MIN, TEMP_MIN_MEAN, TEMP_MEAN_MIN,
                         TEMP_MEAN_MEAN, TEMP_MEAN_MAX, TEMP_MAX_MEAN, TEMP_MAX_MAX)])
corrplot_full(mcor_summer, "Correlation matrix (may-september)")

