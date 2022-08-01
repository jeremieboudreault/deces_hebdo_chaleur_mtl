# 03_download_eccc_data.R


# Step 03 : Download raw hourly data from ECCC given the station list.


# Project : deces_hebdo_chaleur_mtl
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


# List of stations.
stns_list <- data.table::fread("data/eccc/stns_mtl.csv", dec = ",")

# Keep stations that have data after 1979.
stns_list <- stns_list[`HLY Last Year` >= 1979L, ]


# Download data for the stations in Monteal/Laval ------------------------------


# Download from ECCC by looping on all stations.
for (stn_i in seq_len(nrow(stns_list))) {

    # Extract station id
    stn_id <- stns_list[stn_i, `Station ID`]

    # Extract start and end year.
    start <- max(stns_list[stn_i, `HLY First Year`], 1979L)
    end   <- stns_list[stn_i, `HLY Last Year`]

    # Loop on years.
    for (year in start:end) {

        # Loop on months.
        for (month in 1:12) {

            # Message.
            message(
                "Download hourly data for station ", stn_id, ", ",
                year, "/", month, "."
            )

            # Create URL.
            url <- paste0(
                "https://climate.weather.gc.ca/climate_data/bulk_data_e.html?",
                "format=csv&stationID=", stn_id, "&Year=", year, "&Month=", month,
                "&Day=14&timeframe=1&submit=%20Download+Data"
            )

            # Filename.
            filename <- paste0(stn_id, "_", year, "_", month, ".csv")

            # Download file.
            download.file(
                url      = url,
                destfile = file.path("data", "eccc", "raw", filename),
                quiet    = TRUE
            )

        # End of loop for month.
        }

    # End of loop for year.
    }

    # Sleep time to avoid breaking connection by asking to much data.
    Sys.sleep(30L)

# End of loop for stations
}

