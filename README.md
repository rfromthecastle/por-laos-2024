# Scripts for the 2024 Laos malaria prevention of re-establishment stratification

## Prerequisites
All ERA5 datasets are downloaded from the Copernicus Climate Data Service using Python scripts (see Python download scripts folder), while other variables and spatial units need to be pre-downloaded and prepared.

- Health facility catchment areas in shapefile format (download from GeoPrism Registry (http://laogpr.moh.gov.la/#/registry/master-lists?typeCode=HF) and generate Voronoi polygons in QGIS)
- Shuttle Radar Topography Mission Digital Elevation Model in GeoTIFF format (download from NASA EarthData and stitch together in QGIS)
- ESA WorldCover 2021 in GeoTIFF format (download from website and stitch together in QGIS)

The R scripts handle the processing of each variable.

## Authors
Scripts developed by:
- ChatGPT
- Rica Zamora Duchateau (Clinton Health Access Initiative)
- Valérian Turbé (Clinton Health Access Initiative)
- Jessica Floyd (Clinton Health Access Initiative)
- Hannah Brindle (Clinton Health Access Initiative)
- Lorenzo Arena (Clinton Health Access Initiative)
