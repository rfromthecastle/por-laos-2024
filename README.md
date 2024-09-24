# Scripts for the 2024 Laos malaria prevention of re-establishment stratification

## Prerequisites
All ERA5 datasets are downloaded from the Copernicus Climate Data Service using Python scripts (see Python download scripts folder), while other variables and spatial units need to be pre-downloaded and prepared.

- Health facility catchment areas in shapefile format (download from GeoPrism Registry (http://laogpr.moh.gov.la/#/registry/master-lists?typeCode=HF) and generate Voronoi polygons in QGIS)
- Shuttle Radar Topography Mission Digital Elevation Model in GeoTIFF format (download from NASA EarthData and stitch together in QGIS)

The R scripts handle the processing of each variable.

## Authors
Scripts developed by the Clinton Health Access Initiative:
- Hannah Brindle (Phnom Penh, Cambodia)
- Jessica Floyd (London, UK)
- Lorenzo Arena (Vientiane, Laos)
- Rica Zamora Duchateau (Vientiane, Laos)
- Valérian Turbé (London, UK)

Includes code from:
- ChatGPT
- Elijah Filip - Clinton Health Access Initiative (Dakar, Senegal)
- Wu, Qiusheng. 2023. _Earth Engine and Geemap - Geospatial Data Science with Python_
