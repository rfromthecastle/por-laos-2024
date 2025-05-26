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
required_libraries = ['cdsapi', 'xarray', 'pandas','netcdf4', 'h5netcdf', 'openpyxl', 'geopandas', 'shapely', 'matplotlib']

# Check and install libraries
install_libraries(required_libraries)

import cdsapi
import xarray as xr
import pandas as pd
import pandas as pd
import geopandas as gpd
from shapely.geometry import Point
import matplotlib.pyplot as plt

# Function to download ERA5-Land data
def download_era5_land(output_file):
    if os.path.exists(output_file):
        print(f"{output_file} already exists. Skipping download.")
        return
    
    c = cdsapi.Client()
    c.retrieve(
        'reanalysis-era5-single-levels',
        {
            'product_type': 'reanalysis',
            'variable': '2m_temperature',
            'year': ['2021','2022','2023'],
            'month': [
                '01', '02', '03', '04', '05', '06',
                '07', '08', '09', '10', '11', '12',
            ],
            'day': [
                '01', '02', '03', '04', '05', '06',
                '07', '08', '09', '10', '11', '12',
                '13', '14', '15', '16', '17', '18',
                '19', '20', '21', '22', '23', '24',
                '25', '26', '27', '28', '29', '30',
                '31',
            ],
            'time': '12:00',
            'data_format': 'netcdf',
            'download_format': 'unarchived',
            'area': [22.6742105539222258, 99.9050343141071551, 13.7353817230269417, 107.8147256667023299]
        },
        output_file
    )
    print(f"Data downloaded to {output_file}")

def convert_to_csv(input_file, output_file):
    import xarray as xr
    import pandas as pd

    # Load the NetCDF file
    ds = xr.open_dataset(input_file)

    # Convert to DataFrame
    df = ds.to_dataframe().reset_index()

    # Save to Excel
    df.to_csv(output_file, index=False)
    print(f"Data converted to {output_file}")

def aggregate_to_monthly(input_file, output_file):
    # Load the NetCDF file
    ds = xr.open_dataset(input_file)

    # Resample to monthly data
    monthly_data = ds.resample(time='1M').mean()

    # Convert to DataFrame
    df = monthly_data.to_dataframe().reset_index()

    # Save to Excel
    df.to_csv(output_file, index=False)
    print(f"Monthly data saved to {output_file}")

