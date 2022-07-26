# 03_download_eccc_data.R


# Step 03 : Download data from ECCC given the station list.


# Project : deces_isq_chaleur
# Author  : Jeremie Boudreault
# Email   : [Name].[Surname] [at] inrs [dot] ca
# Depends : R (v4.1.2)
# Imports : jtheme (https://github.com/jeremieboudreault/jtheme)
# License : CC BY-NC-ND 4.0


# Packages ---------------------------------------------------------------------


library(data.table)
library(ggplot2)
library(jtheme)
library(weathercan)


# Imports ----------------------------------------------------------------------


# List of stations.
stns_list <- data.table::fread("data/eccc/stns_mtl_list.csv", dec = ",")


# Download data for the Monteal stations ---------------------------------------


# Note : This step is very long.

# Download from ECCC by looping on all stations.
for (stn_id in stns_list$station_id) {

    # Download data from ECCC.
    weather_data_tmp <- weathercan::weather_dl(
        station_ids = stn_id,
        interval    = "hour",
        start       = "1979-01-01",
        verbose     = TRUE
    )

    # Save file if not empty.
    if (nrow(weather_data_tmp) > 0) {
        data.table::fwrite(
            x     = weather_data_tmp,
            file  = paste0("data/eccc/", stn_id, ".csv"),
            sep   = ";",
            dec   = ","
        )
    }

# End of the loop.
}

