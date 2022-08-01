# 07_explore_weather_mortality_relations.R


# Step 07 : Explore relations between OM and weather variables.


# Project : deces_hebdo_chaleur_mtl
# Author  : Jeremie Boudreault
# Email   : Prenom.Nom@inrs.ca
# Depends : R (v4.2.1)
# Imports : jtheme (https://github.com/jeremieboudreault/jtheme)
# License : CC BY-NC-ND 4.0


# Packages ---------------------------------------------------------------------


library(corrplot)
library(data.table)
library(ggplot2)
library(ggpubr)
library(jtheme)


# Function ---------------------------------------------------------------------


corrplot_full <- function(mcor, title = NA) {
    corrplot::corrplot(
        corr     = mcor,
        col      = rev(COL2("RdBu", 200)[-(80:120)]),
        method   = "number",
        title    = title,
        type     = "lower",
        tl.pos   = "lt",
        tl.col   = "black",
        tl.cex   = 0.7,
        tl.srt   = 30,
        number.cex = 0.8,
        cl.pos   = "n",
        mar      = if(is.na(title)) c(0, 0, 0.2, 0) else c(0, 0, 2, 0),
        na.label = "NA"
    )
    corrplot::corrplot(
        corr     = mcor,
        col      = rev(COL2("RdBu", 200)[-(80:120)]),
        method   = "ellipse",
        type     = "upper",
        tl.col   = "black",
        tl.pos   = "n",
        add      = TRUE,
        na.label = "NA"

    )
}


# Imports ----------------------------------------------------------------------


data <- data.table::fread("data/weekly_death_weather_om.csv", dec = ",")


# Correlation analysis between temperature data and deaths ---------------------


# Initial analysis with all months.
mcor <- cor(data[, .(
    N_DEATH, OM_MONTH,
    T_MIN_WMEAN, T_MEAN_WMEAN, T_MAX_WMEAN,
    HMDX_MIN_WMEAN, HMDX_MEAN_WMEAN, HMDX_MAX_WMEAN,
    TDEW_MEAN_WMEAN, WDCHL_MEAN_WMEAN, RELH_MEAN_WMEAN,
    PRES_MEAN_WMEAN, WDSPD_MEAN_WMEAN, PRCIP_SUM_WSUM, VISB_MEAN_WMEAN
)], use = "pairwise.complete.obs")

# Plot and save correlation matrix.
pdf("plots/supp/fig_s2_1_cor_mat.pdf", width = 10, height = 8)
corrplot_full(mcor, "Matrice de corrélation (tous les mois)")
dev.off()

# Analysis with summer months only.
mcor_summer <- cor(data[WEEK > 16 & WEEK < 38, .(
    N_DEATH, OM_MONTH,
    T_MIN_WMEAN, T_MEAN_WMEAN, T_MAX_WMEAN,
    HMDX_MIN_WMEAN, HMDX_MEAN_WMEAN, HMDX_MAX_WMEAN,
    TDEW_MEAN_WMEAN, RELH_MEAN_WMEAN,
    PRES_MEAN_WMEAN, WDSPD_MEAN_WMEAN, PRCIP_SUM_WSUM, VISB_MEAN_WMEAN
)], use = "pairwise.complete.obs")

# Plot and save correlation matrix.
pdf("plots/supp/fig_s2_2_cor_mat_ete.pdf", width = 10, height = 8)
corrplot_full(mcor_summer, "Matrice de corrélation (mai-septembre)")
dev.off()


# Overview of the overmortality 2010-2022 --------------------------------------


# Extract top-30 week with over-mortality.
data_om_top30 <- head(data[order(OM_MONTH, decreasing = TRUE), ], 30L)

# Palette.
pal <- rev(RColorBrewer::brewer.pal(9L, "RdBu")[c(1:3, 7:9)])

# Plot.
ggplot(data, aes(x = MID_DATE, y = OM_MONTH)) +
    geom_line(aes(col = T_MEAN_WMEAN)) +
    geom_point(data = data_om_top30, pch = 1, alpha = 0.8) +
    geom_hline(yintercept = 0, lty = 3, alpha = 0.8) +
    scale_color_gradientn(colors = pal, guide = guide_colourbar(
        barwidth = 10, barheight = 1, ticks = FALSE)
    ) +
    ggtitle("Surmortalités importantes à Montréal et températures observées") +
    labs(y = "Surmortalité hebdomadaire", x = "Date",
         color = "Températures moyennes hebdomadaires :") +
    jtheme()

# Save.
jtheme::save_ggplot("plots/fig_5_surmortalites_montreal_temperatures.jpg", "rect")


# Generate a plot of the relation between temperature and mortality ------------


