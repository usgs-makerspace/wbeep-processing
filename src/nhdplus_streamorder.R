#need stream reaches output by nhdplusTools::stage_national_data
#I dropped some unneeded columns after that
#load modules
#module load R/3.5.1-gcc7.1.0 gdal/2.2.2-gcc gis/geos-3.5.0 proj/5.0.1-gcc-7.1.0
library(sf)
library(dplyr)
#this came from NHDplustools
#probably need to work on Yeti, full unzipped .gdb of NHDPlus is 80GB
geom <- readRDS('geom_relevant.rds') 

for(order in unique(geom$StreamOrde)) {
  order_geom <- filter(geom, StreamOrde == order) %>% 
    select(Shape)
  outfile <- paste0("nhdplus_order_", order, ".geojson")
  st_write(order_geom, dsn = outfile)
  message(order, "done")
}

############################
#combine a few individual files to make inputs for grouped tileset
two <- st_read('nhd_geojson/nhdplus_order_2.geojson')
three <- st_read('nhd_geojson/nhdplus_order_3.geojson')
two_three <- do.call(rbind, list(two, three))
st_write(two_three, dsn = "nhd_geojson/nhdplus_orders_2_3.geojson")
four <- st_read('nhd_geojson/nhdplus_order_4.geojson')
five <- st_read('nhd_geojson/nhdplus_order_5.geojson')
four_five <- do.call(rbind, list(four, five))
st_write(four_five, dsn = "nhd_geojson/nhdplus_orders_4_5.geojson")
