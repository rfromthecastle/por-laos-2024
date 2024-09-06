# Set your working directory to the Git repo
setwd("D:/Malaria/por-laos-2024")

# Load necessary libraries
required_packages <- c("httr", "ncdf4", "raster", "sf", "exactextractr", "dplyr")
installed_packages <- rownames(installed.packages())

for (pkg in required_packages) {
  if (!pkg %in% installed_packages) {
    install.packages(pkg)
  }
}

library(httr)
library(ncdf4)
library(raster)
library(sf)
library(exactextractr)
library(dplyr)

# Function to display a specific band of the raster in RStudio with a custom title
display_raster <- function(raster_file, band = 1, title) {
  r <- stack(raster_file)  # Use stack to handle multi-band raster
  plot(r[[band]], main = title)  # Plot the specified band
  print(paste("Raster band", band, "displayed with title:", title))
}

# Set file path
download_file <- "D:/ERA5/laos_rainfall_2021_2023.nc"
polygons <- "D:/ERA5/hfca_only_public_072024.shp"
output_csv <- "D:/ERA5/median_weekly_rainfall_2021_2023.csv"

# Load the raster
r <- stack(download_file)

# Convert from meters to millimeters
r_mm <- r * 1000

# Display the converted raster (band 182)
display_raster(r_mm, band = 182, title = "ERA5 Rainfall (mm) - Day 182, 2021")

# Number of weeks in 2021-2023
num_weeks <- 52 * 3

# Initialize a list to store weekly rasters
weekly_rasters <- list()

# Aggregate data by week
for (week in 1:num_weeks) {
  start_day <- (week - 1) * 7 + 1
  end_day <- week * 7
  weekly_raster <- calc(r_mm[[start_day:end_day]], fun = sum, na.rm = TRUE)
  weekly_rasters[[week]] <- weekly_raster
}

# Calculate the median rainfall for each pixel across all weeks
median_raster <- calc(stack(weekly_rasters), fun = median, na.rm = TRUE)

# Save the median raster as a single-band raster
median_raster_file <- "D:/ERA5/laos_rainfall_median_2021_2023.tif"
writeRaster(median_raster, filename = median_raster_file, format = "GTiff", overwrite = TRUE)

# Display the median raster
display_raster(median_raster_file, band = 1, title = "Median Weekly Rainfall (mm) - 2023")

# Function to calculate zonal statistics and save to CSV
calculate_zonal_statistics <- function(raster_file, shapefile, output_csv) {
  try({
    polygons <- st_read(shapefile)
    print(paste("Shapefile loaded successfully. Number of features:", nrow(polygons)))
    
    r <- raster(raster_file)
    if (st_crs(polygons)$proj4string != projection(r)) {
      polygons <- st_transform(polygons, crs = projection(r))
      print("Shapefile reprojected to match the raster CRS.")
    }
    
    # Perform exact extraction using the summary function
    stats <- exact_extract(r, polygons, 'mean')
    
    required_columns <- c('code', 'HF_DHIS2_U', 'HMIS_NameD', 'HF_T_ABBR1', 'hfghprovin', 'hfghprovi1', 'hfghdistri', 'hfghdistr1')
    if (!all(required_columns %in% colnames(polygons))) {
      stop("One or more required columns are missing in the shapefile.")
    }
    
    result <- cbind(st_drop_geometry(polygons)[required_columns], stats)
    
    write.csv(result, output_csv, row.names = FALSE)
    print(paste("Zonal statistics saved to", output_csv))
    
    # View the CSV file in RStudio's viewer pane
    data <- read.csv(output_csv)
    View(data)
    
  }, silent = FALSE)
}

calculate_zonal_statistics(median_raster_file,polygons,output_csv)

print("Process completed.")
