library(sf)
library(lwgeom)

proj_string <- 4326
segsAllConus <- st_read("cache/segsAllConus.shp")
segsAllConus4326 <- st_transform(segsAllConus,proj_string)
#remove the z dimension from the shapefile data otherwise writing out the file fails
segsAllConus4326 <- st_zm(segsAllConus4326, drop=T, what='ZM')
write_sf(segsAllConus4326,'segsAllConus4326.shp')
