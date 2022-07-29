# 04_process_eccc_data.R


# Step 04 : Process ECCC data in a clean format.


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


# Imports ----------------------------------------------------------------------


# Path to files.
files_path <- "data/eccc/raw/"

# List files.
files <- list.files(files_path)
length(files)

# Load all files in a list.
eccc_raw <- lapply(
    X    = file.path(files_path, files),
    FUN  = data.table::fread,
    sep  = ",",
    fill = TRUE
)

# Bind all files.
eccc_raw <- data.table::rbindlist(
    l         = eccc_raw,
    fill      = TRUE,
    use.names = TRUE
)


# Basic exploration ------------------------------------------------------------


# Number of row.
nrow(eccc_raw)

# Names of columns.
colnames(eccc_raw)

# Class of columns.
data.frame(sapply(eccc_raw, class))

# Percentage of missing per columns.
t(data.frame(lapply(eccc_raw, function(w) round(mean(is.na(w)), 2L))))

# First top 10 rows.
head(eccc_raw)

