# Take data from Water Use team and reformat to what we need for the bubble map in the visualization
# *** ONLY FOR THERMOELECTRIC (aka TE) RIGHT NOW ***

# INPUT (unzipped data from `HUC12centroid_TE.7z` at ftp://ftpint.usgs.gov/private/wr/id/boise/Skinner/WU/)
#   1. HUC12_TE_2015with.csv – comma-delimited file of withdrawal water use in m3/day by HUC12
#   2. HUC12centroid_TEspt.json –geojson file of centroids for HUC12s with thermoelectric plant(s)
#   3. `maps` package USA dataset for CONUS
# OUTPUT
#   1. Single CSV with water use values summed by day to get a CONUS total called `te_bar_data.csv`.

library(dplyr)
library(sf)

##### Download and unzip data #####
# Note 1: you need to be on VPN to access
# Note 2: this unzipping step doesn't work for lplatt. If it doesn't work,
#   you may need to manually unzip `HUC12centroid_TE.7z` and make sure those
#   files are in `cache/` before moving on. 

# Download and unzip the water use data
zip_fn <- "HUC12centroid_TE.7z"
zip_ftp_path <- file.path("ftp://ftpint.usgs.gov/private/wr/id/boise/Skinner/WU", zip_fn)
zip_local_path <- file.path("cache", zip_fn)
download.file(zip_ftp_path, destfile = zip_local_path)

unzip_result <- system(sprintf('7z e -o %s %s', "cache", zip_local_path)) # 
if(unzip_result == 127) stop("did not actually unzip")

# Download the new json data (HUCs with centroids in Canada are relocated)
json_fn <- "HUC12centroid_TEs_pt2.json"
json_ftp_path <- file.path("ftp://ftpint.usgs.gov/private/wr/id/boise/Skinner/WU", json_fn)
json_local_path <- file.path("cache", json_fn)
download.file(json_ftp_path, destfile = json_local_path)

##### Read in and format data #####

te_plant_centroids <- geojsonsf::geojson_sf(json_local_path) 

albers_str <- "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"
usa_sf <- st_as_sf(maps::map("usa", plot = FALSE, fill = TRUE)) %>% st_transform(albers_str) %>% lwgeom::st_make_valid()

te_data <- readr::read_csv("cache/HUC12_TE_2015with.csv") %>% 
  # Starts in wide format with a column for each day of the year. 
  tidyr::pivot_longer(cols = starts_with("W"), names_to = "Wdate", values_to = "TE_val") %>% 
  mutate(Date = as.Date(gsub("W", "", Wdate), format = "%m-%d-%Y")) %>% 
  # The `HUC12` column originally had " Total" attached to the end of each code
  # Keep the column with only the code (`HUC12t`) and rename to `HUC12`
  select(HUC12 = HUC12t, Date, wu_val = TE_val)
  
##### Filter centroid data to only CONUS #####

te_plant_centroids_conus <- te_plant_centroids %>% 
  st_transform(albers_str) %>% 
  st_intersection(usa_sf)

##### Summarize HUC12 daily WU values into CONUS daily WU values #####

te_bar_data_conus <- te_data %>% 
  filter(HUC12 %in% unique(te_plant_centroids_conus$HUC12)) %>% 
  group_by(Date) %>% 
  summarize(wu_total = sum(wu_val, na.rm = TRUE)) %>% 
  ungroup() %>% 
  mutate(day_nu = as.numeric(format(Date, "%j"))) %>% 
  select(day_nu, wu_total)

##### Save the resulting data to be used for the radial chart #####

readr::write_csv(te_bar_data_conus, "cache/te_bar_data.csv")
