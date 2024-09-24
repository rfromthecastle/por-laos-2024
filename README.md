# Scripts for the 2024 Laos malaria prevention of re-establishment stratification

## Prerequisites
The following datasets need to be pre-downloaded and prepared for the geographic extent of Laos.

- Airport locations in shapefile format
- Health facility catchment areas in shapefile format (download from GeoPrism Registry (http://laogpr.moh.gov.la/#/registry/master-lists?typeCode=HF) and generate Voronoi polygons in QGIS)
- International border checkpoints in shapefile format
- Railway stations in shapefile format
- Shuttle Radar Topography Mission Digital Elevation Model in GeoTIFF format (download from NASA EarthData and stitch together in QGIS)

## Datasets
| Variable | Data source | Dataset | Frequency / Currency | Resolution |
| ------------- | ------------- | ------------- | ------------- | ------------- |
| Altitude | NASA | [Shuttle Radar Topography Mission](https://www.earthdata.nasa.gov/sensors/srtm) | Latest available (2000) | 1 arcsec (~ 30 m) |
| Distance to airport | Google | Google Maps | Latest available (2024) | N/A |
| Distance to international border checkpoints | Google | Google Maps | Latest available (2024) | N/A |
| Distance to railway stations | Google | Google Maps | Latest available (2024) | N/A |
| Forest cover | Esri | [Esri 10 m Annual Land Cover (Google Earth Engine)](https://gee-community-catalog.org/projects/S2TSLULC/) | Annual for 2021-2023 | 10 m |
| Malaria cases | Lao Ministry of Health | [Lao Health Management Information System](https://hmis.gov.la/) (DHIS2 line list) | Annual for 2023 | N/A |
| Permanent water bodies | Esri | [Esri 10 m Annual Land Cover (Google Earth Engine)](https://gee-community-catalog.org/projects/S2TSLULC/) | Annual for 2021-2023 | 10 m |
| Seasonal water bodies | Copernicus Land Monitoring Service | [Water Bodies 2020-present (raster 100 m), global, monthly - version 1](https://land.copernicus.eu/en/products/water-bodies/water-bodies-global-v1-0-100m) | Annual for 2021-2023 | 100 m |
| Rainfall | Copernicus Climate Data Store | [ERA5 Hourly Data on Pressure Levels](https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-pressure-levels) | Monthly for 2021-2023 | 0.1° (= 9 km) |
| Relative humidity | Copernicus Climate Data Store | [ERA5-Land Hourly Data](https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-land) | Monthly for 2021-2023 | 0.1° (= 9 km) |
| Temperature | Copernicus Climate Data Store | [ERA5-Land Hourly Data](https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-land) | Monthly for 2021-2023 | 0.1° (= 9 km) |

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
