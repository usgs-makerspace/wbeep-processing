#need stream reaches output by nhdplusTools::stage_national_data
#I dropped some unneeded columns after that
#load modules
#module load R/3.5.1-gcc7.1.0 gdal/2.2.2-gcc gis/geos-3.5.0 proj/5.0.1-gcc-7.1.0
library(sf)
library(dplyr)
#this came from NHDplustools
#probably need to work on Yeti, full unzipped .gdb of NHDPlus is 80GB
geom <- readRDS('src/geom_relevant.rds') 

for(order in unique(geom$StreamOrde)) {
  order_geom <- filter(geom, StreamOrde == order) %>% 
    select(Shape)
  outfile <- paste0("nhdplus_order_", order, ".geojson")
  st_write(order_geom, dsn = outfile)
  message(order, "done")
}

############################
# read in all the geojson to use for writing out the grouped tileset

one <- st_read('nhd_geojson/nhdplus_order_1.geojson')
two <- st_read('nhd_geojson/nhdplus_order_2.geojson')
three <- st_read('nhd_geojson/nhdplus_order_3.geojson')
four <- st_read('nhd_geojson/nhdplus_order_4.geojson')
five <- st_read('nhd_geojson/nhdplus_order_5.geojson')
six <- st_read('nhd_geojson/nhdplus_order_6.geojson')
seven <- st_read('nhd_geojson/nhdplus_order_7.geojson')
eight <- st_read('nhd_geojson/nhdplus_order_8.geojson')
nine <- st_read('nhd_geojson/nhdplus_order_9.geojson')
minusnine <- st_read('nhd_geojson/nhdplus_order_minus_9.geojson')
ten <- st_read('nhd_geojson/nhdplus_order_10.geojson')


############################
#combine a few individual files to make inputs for grouped tileset

#most uses all of the stream orders 1-10 (and minus nine)
most_detail <- do.call("rbind", list(one, two, three, four, five, six, seven, eight, nine, minusnine, ten))
st_write(most_detail, dsn="nhd_geojson/most_detail.geojson")

#medium uses just 2-10
medium_detail <- do.call("rbind", list(two, three, four, five, six, seven, eight, nine, minusnine, ten))
st_write(medium_detail, dsn="nhd_geojson/medium_detail.geojson")

#least uses just 4-10
least_detail <- do.call("rbind", list(four, five, six, seven, eight, nine, minusnine, ten))
st_write(least_detail, dsn="nhd_geojson/least_detail.geojson")
