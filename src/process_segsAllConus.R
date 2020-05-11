library(sf)
library(lwgeom)

proj_string <- 4326
segsAllConus <- st_read("cache/segsAllConus.shp")
segsAllConus4326 <- st_transform(segsAllConus,proj_string)
write_sf(segsAllConus4326,'segsAllConus4326.shp')
