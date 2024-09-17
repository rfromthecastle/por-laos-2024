rm(list=ls())

### Packages ### ----------------------------------------------------------------

pacman::p_load(
  "conflicted",
  "tidyverse",
  "sf",
  "httr",
  "janitor",
)

conflict_prefer("select", "dplyr")  # Will prefer dplyr::select over any other package
conflict_prefer("filter", "dplyr")  # Will prefer dplyr::filter over any other package
options(digits=1)                   # Will use until the first decimal

### Functions ### ----------------------------------------------------------------

# # Function to download and translate the org units into R
getOrgUnitsByLevel <- function(user, pass, level){
  
  # Create the URL for all org units
  ouLvl <- if(is.numeric(level)) paste0('&level=', level) else ''
  allOuUrl = paste0('https://hmis.gov.la/hmis/api/29/organisationUnits.csv?paging=FALSE', ouLvl)
  
  # Get a CSV and turn it into a dataframe
  allOus <- GET(
    allOuUrl,
    authenticate(
      user,
      pass,
      type = 'basic'
    )
  ) %>%
    content(type = 'text') %>%
    read_csv()
  
  # Create the URL
  locationUrl = paste0('https://hmis.gov.la/hmis/api/29/organisationUnits.geojson?level=', level)
  
  # Get the GeoJSON and convert it to a SF object
  locations <- GET(
    locationUrl,
    authenticate(
      user,
      pass,
      type = 'basic'
    )
  ) %>%
    content(type = 'text') %>%
    st_read(quiet = T)
  
  # Join the geometry to the locations
  joined <- allOus %>%
    rename(c(name = displayName)) %>%
    left_join(
      locations %>%
        dplyr::select(-c(name, groups)),
      by = 'id'
    ) %>%
    st_as_sf()
  
  # Return the result
  return(joined)
}

# # Function to assign the level3 to level 4 to the AH and PH
impute_orgunit <- function(level4, level3){
  
  #Associate org unit that have level 4 to level 3
  level4up <- ifelse(is.na(level4), level3, level4)
  level3 <- ifelse(is.na(level4), NA, level3)
  
  return(list(level4up,level3))
}


### # # Function to merge all the function to create dataset

MyMerge <- function(x, y){
  df <- merge(x, y, by= "orgunitlevel4", all.x= TRUE, all.y= TRUE)
  return(df)
}


### Import datasets ### --------------------------------------------------------

### Master list data 
#this datasets provides information of the district where the health centers comes from, including AH and PH
HFML <- readxl::read_excel("data-raw/HF-2024-07-28.xlsx") %>% 
  clean_names() %>% 
  #Generate a variable with the District Code and District name
  mutate(orgunitlevel3 = paste(health_facility_geographic_hierarchy_district_moh_data_prop_code,
                               health_facility_geographic_hierarchy_district_moh_english)) %>%
  mutate(orgunitlevel3 = ifelse(orgunitlevel3 =="NA NA", 
                                NA, 
                                gsub("^.{0,2}", "", orgunitlevel3)))

# Get the org units from DHIS
username <- ""
password <- ""

# Get the provinces
lao_province <- getOrgUnitsByLevel(
  user = username, 
  pass = password,
  level = 2
) %>% 
  filter(str_starts(name, '[0-9][0-9] ')) %>% 
  st_as_sf()

# Get the districts
lao_district <- getOrgUnitsByLevel(
  user = username, 
  pass = password,
  level = 3
) %>%
  filter(str_starts(name, '[0-9][0-9][0-9][0-9] ') & str_starts(code, 'ASILA')) %>% 
  st_as_sf()

# Get the health centers
lao_HF <- getOrgUnitsByLevel(
  user = username, 
  pass = password,
  level = 4
) %>%
  # filter(str_starts(name, 'HC ')) %>% 
  st_as_sf()

villages <- getOrgUnitsByLevel(
  user = username,
  pass = password,
  level = 5
) %>% 
  st_as_sf()


