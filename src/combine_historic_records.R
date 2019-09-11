library(dplyr)
library(ncdf4) 

message(sprintf("Started at %s", Sys.time()))

read_period_of_record_data <- function(fn, varid) {
  
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

  return(data)
}

combine_variables_to_one_df <- function(dflist) {
  # Using bind_rows ensures that the columns are lined up with each other
  #   post-binding even if they aren't in the same order in the separate dfs
  #   e.g. bind_rows(mtcars[1:2], mtcars[2:1])
  # Started at 1:30 & took 30 minutes for two of the variables!
  message("binding rows of data frames in list")
  variable_df <- bind_rows(dflist) 
  
  return(variable_df)
}

# NetCDF files from Steve Markstrom
soil_moist_tot <- read_period_of_record_data("historical_soil_moist_tot_out.nc", "soil_moist_tot")
pkwater_equiv <- read_period_of_record_data("historical_pkwater_equiv_out.nc", "pkwater_equiv")
hru_intcpstor <- read_period_of_record_data("historical_hru_intcpstor_out.nc", "hru_intcpstor")
hru_impervstor <- read_period_of_record_data("historical_hru_impervstor_out.nc", "hru_impervstor")
gwres_stor <- read_period_of_record_data("historical_gwres_stor_out.nc", "gwres_stor")
dprst_stor <- read_period_of_record_data("historical_dprst_stor_hru_out.nc", "dprst_stor_hru")

variable_df_list <- list(
  pkwater_equiv = pkwater_equiv,
  soil_moist_tot = soil_moist_tot,
  hru_intcpstor = hru_intcpstor,
  hru_impervstor = hru_impervstor,
  gwres_stor = gwres_stor,
  dprst_stor = dprst_stor
)

# Combine all variables into one df ----
variable_df <- combine_variables_to_one_df(variable_df_list)
saveRDS(variable_df, "combined_vars.rds")

message(sprintf("Finished at %s", Sys.time()))
