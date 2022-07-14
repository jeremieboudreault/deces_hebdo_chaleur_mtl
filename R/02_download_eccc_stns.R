# 02_download_eccc_stns_data.R


# Step 02 : Download ECCC stations data and merge them.


# Project : deces_isq_chaleur
# Author  : Jeremie Boudreault
# Email   : Jeremie.Boudreault [at] inrs [dot] ca
# Depends : R (v4.1.2)
# License : CC BY-NC-ND 4.0


# Packages ---------------------------------------------------------------------


library(data.table)
library(ggplot2)
library(jtheme)
library(sf)
library(weathercan)


# List of stations in Montreal -------------------------------------------------


# Cache list of stations as of 2022/06/29.
weathercan::stations_dl()
stns <- data.table::data.table(weathercan::stations())

# Download all Montreal stations with daily data.
mtl_stns <- data.table::data.table(weathercan::stations_search(name = "Montreal", interval = "day"))
mtl_stns <- mtl_stns[prov %in% "QC" & !is.na(lat), ]


# Map Montreal's stations ------------------------------------------------------


# Leaflet map.
leaflet::leaflet(
)  %>%
leaflet::addProviderTiles(
    provider = leaflet::providers$CartoDB.Voyager
) %>%
leaflet::addCircleMarkers(
    data        = mtl_stns,
    lng         = ~ lon,
    lat         = ~ lat,
    radius      = 4L,
    stroke      = TRUE,
    color       = "black",
    weight      = 1.2,
    opacity     = 0.8,
    fillColor   = "orange",
    fillOpacity = 1L,
    label       = ~ station_name,
)


# Compute distance between stations --------------------------------------------


# Convert stations data.table to a matrix.
mtl_stns_mat <- as.matrix(mtl_stns[, .(lon, lat)])
stns_id <- as.character(mtl_stns$station_id)
rownames(mtl_stns_mat) <- stns_id

# Calculate distance.
dist_mat <- fields::rdist.earth(
    x1     = mtl_stns_mat,
    miles  = FALSE
)

# Keep only the upper triangle.
dist_mat[upper.tri(dist_mat, diag = TRUE)] <- NA


# Clustering of stations based on distance -------------------------------------


# Create clustes of stations with < 1 km of distance.
create_stns_clusters <- function(dist_mat, dist_max = 0.01) {

    # Extract row and col names.
    rnames <- rownames(dist_mat)
    cnames <- colnames(dist_mat)

    # Check for identify.
    if (!all(rnames == cnames)) {
        stop("Row and col names differ. Please fix in dist_nat.")
    }

    # Extract pairs of stations cl
    ijs <- which(dist_mat < dist_max, arr.ind = TRUE)

    # Check for pairs of stations to merge.
    if (nrow(ijs) == 0L) {
        stop(sprintf("All stations are distant by more than %s km.\n ", dist_max),
             "> Increase 'dist_max' to create clusters of stations.")
    }

    # Create a matrix with the pairs of stations.
    mat_pairs <- cbind(rnames[ijs[, 1L]], rnames[ijs[, 2L]])

    # Create an empty cluster list.
    cluster_list <- list(0)
    cluster_i <- 1L

    # Iterate on all pair to create the cluster.
    for (i in seq_len(nrow(mat_pairs))) {

        # Check for stations already in cluster.
        in_cluster <- sapply(cluster_list, function(w) any(mat_pairs[i, ] %in% w))

        # If cluster already exists.
        if (any(in_cluster)) {

            cluster_list[[which(in_cluster)]] <- unique(c(
                cluster_list[[which(in_cluster)]], mat_pairs[i, ]
            ))

            # If a new cluster needs to be creater
        } else {

            cluster_list[[cluster_i]] <- mat_pairs[i, ]
            cluster_i <- cluster_i + 1L

        }

    }

    # Return the cluster list.
    return(cluster_list)

}

# Create stns_cluster.
stns_cluster <- create_stns_clusters(dist_mat, dist_max = 0.01)

# Data.table of cluster # and stations.
stns_cluster_dt <- data.table::data.table(
    cluster_id = rep(1:length(stns_cluster), times = lengths(stns_cluster)),
    station_id = unlist(stns_cluster)
)

# Merge clusters with meta informations.
mtl_stns[, station_id := as.character(station_id)]
stns_cluster <- mtl_stns[stns_cluster_dt, , on = "station_id"]

# Leaflet map.
leaflet::leaflet(
)  %>%
leaflet::addProviderTiles(
    provider = leaflet::providers$CartoDB.Voyager
) %>%
leaflet::addCircleMarkers(
    data        = stns_cluster,
    lng         = ~ lon,
    lat         = ~ lat,
    radius      = 4L,
    stroke      = TRUE,
    color       = "black",
    weight      = 1.2,
    opacity     = 0.8,
    fillColor   = ~ cluster_id,
    fillOpacity = 1L,
    label       = ~ station_name,
    #clusterOptions = leaflet::markerClusterOptions()
)


# Download data for the Monteal stations ---------------------------------------


# Download from ECCC.
weather_data_mtl <- weathercan::weather_dl(
    station_ids = mtl_stns$station_id,
    interval    = "day",
    start       = "1970-01-01"
)

# Convert to a data.table.
weather_data_mtl <- data.table::setDT(weather_data_mtl)

# Aggregate all stations.
weather_data_mtl_agg <- weather_data_mtl[, .(
    mean_temp = mean(mean_temp, na.rm = TRUE),
    max_temp = mean(max_temp, na.rm = TRUE),
    min_temp = mean(min_temp, na.rm = TRUE)
), by = c("date", "year", "month", "day")
]

# Plot temperature metrics.
ggplot(weather_data_mtl_agg[date > "2010-01-01"], mapping = aes(x = date)) +
geom_line(aes(y = max_temp, col = "Max"), lwd = 0.2) +
geom_line(aes(y = min_temp, col = "Min"), lwd = 0.2) +
geom_line(aes(y = mean_temp, col = "Moy"), lwd = 0.2) +
scale_x_date(expand = expansion(mult = c(0.01, 0.02))) +
scale_color_manual(values = c(colors$red, colors$blue, "black")) +
ggtitle("Températures à Montreal") +
labs(x = "Date", y = "Température (ºC)") +
jtheme(legend.title = FALSE)

# Save plot.
jtheme::save_ggplot("plots/fig_4_montreal_temp.jpg", size = "rect")


# Exports stns data ------------------------------------------------------------


qs::qsave(weather_data_mtl, "data/eccc/mtl_stns_data.qs")
qs::qsave(weather_data_mtl_agg, "data/eccc/mtl_stns_data_agg.qs")

