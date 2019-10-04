#!/bin/bash

tippecanoe -Z4 -z8 --no-tiny-polygon-reduction --detect-shared-borders --simplify-only-low-zooms --simplification=5 --output-to-directory tile_dir_simple5 no_simp_prec5.geojson 


#to create NHDPlus stream order tiles
tippecanoe -zg --detect-shared-borders --simplify-only-low-zooms --drop-densest-as-need --simplification=5 --output-to-directory nhd_order_grouped nhdplus_order_1.geojson nhdplus_order_2_3.geojson nhdplus_order_4_5.geojson nhdplus_order_6.geojson
nhd_geojson wwatkins$ aws s3 cp nhd_order_grouped/ s3://maptiles-prod-website/nhdstreams_grouped --recursive --content-encoding 'gzip' --content-type 'application/x-protobuf' --profile chsprod