#Aggregated data on P.f., P.v., mixed from 2018 onwards aggregated at health facility level as reporting unit
url.aggr<-"https://hmis.gov.la/hmis/api/analytics.csv?dimension=dx%3AmB9KbAM6KdF%3BxVD0aXeXr5w%3BvBo33ws9HnC%3BZwvHOvOKbuJ&dimension=pe%3A2018%3B2019%3B2020%3B2021%3B2022%3B2023%3B2024&dimension=ou%3AOU_GROUP-i25KIs0mtvz%3BIWp9dQGM0bS&tableLayout=true&rows=ou&columns=dx%3Bpe&skipRounding=false&completedOnly=false&showHierarchy=true"

aggr.cases <- GET(
  url.aggr,
  authenticate(
    username,
    password,
    type = "basic"
  ))%>% 
  content(., "text") %>% 
  read_csv() %>% 
  clean_names()

# #Aggregated data at village level as reporting unit to associate each org unit ID to the right level
urlvillage <- "https://hmis.gov.la/hmis/api/analytics.csv?dimension=dx%3AMIOL3mDFJZf&dimension=ou%3AOU_GROUP-i25KIs0mtvz%3BLEVEL-lg6NTeX70iX%3BLEVEL-d4UXL51EVXm%3BIWp9dQGM0bS&tableLayout=true&rows=ou&columns=dx&skipRounding=false&completedOnly=false&showHierarchy=true&filter=pe%3A2023"
level5.test <- GET(
  urlvillage,
  authenticate(
    username,
    password,
    type = "basic"
  ))%>%
  content(., "text") %>%
  read_csv() %>%
  clean_names()

#Cicc data from 2022,2023, ongoing by Using API to extract from recent DHIS2 server:
url.cicc <- "https://hmis.gov.la/hmis/api/29/analytics/enrollments/query/yAKTrPUMAuU.csv?dimension=pe:2022;2023;THIS_YEAR&dimension=ou:IWp9dQGM0bS;OU_GROUP-xcrI8OQASVf&dimension=sYIPnUlgN5p&dimension=ICzb0sNZZNQ&dimension=h86ikuTvjuP.qf5LcIDIXSJ&dimension=RhcGAjyYJMH&dimension=ZehVNXWsgbs&dimension=uBtUfbHMjK1&dimension=HnqSqtoERYm&dimension=IVANnvGgSDY&dimension=Tz0gwnPTKsa.ESfDoUGZYUX&dimension=Tz0gwnPTKsa.GNLu0b4Dfk6&dimension=Tz0gwnPTKsa.nOZrreWIzBz&dimension=Tz0gwnPTKsa.yk6kSyuQoKb&dimension=Tz0gwnPTKsa.fKUM5jMBOWZ&dimension=lW4E4Tyu2D9&stage=Tz0gwnPTKsa&displayProperty=NAME&totalPages=false&tableLayout=true&dataIdScheme=NAME&columns=pe;ou;sYIPnUlgN5p;ICzb0sNZZNQ;qf5LcIDIXSJ;RhcGAjyYJMH;ZehVNXWsgbs;uBtUfbHMjK1;HnqSqtoERYm;IVANnvGgSDY;ESfDoUGZYUX;GNLu0b4Dfk6;nOZrreWIzBz;yk6kSyuQoKb;fKUM5jMBOWZ;lW4E4Tyu2D9&rows=pe;ou;sYIPnUlgN5p;ICzb0sNZZNQ;qf5LcIDIXSJ;RhcGAjyYJMH;ZehVNXWsgbs;uBtUfbHMjK1;HnqSqtoERYm;IVANnvGgSDY;ESfDoUGZYUX;GNLu0b4Dfk6;nOZrreWIzBz;yk6kSyuQoKb;fKUM5jMBOWZ;lW4E4Tyu2D9&paging=false"

cicc.recent <- GET(
  url.cicc,
  authenticate(
    username,
    password,
    type = "basic"
  ))%>% 
  content(., "text") %>% 
  read_csv() %>% 
  clean_names() %>% 
  rename(organisationunitid = organisation_unit,
         enrollment_date=enrollment_date_ວ_ນທ_ຂອງການບ_ງມະຕ) %>% 
  #remove unnecessary columns
  select(-incident_date_ວ_ນທ_ປ_ອນຂ_ມ_ນ_ອ_ດຕະໂນມ_ດ,
         -stored_by, 
         -created_by,
         -last_updated_by, 
         -last_updated_on,
         -program_status) 


