# First generate a .cdsapirc file with the contents:
#
# url: https://cds-beta.climate.copernicus.eu/api
# key: <your-personal-access-token>
#
# and store in C:\Users\<YourUsername>
#
# Your API token can be obtained from your account on the Copernicus Climate Change Service website
# 1. Run download_era5_rainfall.py to download the data
# 2. Run convert_to_csv.py to convert the downloaded NetCDF file to CSV
# 3. Run aggregate_to_district.py to aggregate the data by district and save to CSV

import os
import subprocess
import sys

from matplotlib.colors import ListedColormap

# Function to check and install missing libraries
def install_libraries(libraries):
    for lib in libraries:
        try:
            __import__(lib)
        except ImportError:
            print(f"Library {lib} not found. Installing...")
            subprocess.check_call([sys.executable, "-m", "pip", "install", lib])

# List of required libraries
required_libraries = ['cdsapi', 'xarray', 'pandas', 'h5netcdf', 'openpyxl', 'geopandas', 'shapely', 'matplotlib']

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
        'reanalysis-era5-land',
        {
            'variable': 'total_precipitation',
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

def export_district_rainfall_to_csv(input_file, geojson_file, district_name, output_file):
    import xarray as xr
    import geopandas as gpd
    import pandas as pd

    print("Loading NetCDF data...")
    ds = xr.open_dataset(input_file)
    df = ds.to_dataframe().reset_index()

    print("Converting to GeoDataFrame...")
    gdf = gpd.GeoDataFrame(
        df,
        geometry=gpd.points_from_xy(df.longitude, df.latitude),
        crs="EPSG:4326"
    )

    print("Loading district boundaries...")
    districts = gpd.read_file(geojson_file)
    districts = districts[districts['name'] == district_name]

    if districts.empty:
        print(f"❌ District '{district_name}' not found.")
        return

    print(f"Filtering points within: {district_name}")
    gdf_clipped = gpd.sjoin(gdf, districts, how="inner", predicate="within")

    if gdf_clipped.empty:
        print("❌ No rainfall data points found within district.")
        return

    # Drop spatial join info and export
    gdf_clipped = gdf_clipped.drop(columns=['index_right', 'geometry'], errors='ignore')
    gdf_clipped.to_csv(output_file, index=False)
    print(f"✅ Exported rainfall data for '{district_name}' to {output_file}")

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

    output_png = input_file.replace(".nc", ".png") if output_file else "districts_rainfall_map.png"
    print("Loading Rainfall data...")
    ds = xr.open_dataset(input_file)
    tp = ds['tp']
    df = tp.to_dataframe().reset_index()
    print(f"Rainfall records loaded: {len(df)}")

    gdf = gpd.GeoDataFrame(
        df,
        geometry=gpd.points_from_xy(df.longitude, df.latitude),
        crs="EPSG:4326"
    )
    print(f"Rainfall GeoDataFrame created with {len(gdf)} points.")

    print("Loading district boundaries...")
    gdf_districts = gpd.read_file(map_geojson)
    print(f"Total features in map: {len(gdf_districts)}")

    # Lọc các quận có mã code bắt đầu bằng 'ASILAO'
    gdf_districts = gdf_districts[
        gdf_districts['code'].astype(str).str.startswith("ASILAO", na=False)
    ]
    # ✅ Remove features with invalid or missing geometry
    gdf_districts = gdf_districts[
        gdf_districts.geometry.notnull() &
        gdf_districts.is_valid &
        ~gdf_districts.is_empty
    ]

    gdf_districts = gdf_districts.to_crs("EPSG:4326")

    print("CRS of temp data:", gdf.crs)
    print("CRS of districts:", gdf_districts.crs)

    if gdf.empty:
        print("Rainfall GeoDataFrame is empty.")
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
        daily_sum = gdf_joined.groupby(['name', 'valid_time'])['tp'].mean().reset_index()

        # Convert valid_time to datetime and extract week number
        daily_sum['valid_time'] = pd.to_datetime(daily_sum['valid_time'])
        daily_sum['week'] = daily_sum['valid_time'].dt.isocalendar().week
        daily_sum['year'] = daily_sum['valid_time'].dt.isocalendar().year

        # Step 1: Compute weekly mean rainfall (averaged over all grid cells in a district)
        weekly_rainfall = daily_sum.groupby(['name', 'year', 'week'])['tp'].sum().reset_index()

        # Step 2: Convert to mm
        weekly_rainfall['tp'] = weekly_rainfall['tp'] * 1000  # meters → mm

        # Step 3: Get the mean of weekly means (final average weekly rainfall per district)
        district_avg_rainfall = weekly_rainfall.groupby('name')['tp'].mean().reset_index()

        print(f"✅ Districts with mean weekly rainfall: {len(district_avg_rainfall)}")
        districts_rainfall = gdf_districts.merge(district_avg_rainfall, on='name', how='left')

    print(f"Districts temp GeoDataFrame has {len(districts_rainfall)} rows")

    # Plot the data
    if not districts_rainfall.empty and 'tp' in districts_rainfall.columns:
        fig, ax = plt.subplots(figsize=(10, 10))
        districts_rainfall.plot(
            column='tp',
            cmap='coolwarm',
            legend=True,
            edgecolor='black',
            ax=ax,
            missing_kwds={"color": "lightgrey", "label": "No data"}
        )

        plt.title("Rainfall Category by District")
        plt.axis("off")

        # Save PNG
        plt.savefig(output_png, dpi=150)
        print(f"✅ PNG map saved to: {output_png}")
        plt.show()        
    else:
        print("No data available to plot.")

    # Export average Rainfall per district to CSV (filtered by code containing 'ASILAO')
    csv_output = output_file.replace(".geojson", ".csv") if output_file else "district_avg_rainfall_ASILAO.csv"
    export_columns = ['name', 'code', 'tp']

    if not districts_rainfall.empty:
        print(f"Exporting filtered average Rainfall per district to {csv_output}")
        districts_rainfall[export_columns].to_csv(csv_output, index=False)
    else:
        print("No districts match code filter 'ASILAO'. No CSV file exported.")

# Set file paths
download_file = "D:/ERA5/laos_rainfall_2021_2023.nc"
geojson_file = "D:/ERA5/Laos.geojson"
cleaned_rainfall_file = "D:/ERA5/laos_rainfall_2021_2023_districts.csv"

# Run the functions
#download_era5_land(download_file)
#print("Download completed.")

#convert_to_csv(download_file, "D:/ERA5/laos_rainfallerature_2021_2023.csv")
#print("Conversion to Excel completed.")

export_district_rainfall_to_csv(
    input_file=download_file,
    geojson_file=geojson_file,
    district_name="0905 Mok",
    output_file="D:/ERA5/rainfall_MOK.csv"
)

#aggregate_to_district(download_file, geojson_file, cleaned_rainfall_file)
#print("Aggregation to districts completed.")