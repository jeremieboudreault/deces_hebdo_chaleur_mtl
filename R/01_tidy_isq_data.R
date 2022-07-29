# 01_tidy_isq_data.R


# Step 01 : Tidy ISQ weekly death data into proper format.


# Project : deces_isq_chaleur
# Author  : Jeremie Boudreault
# Email   : Prenom.Nom@inrs.ca
# Depends : R (v4.2.1)
# Imports : jtheme (https://github.com/jeremieboudreault/jtheme)
# License : CC BY-NC-ND 4.0


# Packages ---------------------------------------------------------------------


library(data.table)
library(ggplot2)
library(jtheme)
library(openxlsx)


# Load CDC weeks ---------------------------------------------------------------


# Note : These are weeks that are commonly used in epidemiology. Each week
#        number can be related to a start, a middle and an end date.

# Load CDC weeks (custom file made in Excel).
cdc_weeks <- data.table::setDT(openxlsx::read.xlsx("data/cdc/cdc_weeks.xlsx"))

# Fix dates.
cdc_weeks[, START_DATE := as.Date(START_DATE, origin = "1899-12-30")]
cdc_weeks[, MID_DATE   := as.Date(MID_DATE,   origin = "1899-12-30")]
cdc_weeks[, END_DATE   := as.Date(END_DATE,   origin = "1899-12-30")]

# Look at final file.
cdc_weeks

# Export final file to .csv.
data.table::fwrite(cdc_weeks, "data/cdc/cdc_weeks.csv", sep = ";", dec = ",")


# Weekly deaths by age groups --------------------------------------------------


# File downloaded here : https://statistique.quebec.ca/fr/document/
#                        nombre-hebdomadaire-de-deces-au-quebec/tableau/
#                        deces-par-semaine-selon-le-groupe-dage-quebec

# Load deaths by age group.
wdeath_age_raw <- data.table::setDT(openxlsx::read.xlsx(
    xlsxFile = "data/isq/DecesSemaine_QC_GrAge.xlsx",
    startRow = 7L
))

# Update columns names.
colnames(wdeath_age_raw) <- c("YEAR", "FLAG", "AGE", 1:53)

# Melt the table.
wdeath_age <- data.table::melt.data.table(
    data            = wdeath_age_raw,
    id.vars         = c("YEAR", "FLAG", "AGE"),
    variable.name   = "WEEK",
    value.name      = "N_DEATH",
    variable.factor = FALSE
)

# Look at the available values.
table(wdeath_age$YEAR, useNA = "always")
table(wdeath_age$FLAG, useNA = "always") # d = definitive, p = preliminary
table(wdeath_age$AGE,  useNA = "always")
table(wdeath_age$WEEK, useNA = "always")

# Overwrite the age categories.
wdeath_age[, AGE := gsub(" ans", "", AGE)]
wdeath_age[, AGE := gsub(" et plus", "+", AGE)]
table(wdeath_age$AGE, useNA = "always")

# Convert <WEEK> to integer format.
wdeath_age[, WEEK := as.integer(as.character(WEEK))]
wdeath_age <- wdeath_age[!is.na(WEEK), ]

# Merge with dates.
wdeath_age <- data.table::merge.data.table(
    x = wdeath_age,
    y = cdc_weeks,
    by = c("YEAR", "WEEK"),
    all.x = TRUE
)

# Remove empty dates and deaths.
wdeath_age <- wdeath_age[!is.na(MID_DATE), ]
wdeath_age <- wdeath_age[!is.na(N_DEATH), ]

# Reorder columns.
wdeath_age <- wdeath_age[, .(YEAR, WEEK, START_DATE, MID_DATE, END_DATE,
                             AGE, N_DEATH, FLAG)]

# Plot the results prior to save.
ggplot(
    data    = wdeath_age[AGE != "Total", ],
    mapping = aes(x = MID_DATE, y = N_DEATH)
) +
geom_line(aes(color = AGE)) +
ggtitle("Décès hebdomadaires au Québec par groupe d'âge") +
labs(y = "Décès hebdomadaires", x = "Date") +
scale_x_date(expand = expansion(mult = c(0.01, 0.02))) +
guides(colour = guide_legend(nrow = 1)) +
jtheme(legend.title = FALSE)

# Save plots.
jtheme::save_ggplot("plots/fig_1_deces_par_age.jpg", size = "rect")

# Save dataset.
data.table::fwrite(
    x    = wdeath_age,
    file = "data/isq/wdeaths_age.csv",
    sep  = ";",
    dec  = ","
)


# Weekly deaths by regions -----------------------------------------------------


# File downloaded here : https://statistique.quebec.ca/fr/document/
#                        nombre-hebdomadaire-de-deces-au-quebec/tableau/
#                        deces-par-semaine-selon-le-regroupement-de-regions-quebec

# Load deaths by region.
wdeath_region_raw <- data.table::setDT(openxlsx::read.xlsx(
    xlsxFile = "data/isq/DecesSemaine_QC_Region.xlsx",
    startRow = 7L
))

# Update columns names.
colnames(wdeath_region_raw) <- c("YEAR", "FLAG", "REGION", 1:53)