generate_plot <- function(
    plot_i       = 1L,
    week_start   = 1L,
    week_end     = 53L,
    year_start   = 2010,
    year_end     = 2019,
    temp_metric  = "T_MEAN_WMEAN",
    death_metric = "N_DEATH"
){

    # Subset data.
    data_sub <- data[YEAR >= year_start &
                     YEAR <= year_end   &
                     WEEK >= week_start &
                     WEEK <= week_end, ]
    data_sub$TEMP_METRIC  <- data_sub[[temp_metric]]
    data_sub$DEATH_METRIC <- data_sub[[death_metric]]

    # Name of the death variable.
    death_name   <- if (death_metric == "N_DEATH") {
        "Mortalité"
    } else {
        "Surmortalité"
    }

    # Period name.
    period_name  <- if (week_start == 1L) {
        "Janvier à décembre"
    } else {
        "Mai à septembre"
    }

    # Period name 2.
    period_name2 <- if (week_start == 1L) {
        "annuelle"
    } else {
        "estivale"
    }

    # Temperature
    temp_name    <- if (temp_metric == "T_MEAN_WMEAN") {
        "Moyenne hebdomadaire des Tmoy"
    } else if (temp_metric == "T_MAX_WMEAN") {
        "Moyenne hebdomadaire des Tmax"
    }

    # Plot
    ggplot(data_sub, aes(x = TEMP_METRIC, y = DEATH_METRIC)) +
        geom_jitter(aes(color = TEMP_METRIC)) +
        geom_smooth(color = "black") +
        scale_color_distiller(palette = "YlOrRd", direction = 1, limits = c(-21, 35)) +
        ggtitle(paste(death_name, period_name2), paste0(period_name, " (", year_start, "-", year_end, ")")) +
        labs(
            y = death_name,
            x = ifelse(plot_i %in% c(3L, 4L), temp_name, "")
        ) +
        jtheme(legend.title = FALSE, facets = TRUE)

}


# Figure 1 - Non linear relation between mean temperature and mortality --------


# Annual mortality.
p1 <- generate_plot(1L,
    year_end     = 2022,
    death_metric = "N_DEATH"
)

# Annual over-mortality.
p2 <- generate_plot(2L,
    year_end     = 2022,
    death_metric = "OM_MONTH"
)

# Summer mortality.
p3 <- generate_plot(3L,
    year_end      = 2022,
    week_start    = 16L,
    week_end      = 38L
)

# Summer over-mortality.
p4 <- generate_plot(4L,
    year_end     = 2022,
    death_metric = "OM_MONTH",
    week_start   = 16L,
    week_end     = 38L
)

# Plot.
ggpubr::ggarrange(
    plotlist = list(p1, p2, p3, p4),
    nrow     = 2L,
    ncol     = 2L,
    legend   = "none"
)

# Export.
jtheme::save_ggplot("plots/fig_6_1_relations_tmoy.jpg", "sqrbig")


# Figure 2 : Pre-covid relation between mean temperature and mortality ---------


# Annual mortality.
p1 <- generate_plot(1L,
    year_end     = 2019,
    death_metric = "N_DEATH"
)

# Annual over-mortality.
p2 <- generate_plot(2L,
    year_end     = 2019,
    death_metric = "OM_MONTH"
)

# Summer mortality.
p3 <- generate_plot(3L,
    year_end      = 2019,
    week_start    = 16L,
    week_end      = 38L,
    death_metric = "N_DEATH"
)

# Summer over-mortality.
p4 <- generate_plot(4L,
    year_end     = 2019,
    week_start   = 16L,
    week_end     = 38L,
    death_metric = "OM_MONTH"
)

# Plot.
ggpubr::ggarrange(
    plotlist = list(p1, p2, p3, p4),
    nrow     = 2L,
    ncol     = 2L,
    legend   = "none"
)

# Export.
jtheme::save_ggplot("plots/fig_6_2_relations_tmoy_precovid.jpg", "sqrbig")


# Figure 3 : Non linear relation between max temperature and mortality ---------


# Annual mortality.
p1 <- generate_plot(1L,
    year_end     = 2019,
    death_metric = "N_DEATH",
    temp_metric  = "T_MAX_WMEAN"
)

# Annual over-mortality.
p2 <- generate_plot(2L,
    year_end     = 2019,
    death_metric = "OM_MONTH",
    temp_metric  = "T_MAX_WMEAN"
)

# Summer mortality.
p3 <- generate_plot(3L,
    year_end      = 2019,
    week_start    = 16L,
    week_end      = 38L,
    death_metric = "N_DEATH",
    temp_metric  = "T_MAX_WMEAN"
)

# Summer over-mortality.
p4 <- generate_plot(4L,
    year_end     = 2019,
    week_start   = 16L,
    week_end     = 38L,
    death_metric = "OM_MONTH",
    temp_metric  = "T_MAX_WMEAN"
)

# Plot.
ggpubr::ggarrange(
    plotlist = list(p1, p2, p3, p4),
    nrow     = 2L,
    ncol     = 2L,
    legend   = "none"
)

# Export.
jtheme::save_ggplot("plots/fig_6_3_relations_tmax_precovid.jpg", "sqrbig")

