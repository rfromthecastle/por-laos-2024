# First generate a .cdsapirc file with the contents:
#
# url: https://cds-beta.climate.copernicus.eu/api
# key: <your-personal-access-token>
#
# and store in C:\Users\<YourUsername>
#
# Your API token can be obtained from your account on the Copernicus Climate Change Service website

import os
import subprocess
import sys

# Function to check and install missing libraries
def install_libraries(libraries):
    for lib in libraries:
        try:
            __import__(lib)
        except ImportError:
            print(f"Library {lib} not found. Installing...")
            subprocess.check_call([sys.executable, "-m", "pip", "install", lib])

# List of required libraries
required_libraries = ['cdsapi']

# Check and install libraries
install_libraries(required_libraries)

import cdsapi

# Function to download ERA5 data
def download_era5_land(output_file):
    if os.path.exists(output_file):
        print(f"{output_file} already exists. Skipping download.")
        return
    
    c = cdsapi.Client()
    c.retrieve(
        'reanalysis-era5-pressure-levels',
        {
            'product_type': ['reanalysis'],
            'variable': ['relative_humidity'],
            'year': ['2021', '2022', '2023'],
            'month': ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'],
            'day': ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31'],
            'time': ['12:00'],
            'pressure_level': ['1000'],
            'data_format': 'netcdf',
            'download_format': 'unarchived',
            'area': [22.674210553922226, 99.90503431410716, 13.735381723026942, 107.81472566670233]
        },
        output_file
    )
    print(f"Data downloaded to {output_file}")

# Set file paths
download_file = "D:/ERA5/laos_relhum_2023.nc"

# Run the functions
download_era5_land(download_file)

print("Download completed.")
