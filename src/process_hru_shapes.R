library(sf)
library(lwgeom)
#proj_string <- '+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m'
proj_string <- 4326

gfdb <- "cache/GF_nat_reg.gdb"
hru_reduced <- read_sf(gfdb, "nhru")  %>% 
  dplyr::select(Shape, hru_id_nat) %>% 
  st_transform(crs = proj_string) %>% 
  dplyr::mutate(hrud_id_2 = hru_id_nat) #need ID in two places in final output

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
#Too big an object to write to geojson directly, since 
#R tries to serialize it all in memory — have to use ogr2ogr
write_sf(hru_reduced, 'hru_reduced_valid.shp')

