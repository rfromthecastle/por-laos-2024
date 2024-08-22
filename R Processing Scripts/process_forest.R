# Set your working directory to the Git repo
setwd("D:/Malaria/por-laos-2024")

# Load necessary libraries
required_packages <- c("exactextractr", "dplyr", "terra", "sf")
installed_packages <- rownames(installed.packages())

for (pkg in required_packages) {
  if (!pkg %in% installed_packages) {
    install.packages(pkg)
  }
}

library(exactextractr)
library(dplyr)
library(terra)
library(sf)

# Function to display a specific band of the raster in RStudio with a custom title
display_raster <- function(raster_file) {
  land_cover <- rast(raster_file)
  plot(land_cover)
}

# Function to calculate the percentage of forest cover (value 10) and save to CSV
calculate_forest_cover_percentage <- function(raster_file, shapefile, output_csv) {
  try({
    polygons <- st_read(shapefile)
    print(paste("Shapefile loaded successfully. Number of features:", nrow(polygons)))
    
    r <- rast(raster_file)
    if (st_crs(polygons)$epsg != crs(r, proj=TRUE)) {
      polygons <- st_transform(polygons, crs = crs(r, proj=TRUE))
      print("Shapefile reprojected to match the raster CRS.")
    }
    
    # Calculate the percentage of forest cover (raster value 10)
    stats <- exact_extract(r, polygons, function(values, coverage_fractions) {
      forest_fraction <- sum(coverage_fractions[values == 10], na.rm = TRUE)
      total_fraction <- sum(coverage_fractions, na.rm = TRUE)
      return(forest_fraction / total_fraction * 100)  # Percentage of forest cover
    })
    
    required_columns <- c('code', 'HF_DHIS2_U', 'HMIS_NameD', 'HF_T_ABBR1', 'hfghprovin', 'hfghprovi1', 'hfghdistri', 'hfghdistr1')
    if (!all(required_columns %in% colnames(polygons))) {
      stop("One or more required columns are missing in the shapefile.")
    }
    
    result <- cbind(st_drop_geometry(polygons)[required_columns], forest_cover_percentage = stats)
    
    write.csv(result, output_csv, row.names = FALSE)
    print(paste("Forest cover percentage saved to", output_csv))
    
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
land_cover_file <- "D:/ERA5/land_cover_2023_Laos.tif"
shapefile <- "D:/ERA5/hfca_only_public_072024.shp"
output_csv <- "D:/ERA5/forest_cover_percentage.csv"

# Display Land Cover Raster
display_raster(land_cover_file)

# Plot the shapefile
plot_shapefile(shapefile, "Health Facility Catchment Areas")

# Calculate and save forest cover percentage
calculate_forest_cover_percentage(land_cover_file, shapefile, output_csv)

print("Process completed.")
