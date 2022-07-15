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
