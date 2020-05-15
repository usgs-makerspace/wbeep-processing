# Take data from Water Use team and reformat to what we need for the bubble map in the visualization
# *** ONLY FOR THERMOELECTRIC (aka TE) RIGHT NOW ***

# INPUT (unzipped data from `HUC12centroid_TE.7z` at ftp://ftpint.usgs.gov/private/wr/id/boise/Skinner/WU/)
#   1. HUC12_TE_2015with.csv – comma-delimited file of withdrawal water use in m3/day by HUC12
#   2. HUC12centroid_TEspt.json –geojson file of centroids for HUC12s with thermoelectric plant(s)
# OUTPUT
#   1. Long format geoJSON with thermoelectric water use values transformed into bubble radii (spatial 
#      features duplicated for each timestep)
#   2. Wide format geoJSON with thermoelectric water use values transformed into bubble radii (unique  
#      spatial features with separate column for each timestep)

library(dplyr)

##### Download and unzip data #####
# Note 1: you need to be on VPN to access
# Note 2: this unzipping step doesn't work for lplatt. If it doesn't work,
#   you may need to manually unzip `HUC12centroid_TE.7z` and make sure those
#   files are in `cache/` before moving on. 

zip_fn <- "HUC12centroid_TE.7z"
zip_ftp_path <- file.path("ftp://ftpint.usgs.gov/private/wr/id/boise/Skinner/WU", zip_fn)
zip_local_path <- file.path("cache", zip_fn)
download.file(zip_ftp_path, destfile = zip_local_path)

unzip_result <- system(sprintf('7z e -o %s %s', "cache", zip_local_path)) # 
if(unzip_result == 127) stop("did not actually unzip")

##### Read in data #####

te_plant_centroids <- geojsonsf::geojson_sf("cache/HUC12centroid_TEs_pt.json") 

te_data <- readr::read_csv("cache/HUC12_TE_2015with.csv") %>% 
  # The `HUC12` column originally had " Total" attached to the end of each code
  # Remove that and then take the column with only the code (`HUC12t`) and rename to `HUC12`
  select(-HUC12, HUC12 = HUC12t) %>%  
  # Starts in wide format with a column for each day of the year. 
  tidyr::pivot_longer(cols = starts_with("W"), names_to = "Wdate", values_to = "TE_val") %>% 
  mutate(Date = as.Date(gsub("W", "", Wdate), format = "%m-%d-%Y")) %>% 
  filter(!is.na(HUC12)) %>% # There were some entries with NA for the HUC12 code
  # There are some implausible negative values that need to be changed to zeros
  mutate(TE_val = ifelse(TE_val < 0, 0, TE_val))
  
##### Transform WU values into bubble radii #####

# Calculate the min and max daily thermoelectric values
te_max <- max(te_data$TE_val, na.rm = TRUE)
te_min <- min(te_data$TE_val, na.rm = TRUE)

# Identify the maximum and minimum radii to be used
bubble_rad_max <- 20
bubble_rad_min <- 0

# Now figure out what those radii mean for circle area since that is really
# what we will be scaling these circles by based on their WU value
bubble_area_max <- pi*bubble_rad_max^2
bubble_area_min <- pi*bubble_rad_min^2

# Now rescale the water use values using scale of areas that correspond to radii between 0-20
# Then, calculate the radii
te_data_transformed <- te_data %>% 
  mutate(TE_area = ((TE_val - te_min) * 
                      (bubble_area_max - bubble_area_min) / 
                      (te_max - te_min)) + bubble_area_min) %>% 
  mutate(TE_radius = sqrt(TE_area/pi))

# Validate that `TE_radius` min and max and between 0 and 20
stopifnot(min(te_data_transformed$TE_radius) >= 0)
stopifnot(max(te_data_transformed$TE_radius) <= 20)

##### Join transformed WU values to spatial data and save #####

# Join the long version of the data with the centroids
te_spatial_long <- te_plant_centroids %>% 
  left_join(te_data_transformed, by = "HUC12") %>% 
  select(HUC12, Date, TE_radius)

# Create a wide version of the data and then join with centroids
te_data_wide <- te_data_transformed %>%
  mutate(Wdate = paste0("W", Date)) %>% 
  select(HUC12, Wdate, TE_radius) %>% 
  tidyr::pivot_wider(id_cols = HUC12, names_from = Wdate, values_from = TE_radius)
te_spatial_wide <- te_plant_centroids %>% 
  left_join(te_data_wide, by = "HUC12") %>% 
  select(HUC12, starts_with("W"))

# Save the version with attributes as geojson
geojsonio::geojson_write(te_spatial_long, file = "cache/wu_te_long.geojson")
geojsonio::geojson_write(te_spatial_wide, file = "cache/wu_te_wide.geojson")
