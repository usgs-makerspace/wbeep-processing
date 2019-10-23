#!/bin/bash

#to create NHDPlus stream order tiles
tippecanoe -zg --detect-shared-borders --simplify-only-low-zooms --drop-densest-as-need --simplification=5 --output-to-directory nhd_order_grouped nhdplus_order_1.geojson nhdplus_order_2_3.geojson nhdplus_order_4_5.geojson nhdplus_order_6.geojson
aws s3 cp nhd_order_grouped/ s3://maptiles-prod-website/nhdstreams_grouped --recursive --content-encoding 'gzip' --content-type 'application/x-protobuf' --profile chsprod