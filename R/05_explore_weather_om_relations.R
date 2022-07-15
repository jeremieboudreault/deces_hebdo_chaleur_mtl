# 05_explore_weather_om_relations.R


# Step 05 : Explore relations between OM and weather variables.


# Project : deces_isq_chaleur
# Author  : Jeremie Boudreault
# Email   : Jeremie.Boudreault [at] inrs [dot] ca
# Depends : R (v4.1.2)
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
        corr   = mcor,
        col    = COL2("RdBu", 200)[-(80:120)],
        method = "number",
        title  = title,
        type   = "lower",
        tl.pos = "lt",
        tl.col = "black",
        tl.cex = 0.7,
        tl.srt = 30,
        number.cex = 0.8,
        cl.pos = "n",
        mar    = if(is.na(title)) c(0, 0, 0.2, 0) else c(0, 0, 2, 0)
    )
    corrplot::corrplot(
        corr   = mcor,
        col    = COL2("RdBu", 200)[-(80:120)],
        method = "ellipse",
        type   = "upper",
        tl.col = "black",
        tl.pos = "n",
        add = TRUE
    )
}


# Imports ----------------------------------------------------------------------


data <- data.table::fread("data/weekly_death_weather_om.csv", dec = ",")


# Correlation analysis between temperature data and deaths ---------------------


# Initial analysis with all months.
mcor <- cor(data[, .(
    N_DEATH, OM_MONTH, OM_CSPLINE, OM_USPLINE, OM_POLY,
    TEMP_MIN_MIN, TEMP_MIN_MEAN, TEMP_MEAN_MIN, TEMP_MEAN_MEAN,
    TEMP_MEAN_MAX, TEMP_MAX_MEAN, TEMP_MAX_MAX
)])

# Plot and save correlation matrix.
pdf("plots/fig_7_1_cor_mat.pdf", width = 7, height = 5)
corrplot_full(mcor, "Matrice de corrélation (tous les mois)")
dev.off()

# Analysis with summer months only.
mcor_summer <- cor(data[WEEK > 16 & WEEK < 38, .(
    N_DEATH, OM_MONTH, OM_CSPLINE, OM_USPLINE, OM_POLY,
    TEMP_MIN_MIN, TEMP_MIN_MEAN, TEMP_MEAN_MIN,
    TEMP_MEAN_MEAN, TEMP_MEAN_MAX, TEMP_MAX_MEAN, TEMP_MAX_MAX
)])

# Plot and save correlation matrix.
pdf("plots/fig_7_2_cor_mat_ete.pdf", width = 7, height = 5)
corrplot_full(mcor_summer, "Matrice de corrélation (mai-septembre)")
dev.off()


# Generate a plot of the relation between temperature and mortality ------------


generate_plot <- function(
    plot_i       = 1L,
    week_start   = 1L,
    week_end     = 53L,
    year_start   = 2010,
    year_end     = 2019,
    temp_metric  = "TEMP_MEAN_MEAN",
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
        "Surmoralité"
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
    temp_name    <- if (temp_metric == "TEMP_MEAN_MEAN") {
        "Moyenne hebdomadaire des Tmoy"
    } else if (temp_metric == "TEMP_MAX_MEAN") {
        "Moyenne hebdomadaire des Tmax"
    }

    # Plot
    ggplot(data_sub, aes(x = TEMP_METRIC, y = DEATH_METRIC)) +
        geom_jitter(aes(color = TEMP_METRIC)) +
        geom_smooth(color = "black") +
        scale_color_distiller(palette = "YlOrRd", direction = 1, limits = c(-20, 35)) +
        ggtitle(paste(death_name, period_name2), paste0(period_name, " (", year_start, "-", year_end, ")")) +
        labs(
            y = death_name,
            x = ifelse(plot_i %in% c(3L, 4L), temp_name, "")
        ) +
        jtheme(legend.title = FALSE, facets = TRUE)

}

