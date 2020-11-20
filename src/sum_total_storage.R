# Code to add variables together and then save as files in groups of 1000

# Total storage = pkwater_equiv + soil_moist_tot + hru_intcpstor +
#                 hru_impervstor + gwres_stor + dprst_stor_hru

library(ncdf4) 
library(data.table)

source("src/validate_historic_driver_data.R") # load code to test model data

n_hrus <- 114958
n_hrus_per_group <- 1000

start_of_loop <- Sys.time()

vars <- c(
  "soil_moist_tot",
  "pkwater_equiv",
  "hru_intcpstor", 
  "hru_impervstor", 
  "gwres_stor", 
  "dprst_stor_hru"
)

##### Add NetCDF files into total storage matrix ##### 

vars_data <- c()
date_list <- c()
for(var in vars) {
  
  message(sprintf("Reading in NetCDF data for %s", var))
  
  # The file is NetCDF
  fn <- sprintf("historical_%s_out.nc", var)
  nc <- nc_open(fn)
  
  # Only load rows for current HRUs
  data_nc <- ncvar_get(nc, var, start = c(1,1), count=c(n_hrus, -1))
  data_nc <- data_nc * 2.54 #convert to mm
  hruids <- ncvar_get(nc, "nhru")
  
  if(length(vars_data) == 0) {
    vars_data <- data_nc
  } else {
    vars_data <- vars_data + data_nc
  }
  
  # Get the time details from one of the NetCDF files
  # Will just overwrite each one time but there is a test to check that they are all the same
  time <- ncvar_get(nc, "time")
  time_att <- ncdf4::ncatt_get(nc, "time")
  time_start <- as.Date(gsub("days since ", "", time_att$units))
  time_fixed <- time + time_start # creates dates from the "days since" var
  
  # Collect dates for each var to compare after
  date_list_var <- list(time_fixed)
  names(date_list_var) <- var
  date_list <- append(date_list, date_list_var)
  
  # Run tests before returning any data
  message(sprintf("Started tests for %s", var))
  validate_historic_driver_data(var, fn, data_nc, hruids, time, time_fixed)
  message(sprintf("Completed tests for %s", var))
  
  nc_close(nc)
  gc() # garbage cleanup
}

validate_historic_data_times_match(date_list, vars)

end_of_loop <- Sys.time()

message(sprintf("Loop complete, took %s minutes. Saving file.", end_of_loop - start_of_loop))

##### Split total into groups and then format #####

# could do parallel starting here instead of 2 different slurms
# 1 node could have multiple cores running this grouping in parallel

start_of_split <- Sys.time()
n_groups <- round(n_hrus/n_hrus_per_group)
for(g in 1:n_groups) {
  # Try feather, too
  hruid_start <- ((g-1)*n_hrus_per_group + 1) # which hru to start with
  hruid_end <- hruid_start + (n_hrus_per_group-1) # which hru to end with
  hruid_end <- ifelse(hruid_end > n_hrus, yes = n_hrus, no = hruid_end)

  hruid_start_char <- sprintf("%.0f", hruid_start) # will stop anything that has scientific notation
  hruid_end_char <- sprintf("%.0f", hruid_end)

  hru_group_fn <- sprintf("grouped_total_storage/total_storage_data_%s_to_%s.feather", hruid_start_char, hruid_end_char)

  if(file.exists(hru_group_fn)) {
    message(sprintf("Already completed %s to %s, skipping ...", hruid_start_char, hruid_end_char))
    next
  }

  message(sprintf("... subsetting large data for %s to %s ...", hruid_start_char, hruid_end_char))
  hru_group_data <- vars_data[hruid_start:hruid_end,] # subset rows to just HRUs in this group

  # Keep only complete years of data
  # data_years <- format(time_fixed, "%Y")
  # n_days_per_year <- table(data_years)
  # data_years_complete <- names(n_days_per_year)[n_days_per_year >= 365]
  year_doy_vector <- format(time_fixed, "%Y_%j")
  dt <- as.data.table(hru_group_data)
  dt[, hruid := hruid_start:hruid_end]
  names(dt) <- c(year_doy_vector, "nhru")

  # With feather, took 12 seconds & files were 109.2 MB
  # With fread, took 58 seconds & average file was 125 MB

  #fwrite(hru_group_data, sprintf("grouped_total_storage/total_storage_data_%s_to_%s.csv", hruid_start, hruid_end))
  feather::write_feather(as.data.frame(dt), hru_group_fn)
}

end_of_split <- Sys.time()

message(sprintf("Split & write complete, took %s seconds. DONE", end_of_split - start_of_split))
