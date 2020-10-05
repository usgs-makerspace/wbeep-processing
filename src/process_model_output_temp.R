# Code for stream temperature daily build

library(ncdf4)
library(dplyr)
library(readr)

args <- commandArgs(trailingOnly=TRUE)
today <- args[1]
fn <- sprintf("%s_seg_tave_water.nc", today)
nc <- nc_open(fn)

tibble(nhm_seg = ncvar_get(nc, varid = "segid"),
       Date = today,
       temp = ncvar_get(nc, varid = "seg_tave_water")) %>% 
  # PRMS documentation states:
  #   -99.9 means that the segment never has any flow (determined up in init).
  #   -98.9 means that this a segment that could have flow, but doesn't
  filter(!temp %in% c(-99.9, -98.9)) %>% 
  write_csv(sprintf("stream_temp_%s.csv", format(as.Date(today), "%Y-%m-%d")))