#CC data from 2021 - using old CMPE datasets: https://laos-his.gov.la/dhis/dhis-web-dashboard/#/
username <- ""
password <- ""
url.cicc2021 <- "https://laos-his.gov.la/dhis/api/29/analytics/enrollments/query/yAKTrPUMAuU.csv?dimension=pe:2021&dimension=ou:IWp9dQGM0bS&dimension=bxSvU1LK2Sn&dimension=JYpq5unNinA&dimension=rreM2sBjjoT&dimension=Tz0gwnPTKsa.qf5LcIDIXSJ&dimension=RhcGAjyYJMH&dimension=ZehVNXWsgbs&dimension=HnqSqtoERYm&dimension=uBtUfbHMjK1&dimension=IVANnvGgSDY&dimension=Tz0gwnPTKsa.ESfDoUGZYUX&dimension=Tz0gwnPTKsa.GNLu0b4Dfk6&dimension=Tz0gwnPTKsa.nOZrreWIzBz&dimension=Tz0gwnPTKsa.yk6kSyuQoKb&dimension=Tz0gwnPTKsa.IrgkSo2s7QF&dimension=Tz0gwnPTKsa.fKUM5jMBOWZ&dimension=Tz0gwnPTKsa.nj23llL870V&stage=Tz0gwnPTKsa&displayProperty=NAME&tableLayout=true&dataIdScheme=NAME&columns=pe;ou;bxSvU1LK2Sn;JYpq5unNinA;rreM2sBjjoT;qf5LcIDIXSJ;RhcGAjyYJMH;ZehVNXWsgbs;HnqSqtoERYm;uBtUfbHMjK1;IVANnvGgSDY;ESfDoUGZYUX;GNLu0b4Dfk6;nOZrreWIzBz;yk6kSyuQoKb;IrgkSo2s7QF;fKUM5jMBOWZ;nj23llL870V&rows=pe;ou;bxSvU1LK2Sn;JYpq5unNinA;rreM2sBjjoT;qf5LcIDIXSJ;RhcGAjyYJMH;ZehVNXWsgbs;HnqSqtoERYm;uBtUfbHMjK1;IVANnvGgSDY;ESfDoUGZYUX;GNLu0b4Dfk6;nOZrreWIzBz;yk6kSyuQoKb;IrgkSo2s7QF;fKUM5jMBOWZ;nj23llL870V&paging=false"
cicc.2021 <- GET(
  url.cicc2021,
  authenticate(
    username,
    password,
    type = "basic"
  ))%>%
  content(., "text") %>%
  read_csv() %>%
  clean_names() %>% 
  select(-incident_date_ວ_ນທ_ສະແດງອາການ) %>% 
  rename(organisationunitid = organisation_unit,
         enrollment_date=enrollment_date_ວ_ນທ_ຂອງການບ_ງມະຕ,
         current_district_hierarchy = current_district,
         current_province_hierarchy = current_province,
         current_village_hierarchy = current_village) #rename the HF organisation_unit ID to match with the new DHIS2 system and allow to merge

### Create Unique dataset ### ---------------------------------------------------------------

### Create a unique dataset with all Case Classification data included in the aggregated cases by Year by Health Facility, with all the reporting health facilities (AH, IH, CH, PH, HC, Malaria Station) as level 4 instead of level 3

# 1) Merge CICC 2021 and CICC Recente data
cicc.complete <- bind_rows(cicc.2021, cicc.recent)

# 2) Include the right district and province code for each health centers using ID from test aggregated data downloaded by level 5
cicc.complete <- merge(cicc.complete,
                       level5.test[, c("organisationunitid",
                                       "orgunitlevel2", 
                                       "orgunitlevel3", 
                                       "orgunitlevel4", 
                                       "orgunitlevel5")],
                       by = "organisationunitid",
                       all.x = TRUE) %>%
  relocate (organisationunitid, orgunitlevel2, orgunitlevel3, orgunitlevel4) %>% 
  #remove cases wrongly assigned to Toum as Elimination Districts
  filter(!orgunitlevel3=="1403 Toumlan")


