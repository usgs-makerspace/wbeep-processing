# Reformat NetCDF files and save as RDS (parallel)

library(ncdf4)

reformat_ncdf_rds <- function() {
  
  varids <- c("soil_moist_tot", "pkwater_equiv", "hru_intcpstor",
              "hru_impervstor", "gwres_stor", "dprst_stor_hru")
  
  # Current varid
  task_id <- as.numeric(Sys.getenv('SLURM_ARRAY_TASK_ID', 'NA'))
  varid <- varids[task_id]
  
  # The file is NetCDF
  nc <- nc_open(sprintf("historical_%s_out.nc", varid))
  
  message(sprintf("Reading in NetCDF data for %s", varid))
  data_nc <- ncvar_get(nc, varid)
  time <- ncvar_get(nc, "time")
  hruid <- ncvar_get(nc, "hruid")
  
  # Convert ncdf4 times to R dates
  time_att <- ncdf4::ncatt_get(nc, "time")
  time_start <- as.Date(gsub("days since ", "", time_att$units))
  time_fixed <- time + time_start # creates dates from the "days since" var
  
  # The data is actually transformed and missing hruid and time
  message(sprintf("Transforming data & adding time/hruid attributes for %s", varid))
  data_transformed <- t(data_nc)
  data <- cbind(time_fixed, data_transformed)
  names(data) <- c("Date", hruid)
  
  saveRDS(data, sprintf("historic_%s.rds", varid))
  return(data)
}
