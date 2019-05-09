library(sf)
library(lwgeom)

#TODO: replace with pull from S3 once bucket is made
gfdb <- "cache/GF_nat_reg.gdb"
hru_reduced <- read_sf(gfdb, "nhru")  %>% 
  dplyr::select(Shape, hru_id_nat) %>% 
  st_transform(crs = '+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m')

#parallelize validation
library(parallel)
cl <- makeCluster(detectCores() - 1)
split_hru_shapes <- clusterSplit(cl, hru_reduced$Shape)
#takes ~10 minutes on my laptop with 7 core cluster
hru_list_valid <- parLapply(cl, split_hru_shapes, fun = st_make_valid)
hru_valid_shapes <- do.call(what = c, hru_list_valid)
stopCluster(cl)

#NOTE: assuming orders haven't been shuffled here
hru_reduced$Shape <- hru_valid_shapes
write_sf(hru_reduced, 'cache/hru_reduced_valid.shp')
system('mapshaper cache/hru_reduced_valid.shp -simplify 10% -o simp_10.topojson')