#Associate #MS Savannakhet (Malaria) (orgganisationunitid = aUAwzhOEh3F) as level 4 and level3, as they are not reported in the dataset
cicc.complete$orgunitlevel4[cicc.complete$organisationunitid == "aUAwzhOEh3F" ] <- "MS Savannakhet (Malaria)"
cicc.complete$orgunitlevel3[cicc.complete$organisationunitid == "aUAwzhOEh3F" ] <- "MS Savannakhet (Malaria)"
cicc.complete$orgunitlevel2[cicc.complete$organisationunitid == "aUAwzhOEh3F" ] <- "13 Savannakhet"

#Associate #MS Khammouan (Malaria) (orgganisationunitid = D4unRCyiUfw) as level 4 and level 3
cicc.complete$orgunitlevel4[cicc.complete$organisationunitid == "D4unRCyiUfw" ] <- "MS Khammouan (Malaria)"
cicc.complete$orgunitlevel3[cicc.complete$organisationunitid == "D4unRCyiUfw" ] <- "MS Khammouan (Malaria)"
cicc.complete$orgunitlevel2[cicc.complete$organisationunitid == "D4unRCyiUfw" ] <- "12 Khammouan"

# 3) Use the function: impute_orgunit() to identify the org unit under level 3 that do not have any org unit as level 4, and classify them as their value in level 3 not associated to any NA,
fixed.orgunit <- impute_orgunit(aggr.cases$orgunitlevel4,aggr.cases$orgunitlevel3)
aggr.cases$orgunitlevel4 <- fixed.orgunit[[1]]
aggr.cases$orgunitlevel3 <- fixed.orgunit[[2]]
aggr.cases <- aggr.cases %>% 
  relocate (organisationunitid, orgunitlevel2, orgunitlevel3, orgunitlevel4)

#Look at the variables withouth NA
aggr.cases %>% filter(grepl(" IH ", orgunitlevel3)) %>% nrow() #0
aggr.cases %>% filter(grepl(" AH ", orgunitlevel3)) %>% nrow() #0
aggr.cases %>% filter(grepl(" PH ", orgunitlevel3)) %>% nrow() #33

### Remove PHW and wrongly associated Villages
# Assuming villages from level 4 instead of 5 have been wrongly associated, along with Provincial Warehouses and Children hospitals- to be removed from the list
aggr.cases <- aggr.cases %>% filter(!grepl(" PH ", 
                                           orgunitlevel3)) 

#Creating a dataset with all the HFs without orgunitlevel3
na.aggr.cases<- merge(aggr.cases %>% 
                        filter(is.na(orgunitlevel3)) %>% 
                        select (-orgunitlevel3),
                      HFML [, c("health_facility_dhis2_uid",
                                "orgunitlevel3")],
                      by.x = "organisationunitid",
                      by.y = "health_facility_dhis2_uid",
                      all.x=TRUE) %>% 
  relocate(organisationunitid, orgunitlevel2, orgunitlevel3, orgunitlevel4)

#Include the new district into the NA value by initially removing the district with NA and then binding the new wone
aggr.cases <- aggr.cases %>% drop_na(orgunitlevel3)
aggr.cases <- rbind(aggr.cases, 
                    na.aggr.cases)

### 5) Repeat the process for CICC Complete cases
cicc.orgunit <- impute_orgunit(cicc.complete$orgunitlevel4,cicc.complete$orgunitlevel3)
cicc.complete$orgunitlevel4 <- cicc.orgunit[[1]]
cicc.complete$orgunitlevel3 <- cicc.orgunit[[2]]
cicc.complete <- cicc.complete %>% 
  relocate (organisationunitid, 
            orgunitlevel2, 
            orgunitlevel3, 
            orgunitlevel4, 
            orgunitlevel5)

#Create the dataset with all the HFs without orgunitlevel3
na.cicc.complete<- merge(cicc.complete %>% 
                           filter(is.na(orgunitlevel3)) %>% 
                           select (-orgunitlevel3),
                         HFML [, c("health_facility_dhis2_uid",
                                   "orgunitlevel3")],
                         by.x = "organisationunitid",
                         by.y = "health_facility_dhis2_uid",
                         all.x=TRUE) %>%
  relocate(organisationunitid, 
           orgunitlevel2, 
           orgunitlevel3, 
           orgunitlevel4, 
           orgunitlevel5)

#Include the new district into  the na value by initially removing the district with NA and then binding the new one
cicc.complete <- cicc.complete %>% drop_na(orgunitlevel3)
cicc.complete <- rbind(cicc.complete, na.cicc.complete)


