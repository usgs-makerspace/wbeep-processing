library(sf)
library(lwgeom)
library(geojsonio)
#proj_string <- '+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m'
proj_string <- 4326

gfdb <- "cache/GF_nat_reg.gdb"
hru_reduced <- read_sf(gfdb, "nhru")  %>% 
  dplyr::select(Shape, hru_id_nat) %>% 
  st_transform(crs = proj_string)

#parallelize validation
library(parallel)
message(detectCores(), ' cores available, using all but 1')
print(gc()) #see memory available

cl <- makeCluster(detectCores() - 1)
split_hru_shapes <- clusterSplit(cl, hru_reduced$Shape)
#takes ~10 minutes on my laptop with 7 core cluster
hru_list_valid <- parLapply(cl, split_hru_shapes, fun = st_make_valid)
hru_valid_shapes <- do.call(what = c, hru_list_valid)
stopCluster(cl)

#NOTE: assuming orders haven't been shuffled here
hru_reduced$Shape <- hru_valid_shapes

geojson_write(hru_reduced, geometry = "polygon", precision = 5,
              file = "hrus.geojson", convert_wgs84 = TRUE)