def aggregate_to_district(input_file, map_geojson, output_file=None):
    import xarray as xr
    import geopandas as gpd
    import pandas as pd
    import matplotlib.pyplot as plt

    print("Loading temperature data...")
    ds = xr.open_dataset(input_file)
    t2m = ds['t2m']
    df = t2m.to_dataframe().reset_index()
    print(f"Temperature records loaded: {len(df)}")

    gdf = gpd.GeoDataFrame(
        df,
        geometry=gpd.points_from_xy(df.longitude, df.latitude),
        crs="EPSG:4326"
    )
    print(f"Temperature GeoDataFrame created with {len(gdf)} points.")

    print("Loading district boundaries...")
    gdf_districts = gpd.read_file(map_geojson)
    print(f"Total features in map: {len(gdf_districts)}")

    if 'level' in gdf_districts.columns:
        gdf_districts = gdf_districts[gdf_districts['level'] == '3']
        print(f"Filtered to level 3 districts: {len(gdf_districts)}")
    else:
        print("Column 'level' not found. Using all features.")

    gdf_districts = gdf_districts.to_crs("EPSG:4326")

    print("CRS of temp data:", gdf.crs)
    print("CRS of districts:", gdf_districts.crs)

    if gdf.empty:
        print("Temperature GeoDataFrame is empty.")
        gdf_joined = pd.DataFrame()
    else:
        print("Performing spatial join with original districts...")
        joined_direct = gpd.sjoin(gdf, gdf_districts, how="inner", predicate="within")
        print(f"Directly joined points: {len(joined_direct)}")

        # Identify districts with no direct data
        districts_with_data = joined_direct['name'].unique()
        districts_without_data = gdf_districts[~gdf_districts['name'].isin(districts_with_data)]

        print(f"Districts without direct data: {len(districts_without_data)}")

        # Buffer only these districts by ~5km (~0.045 deg)
        buffered = districts_without_data.copy()
        buffered['geometry'] = buffered.geometry.buffer(0.07)

        print("Performing spatial join for buffered districts...")
        joined_buffered = gpd.sjoin(gdf, buffered, how="inner", predicate="within")
        print(f"Joined points from buffered districts: {len(joined_buffered)}")

        # Combine both joins
        gdf_joined = pd.concat([joined_direct, joined_buffered], ignore_index=True)

    if not gdf_joined.empty:
        district_avg_temp = gdf_joined.groupby('name')['t2m'].mean().reset_index()
        print(f"Districts with average temp: {len(district_avg_temp)}")
        districts_temp = gdf_districts.merge(district_avg_temp, on='name', how='left')
    else:
        print("No temperature points joined with districts. Creating empty temp column.")
        districts_temp = gdf_districts.copy()
        districts_temp['t2m'] = None

    print(f"Districts temp GeoDataFrame has {len(districts_temp)} rows")

    # Clean geometries
    districts_temp = districts_temp[districts_temp.geometry.notnull()]
    districts_temp = districts_temp[districts_temp.is_valid]
    districts_temp = districts_temp[~districts_temp.is_empty]
    print(f"After cleaning, {len(districts_temp)} geometries remain")

    # Plot the data
    if not districts_temp.empty and 't2m' in districts_temp.columns:
        fig, ax = plt.subplots(figsize=(10, 10))
        districts_temp.plot(
            column='t2m',
            cmap='coolwarm',
            legend=True,
            edgecolor='black',
            ax=ax,
            missing_kwds={"color": "lightgrey", "label": "No data"}
        )
        gdf_joined.plot(ax=ax, color='black', markersize=5, alpha=0.5, label="Temp Points")
        plt.title("Average 2m Temperature by District with Nearby Data Points")
        plt.axis("off")
        plt.legend()
        plt.show()
    else:
        print("No data available to plot.")

    # Export average temperature per district to CSV (filtered by code containing 'ASILAO')
    csv_output = output_file.replace(".geojson", ".csv") if output_file else "district_avg_temp_ASILAO.csv"
    export_columns = ['name', 't2m', 't2m_celsius']

    # Use 'code' if present, or try 'id'
    if 'code' in districts_temp.columns:
        districts_temp_filtered = districts_temp[districts_temp['code'].astype(str).str.startswith("ASILAO")]
        districts_temp_filtered['t2m_celsius'] = districts_temp_filtered['t2m'] - 273.15
        export_columns.insert(0, 'code')
    elif 'id' in districts_temp.columns:
        districts_temp.rename(columns={'id': 'code'}, inplace=True)
        districts_temp_filtered = districts_temp[districts_temp['code'].astype(str).str.startswith("ASILAO")]
        districts_temp_filtered['t2m_celsius'] = districts_temp_filtered['t2m'] - 273.15
        export_columns.insert(0, 'code')
    else:
        print("No 'code' or 'id' column found. Skipping CSV export.")
        districts_temp_filtered = pd.DataFrame()

    if not districts_temp_filtered.empty:
        print(f"Exporting filtered average temperature per district to {csv_output}")
        districts_temp_filtered[export_columns].to_csv(csv_output, index=False)
    else:
        print("No districts match code filter 'ASILAO'. No CSV file exported.")

# Set file paths
download_file = "D:/ERA5/laos_temperature_2021_2023.nc"

# Run the functions
#download_era5_land(download_file)
#print("Download completed.")

#convert_to_csv(download_file, "D:/ERA5/laos_temperature_2021_2023.csv")
#print("Conversion to Excel completed.")
geojson_file = "D:/ERA5/Laos.geojson"
cleaned_temp_flie = "D:/ERA5/laos_temperature_2021_2023_districts.csv"
aggregate_to_district(download_file, geojson_file, cleaned_temp_flie)
#print("Aggregation to districts completed.")