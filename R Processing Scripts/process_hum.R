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

# Function to plot a shapefile in R
plot_shapefile <- function(shapefile, title) {
  polygons <- st_read(shapefile)  # Read the shapefile
  plot(st_geometry(polygons), main = title, col = 'lightblue', border = 'black')  # Plot the geometries
  print(paste("Shapefile plotted with title:", title))
}

# Function to calculate the percentage of days with RH between 70% and 100%
calculate_percentage_rh_range <- function(rh_file, output_file) {
  if (file.exists(output_file)) {
    print(paste(output_file, "already exists. Skipping calculation."))
    return()
  }
  
  rh_raster <- brick(rh_file)
  
  # Calculate the percentage of days with RH >= 70% and <= 100%
  count_rh_in_range <- calc(rh_raster, fun = function(x) sum(x >= 70 & x <= 100, na.rm = TRUE))
  total_days <- nlayers(rh_raster)
  percentage_rh_in_range <- count_rh_in_range / total_days * 100
  
  # Save the result as a single-band raster
  writeRaster(percentage_rh_in_range, output_file, format = "GTiff", overwrite = TRUE)
  print(paste("Percentage of days with RH between 70% and 100% saved as", output_file))
}

# Function to calculate zonal statistics for the percentage raster
calculate_zonal_statistics_percentage <- function(raster_file, shapefile, output_csv) {
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

# Set file paths
rh_file <- "D:/ERA5/laos_relhum_2021_2023.nc"
percentage_rh_file <- "D:/ERA5/percentage_rh_70_100_2023.tif"
shapefile <- "D:/ERA5/hfca_only_public_072024.shp"
output_csv <- "D:/ERA5/percentage_rh_zonal_statistics.csv"

# Step 1: Calculate the percentage of days with RH between 70% and 100%
calculate_percentage_rh_range(rh_file, percentage_rh_file)

# Display the Percentage RH raster
display_raster(percentage_rh_file, band = 1, title = "Percentage of Days with RH 70%-100%, 2023")

# Step 2: Calculate zonal statistics based on the percentage raster
calculate_zonal_statistics_percentage(percentage_rh_file, shapefile, output_csv)

print("Process completed.")
