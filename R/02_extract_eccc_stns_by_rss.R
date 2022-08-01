# 02_extract_eccc_stns_by_rss.R


# Step 02 : Extract a list of stations from ECCC in a given RSS.


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
library(sf)


# Imports ----------------------------------------------------------------------


# RSS (Regions Socio-Sanitaires).
rss <- sf::read_sf("data/rss/Territoires_RSS_2022.shp")

# Download stations from ECCC.
download.file(
    url      = "https://drive.google.com/uc?export=download&id=1HDRnj41YBWpMioLPwAFiLlK4SK8NV72C",
    destfile = "data/eccc/stns.csv"
)

# Load stations.
stns <- data.table::fread("data/eccc/stns.csv")

# Update some names.
data.table::setnames(stns,
    old = c("Latitude (Decimal Degrees)", "Longitude (Decimal Degrees)"),
    new = c("lat", "lon")
)


# ECCC weather stations --------------------------------------------------------


# Keep only stations in QC, with hourly data and valid long/lat.
stns <- stns[
    Province  == "QUEBEC"         &
    !is.na(lat)                   &
    !is.na(lon)                   &
    !is.na(`HLY First Year`)      &
    !is.na(`HLY Last Year`)
]


# Leaflet map of all stations with hourly data ---------------------------------


leaflet::leaflet(
) |>
leaflet::addProviderTiles(
    provider = leaflet::providers$CartoDB.Voyager
) |>
leaflet::addCircleMarkers(
    data        = stns,
    lng         = ~ lon,
    lat         = ~ lat,
    radius      = 4L,
    stroke      = TRUE,
    color       = "black",
    weight      = 1.2,
    opacity     = 0.8,
    fillColor   = "orange",
    fillOpacity = 1L,
    label       = ~ Name,
    clusterOptions = leaflet::markerClusterOptions()
)


# Keep only stations in RSS of Montreal and Laval ------------------------------


# Convert stns to sf and transform to CRS of RSS.
stns_sf <- sf::st_as_sf(
    x      = stns,
    coords = c("lon", "lat"),
    crs    = 4326L
) |>
st_transform(crs = sf::st_crs(rss))

# Plot results.
plot(stns_sf[1L])

# Score stations in RSS.
inter <- st_intersects(stns_sf, rss)

# Set NAs to stations with no RSS.
inter[lengths(inter) == 0L] <- NA

# Add RSS_CODE in Stations.
stns$RSS_CODE <- rss$RSS_code[unlist(inter)]
stns_sf$RSS_CODE <- rss$RSS_code[unlist(inter)]

# Keep stations that do not have a NA.
stns <- stns[!is.na(RSS_CODE), ]
stns_sf <- stns_sf[!is.na(stns_sf$RSS_CODE), ]
nrow(stns) == nrow(stns_sf)

# Plot final list of stations by RSS.
plot(stns_sf["RSS_CODE"])

# Keep only stations in Montreal and Laval.
stns_mtl <- stns[RSS_CODE %in% c("06", "13"), ]
stns_sf_mtl <- stns_sf[stns_sf$RSS_CODE %in% c("06", "13"), ]
nrow(stns_mtl) == nrow(stns_sf_mtl)


# Plot -------------------------------------------------------------------------


# Plot final list of stations in Montreal and Laval.
ggplot() +
geom_sf(
    data  = rss[rss$RSS_code %in% c("06", "13"), ],
    fill  = rgb(0, 0, 0, 0.1),
    color = "grey30"
) +
geom_sf(
    data        = stns_sf_mtl,
    mapping     = aes(color = RSS_CODE),
    show.legend = FALSE
) +
ggtitle("Stations météorologiques de ECCC à Montréal et Laval") +
labs(x = NULL, y = NULL) +
scale_color_manual(values = ul(colors[c("red", "blue")])) +
jtheme(show.grid = TRUE, facets = TRUE)

# Export plots.
jtheme::save_ggplot("plots/fig_2_carte_stations.jpg", size = "rect")


# Exports ----------------------------------------------------------------------


# Stations list.
data.table::fwrite(
    x    = stns_mtl,
    file = "data/eccc/stns_mtl.csv",
    dec  = ",",
    sep  = ";"
)


