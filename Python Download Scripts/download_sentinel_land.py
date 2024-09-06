# First sign up for Google Earth Engine: https://earthengine.google.com/
# and register a Cloud Project. Ensure the Earth Engine API is enabled.
# See https://developers.google.com/earth-engine/cloud/earthengine_cloud_project_setup
# for more information.

import subprocess
import sys
import ee
import geemap
import rasterio
from rasterio.merge import merge

# Function to install missing libraries
def install_missing_libraries():
    required_libraries = ['earthengine-api', 'geemap', 'rasterio']
    for lib in required_libraries:
        try:
            __import__(lib)
        except ImportError:
            subprocess.check_call([sys.executable, "-m", "pip", "install", lib])

install_missing_libraries()

# Set the project ID (update to your project ID)
project_id = 'ee-por-laos-2024'

# Authenticate and initialize the Earth Engine module
# A browser window will show up to ask to authenticate
try:
    ee.Initialize(project=project_id)
except ee.EEException:
    subprocess.run(['earthengine', 'authenticate', '--project', project_id])
    ee.Initialize()

# Define the bounding box coordinates.
bbox = ee.Geometry.Rectangle([99.90503431410716, 13.735381723026942, 107.81472566670233, 22.674210553922226])

# Load the S2TSLULC dataset for the year 2023.
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
tiles = split_bbox(bbox, 8)

# Export each tile to your local drive
tile_paths = []
for idx, tile in enumerate(tiles):
    path = f'D:/S2TSLULC_2023_tile_{idx}.tif'
    geemap.ee_export_image(dataset.clip(tile), filename=path, scale=30, region=tile)
    tile_paths.append(path)

# Function to merge tiles
def merge_tiles(tile_paths, output_path):
    src_files_to_mosaic = []
    for fp in tile_paths:
        src = rasterio.open(fp)
        src_files_to_mosaic.append(src)
    mosaic, out_trans = merge(src_files_to_mosaic)
    out_meta = src.meta.copy()
    out_meta.update({
        "driver": "GTiff",
        "height": mosaic.shape[1],
        "width": mosaic.shape[2],
        "transform": out_trans
    })
    with rasterio.open(output_path, "w", **out_meta) as dest:
        dest.write(mosaic)

# Merge the tiles into a single raster
output_path = 'D:/S2TSLULC_2023_merged.tif'
merge_tiles(tile_paths, output_path)

print("Export and merge completed.")