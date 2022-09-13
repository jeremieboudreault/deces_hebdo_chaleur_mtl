# 07_compute_trends_and_om.R


# Step 7 : Compute trends in data and over-mortality (OM).


# Project : deces_hebdo_chaleur_mtl
# Author  : Jeremie Boudreault
# Email   : Prenom.Nom@inrs.ca
# Depends : R (v4.2.1)
# Imports : jtheme (https://github.com/jeremieboudreault/jtheme)
# License : CC BY-NC-ND 4.0


# Packages ---------------------------------------------------------------------


library(data.table)
library(ggplot2)
library(ggpubr)
library(jtheme)


# Imports ----------------------------------------------------------------------


data <- data.table::fread("data/weekly_death_weather.csv", dec = ",")


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


# Method 2) Continuous splines over the whole domain --------------------------


# Create sequential unique identifiers for each date.
data_wout_covid[, DATE_IDS := as.integer(as.factor(MID_DATE))]
data[, DATE_IDS := as.integer(as.factor(MID_DATE))]

# Fit a smoothing spline with ~3 degrees of freedom per year
fit <- lm(N_DEATH ~ splines::bs(DATE_IDS, df = 30), data = data_wout_covid, )
data_wout_covid$TREND_CSPLINE <- predict(fit)

# Need to retrieve the spline for the period 2020+.
data_wout_covid[WEEK == 53, WEEK := 52]
trend_spline <- data_wout_covid[, .(TREND_CSPLINE = mean(TREND_CSPLINE)), by = "WEEK"]
trend_spline <- rbind(
    trend_spline,
    data.table(
        WEEK               = 53,
        TREND_CSPLINE = trend_spline[WEEK == 52, TREND_CSPLINE]
    )
)
plot(trend_spline)

# Merge splines prior to Covid and after.
data_merged <- data.table::merge.data.table(
    x     = data[!(MID_DATE %in% data_wout_covid$MID_DATE), ],
    y     = trend_spline,
    by    = c("WEEK"),
    all.x = TRUE
)

# Merge the splines data.frame together.
data_spline <- rbind(
    data_merged[, .(DATE_IDS, TREND_CSPLINE, EXTRAPOLATED = "Extrapolated")],
    data_wout_covid[, .(DATE_IDS, TREND_CSPLINE, EXTRAPOLATED = "")]
)

# Bring splines.
data <- data.table::merge.data.table(
    x     = data,
    y     = data_spline,
    by    = "DATE_IDS",
    all.x = TRUE
)

# Plot resulting trend.
p2 <- ggplot(data, aes(y = N_DEATH, x = MID_DATE)) +
    geom_line() +
    geom_line(aes(x = MID_DATE, y = TREND_CSPLINE, col = EXTRAPOLATED), show.legend = FALSE) +
    ggtitle("b) Spline continue") +
    labs(y = "", x = "") +
    scale_color_manual(values = c(colors$blue, colors$red)) +
    jtheme(facets = TRUE)
p2


# Method 3) Unique spline over the whole domain --------------------------------


# Merge trend spline with data.
trend_spline <- trend_spline[, .(WEEK, TREND_USPLINE = TREND_CSPLINE)]

# Merge with data.
data <- data.table::merge.data.table(
    x     = data,
    y     = trend_spline,
    by    = "WEEK",
    all.x = TRUE
)

# Plot resulting trend.
p3 <- ggplot(data, aes(y = N_DEATH, x = MID_DATE)) +
    geom_line() +
    geom_line(aes(x = MID_DATE, y = TREND_USPLINE), col = colors$blue) +
    ggtitle("c) Spline unique") +
    labs(y = "Décès hebdomadaires", x = "Date") +
    jtheme(facets = TRUE)
p3


# Method 4) Polynomial over the weeks ------------------------------------------


# Fit polynomial regression over the weeks.
fit <- lm(N_DEATH ~ poly(WEEK, degree = 4), data = data_wout_covid)
trend_poly <- data.frame(WEEK = 1:53)
trend_poly$TREND_POLY <- predict(fit, newdata = trend_poly)
plot(trend_poly)

# Merge with data.
data <- data.table::merge.data.table(
    x     = data,
    y     = trend_poly,
    by    = "WEEK",
    all.x = TRUE
)

# Plot resulting trend.
p4 <- ggplot(data, aes(y = N_DEATH, x = MID_DATE)) +
    geom_line() +
    geom_line(aes(x = MID_DATE, y = TREND_POLY), col = colors$blue) +
    ggtitle("d) Fonction polynomiale unique") +
    labs(y = "", x = "Date") +
    jtheme(facets = TRUE)
p4


# Create plot of all methods ---------------------------------------------------


# Plot.
ggpubr::ggarrange(
    plotlist = list(p1, p2, p3, p4),
    ncol     = 2L,
    nrow     = 2L
)

# Save.
jtheme::save_ggplot("plots/supp/fig_s1_surmortalite_methodes.jpg", size= "rectbig")


# Compute over mortality -------------------------------------------------------


# Compute over mortality <OM>.
data[, OM_MONTH   := round(N_DEATH - TREND_MONTH,   1L)]
data[, OM_CSPLINE := round(N_DEATH - TREND_CSPLINE, 1L)]
data[, OM_USPLINE := round(N_DEATH - TREND_USPLINE, 1L)]
data[, OM_POLY    := round(N_DEATH - TREND_POLY,    1L)]

# Plot over-mortality.
ggplot(data, aes(x = MID_DATE)) +
    geom_line(aes(y = OM_MONTH,   col = "Mensuel"),           alpha = 0.7) +
    geom_line(aes(y = OM_CSPLINE, col = "Spline continue"),   alpha = 0.7) +
    geom_line(aes(y = OM_USPLINE, col = "Spline unique"),     alpha = 0.7) +
    geom_line(aes(y = OM_POLY,    col = "Polynomiale unique"), alpha = 0.7) +
    geom_hline(yintercept = 0, lty = 3, alpha = 0.5) +
    ggtitle("Surmortalité avec les 4 méthodes testées") +
    labs(y = "Surmortalité hebdomadaire", x = "Date") +
    jtheme(legend.title = FALSE)

# Save plot of over-mortality.
jtheme::save_ggplot("plots/fig_4_surmortalite_resultats.jpg")


# Export -----------------------------------------------------------------------


data.table::fwrite(data, "data/weekly_death_weather_om.csv", sep = ";", dec = ",")

