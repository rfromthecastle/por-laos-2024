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
library(terra)
library(ggplot2)

# Function to display a specific band of the raster in RStudio with a custom title
display_raster <- function(raster_file) {
  DEM <- rast(raster_file)
  plot(DEM)
}

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

# Function to plot a shapefile in R
plot_shapefile <- function(shapefile, title) {
  polygons <- st_read(shapefile)  # Read the shapefile
  plot(st_geometry(polygons), main = title, col = 'lightblue', border = 'black')  # Plot the geometries
  print(paste("Shapefile plotted with title:", title))
}

# Set file paths
download_file <- "D:/ERA5/SRTM_DEM_2000_Laos.tif"
shapefile <- "D:/ERA5/hfca_only_public_072024.shp"
output_csv <- "D:/ERA5/alt_zonal_statistics.csv"

# Display DEM
display_raster(download_file)

# Plot the shapefile
plot_shapefile(shapefile, "Health Facility Catchment Areas")

calculate_zonal_statistics(download_file, shapefile, output_csv)

print("Process completed.")
