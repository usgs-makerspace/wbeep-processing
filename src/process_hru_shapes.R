library(sf)
library(lwgeom)
proj_string <- '+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m'
#TODO: replace with pull from S3 once bucket is made
gfdb <- "../wbeep-sandboxr/cache/GF_nat_reg.gdb"
hru_reduced <- read_sf(gfdb, "nhru")  %>% 
  dplyr::select(Shape, hru_id_nat) %>% 
  st_transform(crs = proj_string)

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
system('mapshaper cache/hru_reduced_valid.shp -simplify 1% -o simp_10.topojson')

#now revalidate
library(geojsonio)
geojson_hru <- topojson_read('simp_10.topojson')
geojson_hru$geometry <- st_make_valid(geojson_hru$geometry)
geojson_write(geojson_hru, geometry = "polygon",
              file = "topojson_valid.topojson",
              crs = proj_string)
system('topoquantize 1e6 topojson_valid.topojson -o topojson_valid_quant.json')