# Aggregate CC data by year and health facility level----

#Initially, Obtain Year per each case from the Case Classification Line List
cicc.complete$enrollment_date <- as.Date(cicc.complete$enrollment_date, format = '%Y-%m-%d')
cicc.complete$year <- format(as.Date(cicc.complete$enrollment_date), "%Y") #using enrollment date to define the year of diagnosis, could be used data of diagnosis as well, although it's not always reported

#reorder df based on the newly created columns
cicc.complete<- cicc.complete %>% relocate(organisationunitid, orgunitlevel2, orgunitlevel3, orgunitlevel4, orgunitlevel5, year, enrollment_date)
cicc.complete$mal_local_case <- cicc.complete$mal_indigenous_case + cicc.complete$mal_introduced_case
#Classify NA as 0
cicc.complete <- cicc.complete %>% mutate(mal_local_case=if_else(is.na(mal_local_case), 0,mal_local_case))

#Aggregate by Health Facility and Year, per species

#  Create variables based on the classification and species
cicc.complete <-cicc.complete %>%
  mutate(
    classification = case_when(
      mal_t_imported_case == 1 ~ 'Imported',
      mal_local_case == 1 ~ 'Local',
      mal_t_induced_case == 1 ~ 'Induced',
      mal_t_relapsed_or_recrudescent_case == 1 ~ 'Relapsed',
      T ~ 'Local'
    ),
    positive = 1
  ) %>%
  pivot_wider(
    names_from = c(invest_diagnosis_test_result, classification),
    values_from =  positive,
    values_fill = 0
  ) %>%
  clean_names()

#Aggregate by year, classification status, and species
#review when new classification occurs in 2024 for imported, relapses, induced by all the species
aggr.cicc <- cicc.complete %>%
  group_by(orgunitlevel4, year) %>%
  summarise(across(c(p_vivax_local,
                     p_vivax_imported,
                     p_falciparum_local,
                     p_falciparum_imported,
                     mixed_imported,
                     p_vivax_induced,
                     p_vivax_relapsed,
                     mixed_local,
                     p_falciparum_relapsed),
                   sum)) %>%
  ungroup() %>%
  pivot_wider(names_from = year,
              values_from = c(p_vivax_local,
                              p_vivax_imported,
                              p_falciparum_local,
                              p_falciparum_imported,
                              mixed_imported,
                              p_vivax_induced,
                              p_vivax_relapsed,
                              mixed_local,
                              p_falciparum_relapsed))


### Create the final aggregated dataset with all the cases from 2018 and all the classified cases, by organisationunit4, i.e. health facility level
lao.cases <- MyMerge(aggr.cases, aggr.cicc) %>% drop_na(organisationunitid)

#Remove the previous datasets from R Enviroment
rm(username, password, url.aggr, url.cicc, url.cicc2021, urlvillage, level5.test, cicc.recent, cicc.2021, na.aggr.cases, na.cicc.complete, cicc.orgunit, fixed.orgunit, HFML, aggr.cases)

