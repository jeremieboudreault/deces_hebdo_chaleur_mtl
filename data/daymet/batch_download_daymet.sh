# Batch download script for DayMet database.
# Author : Jeremie Boudreault

# ------------------------------------------------------------------------------
# Parameters setup

# Year
startyear=1980  # First start year is 1980
endyear=2021 # Last end year is 2021

# Region
region="na" # North America = na, Hawaii = hi; Puerto Rico = pr

# Variable
var="tmax" # Available variables are : tmin, tmax, prcp, srad, vp, swe, dayl

# Output folder
outdir="/Volumes/ExtDataPhD/daymet/"

# ------------------------------------------------------------------------------
# Download

for ((year = startyear; year <= endyear; year++)); do
    echo "-------------------------------------------------------"
    echo "-------- Downloading ${var} for year ${year} in ${region}. --------"
    echo "-------------------------------------------------------"
    #wget "https://thredds.daac.ornl.gov/thredds/fileServer/ornldaac/1840/daymet_v4_daily_${region}_${var}_${year}.nc" -P $outdir
done;
