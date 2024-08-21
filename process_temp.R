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

# Function to download ERA5-Land data
download_era5_land <- function(output_file) {
  if (file.exists(output_file)) {
    print(paste(output_file, "already exists. Skipping download."))
    return()
  }
  
  url <- "https://cds.climate.copernicus.eu/api/v2"
  key <- Sys.getenv("COPERNICUS_API_KEY")
  
  request <- list(
    variable = "2m_temperature",
    year = "2023",
    month = sprintf("%02d", 1:12),
    day = sprintf("%02d", 1:31),
    time = "12:00",
    area = c(22.6742105539222258, 99.9050343141071551, 13.7353817230269417, 107.8147256667023299),
    format = "netcdf"
  )
  
  POST(
    url,
    authenticate(key, ""),
    body = list(request = request, format = "netcdf"),
    write_disk(output_file, overwrite = TRUE)
  )
  
  print(paste("Data downloaded to", output_file))
}

# Function to display a specific band of the raster in RStudio with a custom title
display_raster <- function(raster_file, band = 1, title) {
  r <- stack(raster_file)  # Use stack to handle multi-band raster
  plot(r[[band]], main = title)  # Plot the specified band
  print(paste("Raster band", band, "displayed with title:", title))
}

# Function to convert Kelvin to Celsius for a multi-band raster
convert_kelvin_to_celsius <- function(input_file, output_file) {
  if (file.exists(output_file)) {
    print(paste(output_file, "already exists. Skipping conversion."))
    return()
  }
  
  r <- stack(input_file)  # Use stack to handle multi-band raster
  r_celsius <- calc(r, fun = function(x) x - 273.15)
  writeRaster(r_celsius, output_file, format = "CDF", overwrite = TRUE)
  print(paste("Converted NetCDF file saved as", output_file))
}

# Function to calculate percentage of days with temperature between 20°C and 30°C for a multi-band raster
calculate_percentage_within_range <- function(input_file, output_file) {
  if (file.exists(output_file)) {
    print(paste(output_file, "already exists. Skipping calculation."))
    return()
  }
  
  r <- stack(input_file)  # Use stack to handle multi-band raster
  count_array <- calc(r, fun = function(x) sum(x >= 20 & x <= 30, na.rm = TRUE))
  
  total_days <- nlayers(r)
  percentage_array <- count_array / total_days * 100
  
  writeRaster(percentage_array, output_file, format = "GTiff", overwrite = TRUE)
  print(paste("Percentage raster saved as", output_file))
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
download_file <- "D:/ERA5/laos_temperature_2023.nc"
converted_file <- "D:/ERA5/laos_temperature_2023_celsius.nc"
percentage_raster_file <- "D:/ERA5/temperature_percentage_20_30.tif"
shapefile <- "D:/ERA5/hfca_only_public_072024.shp"
output_csv <- "D:/ERA5/temp_zonal_statistics.csv"

# Run the functions
download_era5_land(download_file)

# Display the Kelvin raster (first band)
display_raster(download_file, band = 1, title = "ERA5 Temperature (Kelvin) - Day 1, 2023")

convert_kelvin_to_celsius(download_file, converted_file)

# Display the Celsius raster (first band)
display_raster(converted_file, band = 1, title = "ERA5 Temperature (Celsius) - Day 1, 2023")

calculate_percentage_within_range(converted_file, percentage_raster_file)

# Display the percentage raster
display_raster(percentage_raster_file, band = 1, title = "% of days between 20°C - 30°C, 2023")

# Plot the shapefile
plot_shapefile(shapefile, "Health Facility Catchment Areas")

calculate_zonal_statistics(percentage_raster_file, shapefile, output_csv)

print("Process completed.")
