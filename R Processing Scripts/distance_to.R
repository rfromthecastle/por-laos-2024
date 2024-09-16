# Set working directory to Box
setwd("C:/Users/jfloyd/Box/POR 2024/")

# Load necessary libraries
library(sf)
library(tidyverse)

# Set file paths
border_crossings <- st_read("International borders/laos_border_crossing_points.shp")
airports = st_read("Airports/Laos Airport Point/Laos Airport Point_2024.shp")
railways = st_read("Railway stations/Laos Railway Station Point_2024.shp")
hfs <- st_read("Health facilities/HFML - For POR - 072024.shp")

cambodia_crossings = border_crossings %>% 
  filter(country == "Cambodia")

distances_border = st_distance(hfs,cambodia_crossings)
distances_airports = apply(st_distance(hfs,airports),1,min)
distances_railways = apply(st_distance(hfs,railways),1,min)

hfs %>%
  select("code","HF_DHIS2_U","HMIS_NameD","HF_T_ABBR1","hfghprovin","hfghprovi1","hfghdistri","hfghdistr1") %>% 
  mutate(dist_to_cam = as.numeric(distances_border/1000),
         dist_to_cam_score = case_when(dist_to_cam >= 50 ~ 1,
                                       dist_to_cam >= 20 & dist_to_cam <50 ~ 2,
                                       dist_to_cam < 20 ~ 4),
         dist_to_air = as.numeric(distances_airports/1000),
         dist_to_air_score = case_when(dist_to_air >= 50 ~ 1,
                                       dist_to_air >= 20 & dist_to_air <50 ~ 2,
                                       dist_to_air < 20 ~ 4),
         dist_to_rail = as.numeric(distances_railways/1000),
         dist_to_rail_score = case_when(dist_to_rail >= 50 ~ 1,
                                        dist_to_rail >= 20 & dist_to_rail <50 ~ 2,
                                        dist_to_rail < 20 ~ 4)) %>% 
  st_drop_geometry() %>% 
  write_csv("International borders/distance_to_border_air_rail.csv")
  

