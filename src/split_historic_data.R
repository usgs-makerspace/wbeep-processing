library(ncdf4) 

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

message(sprintf("Started this task at %s", Sys.time()))

# Read and iteratively save many small files (one to many)
# Using NetCDF files from Steve Markstrom

vars <- c(
  "soil_moist_tot",
  "pkwater_equiv",
  "hru_intcpstor", 
  "hru_impervstor",
  "gwres_stor", 
  "dprst_stor_hru"
)

#from yeti environment
task_id <- as.numeric(Sys.getenv('SLURM_ARRAY_TASK_ID', 'NA'))
task_var <- vars[task_id]

# Read in the two datasets
task_var_df <- read_period_of_record_data(sprintf("historical_%s_out.nc", task_var), task_var)

message(sprintf("Started saving individual files per HRU for %s at %s", task_var, Sys.time()))
for(i in 1:(ncol(task_var_df)-1)) {
  task_var_df_i <- as.data.frame(task_var_df[,c(1, (i+1))])
  saveRDS(task_var_df_i, sprintf("cache/%s_%s.rds", task_var, i))
}

message(sprintf("Completed this task at %s", Sys.time()))