# Melt the table.
wdeath_region <- data.table::melt.data.table(
    data            = wdeath_region_raw,
    id.vars         = c("YEAR", "FLAG", "REGION"),
    variable.name   = "WEEK",
    value.name      = "N_DEATH",
    variable.factor = FALSE
)

# Look at the available values.
table(wdeath_region$YEAR,   useNA = "always")
table(wdeath_region$FLAG,   useNA = "always") # d = definitive, p = preliminary
table(wdeath_region$REGION, useNA = "always")
table(wdeath_region$WEEK,   useNA = "always")

# Convert <WEEK> to integer format.
wdeath_region[, WEEK := as.integer(as.character(WEEK))]
wdeath_region <- wdeath_region[!is.na(WEEK), ]

# Merge with dates.
wdeath_region <- data.table::merge.data.table(
    x = wdeath_region,
    y = cdc_weeks,
    by = c("YEAR", "WEEK"),
    all.x = TRUE
)

# Remove empty dates and deaths.
wdeath_region <- wdeath_region[!is.na(MID_DATE), ]
wdeath_region <- wdeath_region[!is.na(N_DEATH), ]

# Reorder columns.
wdeath_region <- wdeath_region[, .(YEAR, WEEK, START_DATE, MID_DATE, END_DATE,
                             REGION, N_DEATH, FLAG)]

# Plot the results prior to save.
ggplot(
    data    = wdeath_region[REGION != "Total"],
    mapping = aes(x = MID_DATE, y = N_DEATH)
) +
geom_line(aes(color = REGION)) +
ggtitle("Décès hebdomadaires au Québec par région") +
labs(y = "Décès hebdomadaires", x = "Date") +
scale_x_date(expand = expansion(mult = c(0.01, 0.02))) +
guides(colour = guide_legend(nrow = 1)) +
jtheme(legend.title = FALSE)

# Save plots.
jtheme::save_ggplot("plots/fig_2_deces_par_region.jpg", size = "rect")

# Save dataset.
data.table::fwrite(
    x    = wdeath_region,
    file = "data/isq/wdeaths_region.csv",
    sep  = ";",
    dec  = ","
)


# Weekly deaths by sex ---------------------------------------------------------


# File downloaded here : https://statistique.quebec.ca/fr/document/
#                        nombre-hebdomadaire-de-deces-au-quebec/tableau/
#                        deces-par-semaine-selon-le-sexe-quebec

# Load deaths by sex.
wdeath_sex_raw <- data.table::setDT(openxlsx::read.xlsx(
    xlsxFile = "data/isq/DecesSemaine_QC_Sexe.xlsx",
    startRow = 7L
))

# Update columns names.
colnames(wdeath_sex_raw) <- c("YEAR", "FLAG", "SEX", 1:53)

# Melt the table.
wdeath_sex <- data.table::melt.data.table(
    data            = wdeath_sex_raw,
    id.vars         = c("YEAR", "FLAG", "SEX"),
    variable.name   = "WEEK",
    value.name      = "N_DEATH",
    variable.factor = FALSE
)

# Look at the available values.
table(wdeath_sex$YEAR, useNA = "always")
table(wdeath_sex$FLAG, useNA = "always") # d = definitive, p = preliminary
table(wdeath_sex$SEX,  useNA = "always")
table(wdeath_sex$WEEK, useNA = "always")

# Overwrite the sex categories.
wdeath_sex[, SEX := gsub("Femmes", "F", SEX)]
wdeath_sex[, SEX := gsub("Hommes", "H", SEX)]
table(wdeath_sex$SEX,  useNA = "always")

# Convert <WEEK> to integer format.
wdeath_sex[, WEEK := as.integer(as.character(WEEK))]
wdeath_sex <- wdeath_sex[!is.na(WEEK), ]

# Merge with dates.
wdeath_sex <- data.table::merge.data.table(
    x = wdeath_sex,
    y = cdc_weeks,
    by = c("YEAR", "WEEK"),
    all.x = TRUE
)

# Remove empty dates and deaths.
wdeath_sex <- wdeath_sex[!is.na(MID_DATE), ]
wdeath_sex <- wdeath_sex[!is.na(N_DEATH), ]

# Reorder columns.
wdeath_sex <- wdeath_sex[, .(YEAR, WEEK, START_DATE, MID_DATE, END_DATE,
                             SEX, N_DEATH, FLAG)]

# Plot the results prior to save.
ggplot(
    data    = wdeath_sex[SEX != "Total"],
    mapping = aes(x = MID_DATE, y = N_DEATH)
) +
geom_line(aes(color = SEX)) +
ggtitle("Décès hebdomadaires au Québec par sexe") +
labs(y = "Décès hebdomadaires", x = "Date") +
scale_x_date(expand = expansion(mult = c(0.01, 0.02))) +
guides(colour = guide_legend(nrow = 1)) +
jtheme(legend.title = FALSE)

# Save plots.
jtheme::save_ggplot("plots/fig_3_deces_par_sexe.jpg", size = "rect")

# Save dataset.
data.table::fwrite(
    x    = wdeath_sex,
    file = "data/isq/wdeaths_sex.csv",
    sep  = ";",
    dec  = ","
)
