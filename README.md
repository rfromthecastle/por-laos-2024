# Scripts for the 2024 Laos malaria prevention of re-establishment stratification

## Prerequisites
The following datasets need to be pre-downloaded and prepared for the geographic extent of Laos.

- Airport locations in shapefile format
- Health facility catchment areas in shapefile format (download from GeoPrism Registry (http://laogpr.moh.gov.la/#/registry/master-lists?typeCode=HF) and generate Voronoi polygons in QGIS)
- International border checkpoints in shapefile format
- Railway stations in shapefile format
- Shuttle Radar Topography Mission Digital Elevation Model in GeoTIFF format (download from NASA EarthData and stitch together in QGIS)

## Datasets
| Variable | Data source | Dataset | File format | Frequency / Currency | Resolution |  Preparation |
| ------------- | ------------- | ------------- | ------------- | ------------- | ------------- | ------------- |
| Altitude | NASA | [Shuttle Radar Topography Mission](https://www.earthdata.nasa.gov/sensors/srtm) | GeoTIFF | Latest available (2000) | 1 arcsec (~ 30 m) | Download tiles from NASA EarthData and merge into a single raster in QGIS |
| Distance to airport | Google | Google Maps | Derived from shapefile (points) | Latest available (2024) | N/A | Digitize point shapefile and classify according to domestic / international |
| Distance to international border checkpoints | Google | Google Maps | Derived from shapefile (points) | Latest available (2024) | N/A | Digitize point shapefile |
| Distance to railway stations | Google | Google Maps | Derived from shapefile (points) | Latest available (2024) | N/A | Digitize point shapefile |
| Forest cover | Esri | [Esri 10 m Annual Land Cover (Google Earth Engine)](https://gee-community-catalog.org/projects/S2TSLULC/) | GeoTIFF | Annual for 2021-2023 | 10 m | Run [download_esri_10_m_annual_land_cover.py](https://github.com/rfromthecastle/por-laos-2024/blob/master/Python%20Download%20Scripts/download_esri_10m_annual_land_cover.py) |
| Malaria cases | Lao Ministry of Health | [Lao Health Management Information System](https://hmis.gov.la/) (DHIS2 line list) | CSV | Annual for 2023 | N/A | Export from DHIS2 |
| Permanent water bodies | Esri | [Esri 10 m Annual Land Cover (Google Earth Engine)](https://gee-community-catalog.org/projects/S2TSLULC/) | GeoTIFF | Annual for 2021-2023 | 10 m | Run [download_esri_10_m_annual_land_cover.py](https://github.com/rfromthecastle/por-laos-2024/blob/master/Python%20Download%20Scripts/download_esri_10m_annual_land_cover.py) |
| Seasonal water bodies | Copernicus Land Monitoring Service | [Water Bodies 2020-present (raster 100 m), global, monthly - version 1](https://land.copernicus.eu/en/products/water-bodies/water-bodies-global-v1-0-100m) | NetCDF | Annual for 2021-2023 | 100 m | Run [Copernicus_data_download.ipynb](https://github.com/rfromthecastle/por-laos-2024/blob/master/Python%20Download%20Scripts/Copernicus_data_download.ipynb) |
| Rainfall | Copernicus Climate Data Store | [ERA5 Hourly Data on Pressure Levels](https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-pressure-levels) | NetCDF | Monthly for 2021-2023 | 0.1° (= 9 km) | Run [download_era5_rain.py](https://github.com/rfromthecastle/por-laos-2024/blob/master/Python%20Download%20Scripts/download_era5_rain.py) |
| Relative humidity | Copernicus Climate Data Store | [ERA5-Land Hourly Data](https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-land) | NetCDF | Monthly for 2021-2023 | 0.1° (= 9 km) | Run [download_era5_hum.py](https://github.com/rfromthecastle/por-laos-2024/blob/master/Python%20Download%20Scripts/download_era5_hum.py) |
| Temperature | Copernicus Climate Data Store | [ERA5-Land Hourly Data](https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-land) | NetCDF | Monthly for 2021-2023 | 0.1° (= 9 km) | Run [download_era5_temp.py](https://github.com/rfromthecastle/por-laos-2024/blob/master/Python%20Download%20Scripts/download_era5_temp.py) |

## Authors
Scripts developed by the Clinton Health Access Initiative:
- Hannah Brindle, PhD (Phnom Penh, Cambodia)
- Jessica Floyd, PhD (London, UK)
- Lorenzo Arena ([@lorearena](https://github.com/lorearena)) (Vientiane, Laos)
- Rica Zamora Duchateau ([@rfromthecastle](https://github.com/rfromthecastle)) (Vientiane, Laos)
- Valérian Turbé, PhD ([@Valerian8](https://github.com/Valerian8)) (London, UK)

Includes code from:
- ChatGPT
- Elijah Filip - Clinton Health Access Initiative (Dakar, Senegal)
- Wu, Qiusheng. 2023. _Earth Engine and Geemap - Geospatial Data Science with Python_
