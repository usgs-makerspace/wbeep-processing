library(sf)
library(lwgeom)
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

######TODO: just write out geojson here - 5 dec precision, then tippecanoe

write_sf(hru_reduced, 'cache/hru_reduced_valid.shp')

system('node  --max-old-space-size=8192 `which mapshaper` cache/hru_reduced_valid.shp -simplify percentage=10% keep-shapes stats -o simp_10.topojson')
list.files()
#now revalidate
library(geojsonio)
geojson_hru <- topojson_read('simp_10.topojson', check_ring_dir = TRUE)
geojson_hru$geometry <- st_make_valid(geojson_hru$geometry)
#st_dimension to check for null geoms
dim_check <- st_dimension(geojson_hru$geometry)
null_geoms <- which(is.na(dim_check))
geojson_hru_drop_nulls <- dplyr::slice(geojson_hru, -null_geoms)
st_crs(geojson_hru_drop_nulls) <- proj_string
topojson_write(geojson_hru_drop_nulls, geometry = "polygon",
              file = "topojson_valid.topojson",
              convert_wgs84 = TRUE)
system('topoquantize 1e6 topojson_valid.topojson -o topojson_valid_quant.topojson')
