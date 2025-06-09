# First sign up for Google Earth Engine: https://earthengine.google.com/
# and register a Cloud Project. Ensure the Earth Engine API is enabled.
# See https://developers.google.com/earth-engine/cloud/earthengine_cloud_project_setup
# for more information.

import glob
import subprocess
import sys

from matplotlib import pyplot as plt
from matplotlib.colors import BoundaryNorm, ListedColormap

# Function to install missing libraries
def install_missing_libraries():
    required_libraries = ['earthengine-api', 'geemap', 'rasterio', 'ee', 'geopandas', 'rasterstats', 'pandas', 'matplotlib']
    for lib in required_libraries:
        try:
            __import__(lib)
        except ImportError:
            subprocess.check_call([sys.executable, "-m", "pip", "install", lib])

install_missing_libraries()

import ee
import geemap
import rasterio
from rasterio.merge import merge
import geopandas as gpd
import rasterio
import rasterstats
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import matplotlib.patches as mpatches

def download_esri_10m_annual_land_cover(file_des='D:/ERA5/Land-cover'):
    """
    Downloads the ESRI Global Land Cover dataset for 2023,
    splits it into 8x8 tiles, exports each tile to local drive,
    and merges them into a single raster file.
    """
    # Set the project ID (update to your project ID)
    project_id = 'arctic-sound-461005-t2'

    # Authenticate and initialize the Earth Engine module
    # A browser window will show up to ask to authenticate
    try:
        ee.Authenticate()
        ee.Initialize(project=project_id)
    except ee.EEException:
        subprocess.run(['earthengine', 'authenticate', '--project', project_id])
        ee.Initialize()

    # Define the bounding box coordinates.
    bbox = ee.Geometry.Rectangle([99.90503431410716, 13.735381723026942, 107.81472566670233, 14.674210553922226])

    # Use full-resolution static global dataset
    dataset = ee.ImageCollection('projects/sat-io/open-datasets/landcover/ESRI_Global-LULC_10m_TS') \
                .filterDate('2023-01-01', '2023-12-31') \
                .filterBounds(bbox) \
                .mosaic()
    
    # Function to split the bounding box into smaller tiles
    def split_bbox(bbox, n):
        coords = bbox.coordinates().get(0).getInfo()
        x_min, y_min = coords[0]
        x_max, y_max = coords[2]
        x_step = (x_max - x_min) / n
        y_step = (y_max - y_min) / n
        tiles = []
        for i in range(n):
            for j in range(n):
                tile = ee.Geometry.Rectangle([x_min + i * x_step, y_min + j * y_step, x_min + (i + 1) * x_step, y_min + (j + 1) * y_step])
                tiles.append(tile)
        return tiles

    # Split the bounding box into 8x8 tiles
    tiles = split_bbox(bbox, 32)

    # Export each tile to your local drive
    for idx, tile in enumerate(tiles):
        path = f'{file_des}/S2TSLULC_2023_tile_{idx}.tif'
        geemap.ee_export_image(dataset.clip(tile), filename=path, scale=10, region=tile)
          
    print("Export completed.")

def preview_merged_raster():
    """
    Preview the merged raster file.
    """

    import matplotlib.pyplot as plt
    # Load the merged raster file
    import rasterio
    output_path = 'D:/ERA5/Land-cover/S2TSLULC_2023_merged.tif'
    with rasterio.open(output_path) as src:
        print(src.profile)
        data = src.read(1)
        plt.imshow(data, cmap='viridis')
        plt.colorbar()
        plt.title('Merged ESRI Global Land Cover 2023')
        plt.show()

# Function to merge tiles
def merge_tiles(output_path):
    # Get list of all 63 tif files
    tif_files = sorted(glob.glob("D:/ERA5/Land-cover/*.tif"))
    
    src_files_to_mosaic = []
    for fp in tif_files:
        src = rasterio.open(fp)
        src_files_to_mosaic.append(src)
    mosaic, out_trans = merge(src_files_to_mosaic)
    out_meta = src.meta.copy()
    out_meta.update({
        "driver": "GTiff",
        "height": mosaic.shape[1],
        "width": mosaic.shape[2],
        "transform": out_trans,
        "compress": "lzw"  # ✅ Apply LZW compression
    })
    with rasterio.open(output_path, "w", **out_meta) as dest:
        dest.write(mosaic)
    