#Create Pf & Mixed variables, and assumed local pv, pf&mix to prepare for the foci characterization
lao.cases <- lao.cases %>% 
  mutate(across(mal_t_positive_actual_2018:p_falciparum_relapsed_2024, replace_na, 0),   #replace all NAs with 0
         
         # Calculating pfmix_for each year
         mal_t_positive_pfmix_2018 = mal_t_positive_mix_2018 + mal_t_positive_p_f_2018,
         mal_t_positive_pfmix_2019 = mal_t_positive_mix_2019 + mal_t_positive_p_f_2019,
         mal_t_positive_pfmix_2020 = mal_t_positive_mix_2020 + mal_t_positive_p_f_2020,
         mal_t_positive_pfmix_2021 = mal_t_positive_mix_2021 + mal_t_positive_p_f_2021,
         mal_t_positive_pfmix_2022 = mal_t_positive_mix_2022 + mal_t_positive_p_f_2022,
         mal_t_positive_pfmix_2023 = mal_t_positive_mix_2023 + mal_t_positive_p_f_2023,
         mal_t_positive_pfmix_2024 = mal_t_positive_mix_2024 + mal_t_positive_p_f_2024,
         
         # Calculating pfmix imported for each year
         pfmix_imported_2021 = p_falciparum_imported_2021 + mixed_imported_2021,
         pfmix_imported_2022 = p_falciparum_imported_2022 + mixed_imported_2022,
         pfmix_imported_2023 = p_falciparum_imported_2023 + mixed_imported_2023,
         pfmix_imported_2024= p_falciparum_imported_2023 + mixed_imported_2024,
         
         
         # pfmix_induced_2024= p_falciparum_induced_2024 + mixed_induced_2024,         #uncomment if Pf & mixed induced found in 2024
         
         # Calculating pfmix_relapsed for each year
         
         pfmix_relapsed_2021 = p_falciparum_relapsed_2021,                             #no mixed relapsed found in 2021
         pfmix_relapsed_2022 = p_falciparum_relapsed_2022,                             #no mixed relapsed found in 2022
         pfmix_relapsed_2023 = p_falciparum_relapsed_2023,
         pfmix_relapsed_2024= p_falciparum_relapsed_2024,                              #uncomment ,if Pf & mixed relpased found in 2024
         
         # Calculating pfmix assumed local for each year
         
         pfmix_assumed_local_2018 = mal_t_positive_pfmix_2018,             #No CICC in 2018, all cases assumed local                       
         pfmix_assumed_local_2019 = mal_t_positive_pfmix_2019,             #No CICC in 2019, all cases assumed local                          
         pfmix_assumed_local_2020 = mal_t_positive_pfmix_2020,             #No CICC in 2020, all cases assumed local
         pfmix_assumed_local_2021 = mal_t_positive_pfmix_2021 - pfmix_imported_2021,      
         pfmix_assumed_local_2022 = mal_t_positive_pfmix_2022 - pfmix_imported_2022,      
         pfmix_assumed_local_2023 = mal_t_positive_pfmix_2023 - pfmix_imported_2023, 
         pfmix_assumed_local_2024 = mal_t_positive_pfmix_2024 - pfmix_imported_2024,
         
         # Calculating pv assumed local for each year
         
         pv_assumed_local_2018 = mal_t_positive_p_v_actual_2018_2022_2018,  #No CICC in 2018, all cases assumed local                       
         pv_assumed_local_2019 = mal_t_positive_p_v_actual_2018_2022_2019,  #No CICC in 2019, all cases assumed local                          
         pv_assumed_local_2020 = mal_t_positive_p_v_actual_2018_2022_2020,  #No CICC in 2020, all cases assumed local
         pv_assumed_local_2021 = mal_t_positive_p_v_actual_2018_2022_2021 - p_vivax_imported_2021,  
         pv_assumed_local_2022 = mal_t_positive_p_v_actual_2018_2022_2022 - p_vivax_imported_2022,      
         pv_assumed_local_2023 = mal_t_positive_p_v_actual_2018_2022_2023 - p_vivax_imported_2023, 
         pv_assumed_local_2024 = mal_t_positive_p_v_actual_2018_2022_2024 - p_vivax_imported_2024,
         
         # Calculating total malaria assumed local for each year
         
         mal_assumed_local_2018= mal_t_positive_actual_2018,               #No CICC in 2018, all cases assumed local
         mal_assumed_local_2019= mal_t_positive_actual_2019,               #No CICC in 2019, all cases assumed local
         mal_assumed_local_2020= mal_t_positive_actual_2020,               #No CICC in 2020, all cases assumed local
         mal_assumed_local_2021= mal_t_positive_actual_2021 - pfmix_imported_2021 - p_vivax_imported_2021,
         mal_assumed_local_2022= mal_t_positive_actual_2022 - pfmix_imported_2022 - p_vivax_imported_2022,
         mal_assumed_local_2023= mal_t_positive_actual_2023 - pfmix_imported_2023 - p_vivax_imported_2023,
         mal_assumed_local_2024= mal_t_positive_actual_2024 - pfmix_imported_2024 - p_vivax_imported_2024) %>% 
  relocate(orgunitlevel1, orgunitlevel2, orgunitlevel3, orgunitlevel4, organisationunitid, organisationunitname) %>% 
  arrange(orgunitlevel3)

#Save file
write.csv(lao.cases, "results/lao.cases_cicc.csv", row.names = F, fileEncoding = "UTF-8")