def generate_land_cover_preview(tif_path, scale_factor=10):
    """
    Downsample and render a land cover GeoTIFF as a PNG image.
    :param tif_path: path to the input .tif file
    :param output_png: path to the output .png image
    :param scale_factor: how much to downsample the image (e.g., 10 = 1/10 size)
    """
    output_png = tif_path.replace('.tif', '_preview.png')

    with rasterio.open(tif_path) as src:
        # Read first band
        band = src.read(1)
        
        # Downsample the raster
        band_small = band[::scale_factor, ::scale_factor]

        # Plot with categorical colormap (tab20 for up to 20 classes)
        plt.figure(figsize=(10, 10))
        plt.imshow(band_small, cmap='tab20')
        plt.axis("off")
        plt.title("Land Cover Preview (Downsampled)")
        plt.savefig(output_png, bbox_inches='tight', pad_inches=0, dpi=150)
        plt.close()

        print(f"🖼️ PNG saved to: {output_png}")

def aggregate_land_cover_to_districts(tif_path, district_geojson):
    """
    Aggregates land cover classification counts by district.
    """
    output_csv = tif_path.replace('.tif', '_landcover_by_district.csv')
    output_png = tif_path.replace('.tif', '_landcover_map.png')
    # Step 1: Load district boundaries
    gdf_districts = gpd.read_file(district_geojson)
    gdf_districts = gdf_districts[gdf_districts['code'].fillna('').str.startswith('ASILAO')]
    gdf_districts = gdf_districts.to_crs("EPSG:4326")

    # Step 2: Run zonal statistics (count of each land cover class in each polygon)
    print("Computing zonal histogram...")
    zs = rasterstats.zonal_stats(
        vectors=gdf_districts,
        raster=tif_path,
        stats=None,
        categorical=True,
        nodata=None
    )

    # Correct way to build results
    results = []
    for i, zone in enumerate(zs):
        row = {"district": gdf_districts.iloc[i]['name']}
        row.update(zone)
        results.append(row)

    df = pd.DataFrame(results)

    # Step 4: Save to CSV
    df.to_csv(output_csv, index=False)
    print(f"✅ Land cover aggregated and saved to {output_csv}")

    # Define class colors (1 to 11)
    # ESA WorldCover legend (class: label and color)
    esa_labels = {
        10: "Tree Cover",
        20: "Shrubland",
        30: "Grassland",
        40: "Cropland",
        50: "Built-up",
        60: "Bare/Sparse",
        70: "Snow/Ice",
        80: "Water",
        90: "Wetlands",
        95: "Mangroves",
        100: "Moss/Lichen"
    }

    esa_colors = {
        10: "#006400",
        20: "#FFBB22",
        30: "#FFFF4C",
        40: "#F096FF",
        50: "#FA0000",
        60: "#B4B4B4",
        70: "#F0F0F0",
        80: "#0064C8",
        90: "#0096A0",
        95: "#00CF75",
        100: "#FAE6A0"
    }
    
    # Step 5: Generate PNG preview
    print("🖼 Generating PNG preview...")
    with rasterio.open(tif_path) as src:
        band = src.read(1)
        present_classes = sorted(set(np.unique(band)) & esa_labels.keys())
        band_small = band[::10, ::10]  # downsample

    filtered_colors = [esa_colors[c] for c in present_classes]
    cmap = ListedColormap(filtered_colors)
    bounds = [c - 0.5 for c in present_classes] + [present_classes[-1] + 0.5]
    norm = BoundaryNorm(bounds, len(filtered_colors))

    plt.figure(figsize=(10, 10))
    plt.imshow(band_small, cmap=cmap, norm=norm)
    plt.axis("off")
    plt.title("Land Cover Map (ESA WorldCover)")

    patches = [mpatches.Patch(color=esa_colors[c], label=f"{c}: {esa_labels[c]}")
               for c in present_classes]
    plt.legend(handles=patches, bbox_to_anchor=(1.05, 1), loc="upper left", fontsize="small")

    plt.tight_layout()
    plt.savefig(output_png, dpi=150)
    plt.close()
    print(f"✅ PNG saved: {output_png}")

# Download the ESRI Global Land Cover dataset for 2023
file_des='D:/ERA5/Land-cover/ESRI'
download_esri_10m_annual_land_cover(file_des)

# Merge the tiles into a single raster
output_path = 'D:/ERA5/Land-cover/S2TSLULC_2023_merge.tif'
#merge_tiles(output_path)     

#generate_land_cover_preview(output_path)

#preview_merged_raster()
geojson_file = "D:/ERA5/Laos.geojson"
aggregate_land_cover_to_districts(tif_path=output_path, district_geojson=geojson_file)