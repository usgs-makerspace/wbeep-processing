# Processing code to create percentiles for groups of HRUs

# This is preliminary work.

# Creating a historic understanding of how "total storage"
#   has varied through time for each HRU by calculating
#   quantiles to establish very low, low, normal, high, 
#   and very high thresholds of "total storage" for each
#   HRU at every day of the year. Rather than only using
#   values at every day of the year, we are using 5 values
#   before and 5 values after to calculate the thresholds 
#   for each day.

# Total storage = pkwater_equiv + soil_moist_tot + hru_intcpstor +
#                 hru_impervstor + gwres_stor + dprst_stor_hru

# TO DO: 
#   1. Use task_id to loop through groups of HRUs using slurm
#   2. Calc for probs = seq(0, 1, by = 0.05)
#   3. Fix this to work with incomplete years & leap years
#   4. Add -Inf and +Inf in `combine_hru_quantiles` right before saving.

start <- Sys.time()
library(ncdf4) 
library(data.table)

########## Functions ########## 
task_id_to_hru_seq <- function(task_id, n_hrus_per_task = 1000) {
  # Convert task id to HRU ids (increment by n_hrus_per_task)
  hru_id_start <- ((task_id-1)*n_hrus_per_task + 1) # which hru to start with
  hru_id_end <- hru_id_start + (n_hrus_per_task-1) # which hru to end with
  
  # If we are past the last column, cut the final col id off
  n_hrus <- 109951
  hru_id_end <- ifelse(hru_id_end > n_hrus,
                       yes = n_hrus,
                       no = hru_id_end)
  
  hru_seq <- hru_id_start:hru_id_end
  return(hru_seq)
}
read_ncdf_data <- function(fn, varid, hru_seq) {
  
  # The file is NetCDF
  nc <- nc_open(fn)
  
  message(sprintf("Reading in NetCDF data for %s", varid))
  # Only load rows for current HRUs
  data_nc <- ncvar_get(nc, varid, 
                       start = c(head(hru_seq, 1), 1),
                       count = c(length(hru_seq), -1))
  time <- ncvar_get(nc, "time")
  hruid <- ncvar_get(nc, "hruid")[hru_seq]
  
  # Convert ncdf4 times to R dates
  time_att <- ncdf4::ncatt_get(nc, "time")
  time_start <- as.Date(gsub("days since ", "", time_att$units))
  time_fixed <- time + time_start # creates dates from the "days since" var
  
  # Keep only complete years of data
  # data_years <- format(time_fixed, "%Y")
  # n_days_per_year <- table(data_years)
  # data_years_complete <- names(n_days_per_year)[n_days_per_year >= 365]
  
  year_doy_vector <- paste(format(time_fixed, "%Y"), format(time_fixed, "%j"), sep = "_")
  dt <- as.data.table(cbind(hruid, data_nc)) # takes ~2 minutes
  names(dt) <- c("hruid", year_doy_vector)
  dt_long <- melt(dt, id.vars = "hruid", variable.name = "year_doy")
  dt_long[, variable := varid]
  
  return(dt_long)
}
get_doy_sequence <- function(target_doy, window = 5) {
  
  # Determine which doy to start & end with in the window
  begin_doy <- target_doy - window
  end_doy <- target_doy + window
  
  # Handle edge cases:
  last_doy <- 365 # switch back to 366 once leap days are implemented
  if(begin_doy <= 0) {
    # Need to look backward into last days of the year
    seq_doy <- c((last_doy + begin_doy):last_doy, 1:end_doy)
  } else if (end_doy > last_doy) {
    # Need to look forward into first days of the year
    seq_doy <- c(begin_doy:last_doy, 1:(end_doy - last_doy))
  } else {
    seq_doy <- begin_doy:end_doy
  }
  
  return(seq_doy)
}
extract_doy_cols_to_vec <- function(df, doy_seq) {
  ############## WORKING ON THIS
  # Do I need to convert to df?
  df <- as.data.frame(df)
  doy_seq_colnames <- sprintf("%03d", doy_seq)
  target_df <- df[, doy_seq_colnames]
  ############## 
  target_vector <- unlist(target_df, use.names = FALSE)
  return(target_vector)
}
get_quantile_df <- function(target_doy_values, target_doy_seq, 
                            target_doy, probs = c(0.10, 0.25, 0.75, 0.90)) {
  target_doy_quantiles <- quantile(target_doy_values, 
                                   probs = probs, 
                                   type = 6,
                                   na.rm = TRUE)
  target_doy_quantile_df <- cbind(DOY = target_doy, t(target_doy_quantiles))
  return(target_doy_quantile_df)
}
########## ////// ########## 

# Identify task id from yeti environment & convert to HRU ids ----
# task_id <- as.numeric(Sys.getenv('SLURM_ARRAY_TASK_ID', 'NA'))
task_id <- 2 # Will uncomment once setup with slurm
hru_seq <- task_id_to_hru_seq(task_id)

message(sprintf("Started this task at %s", Sys.time()))

vars <- c(
  "soil_moist_tot",
  "pkwater_equiv",
  "hru_intcpstor", 
  "hru_impervstor",
  "gwres_stor", 
  "dprst_stor_hru"
)

dt_long <- c()
for(var in vars) {
  
  # Read in the two datasets
  ncdf_fn <- sprintf("historical_%s_out.nc", var)
  var_df <- read_ncdf_data(ncdf_fn, var, hru_seq)
  dt_long <- rbind(dt_long, var_df)
}

#######################
# Find data.table equivalent to "separate"
# dt_long_sep <- tidyr::separate(dt_long, year_doy, c("year", "doy"), "_")
# Doesn't seem that much faster ...
dt_long[, c("year", "doy") := tstrsplit(year_doy, "_", fixed=TRUE)]
dt_long[, year_doy := NULL]

#######################

# `fill = NA` to account for missing dates at beginning 
#   of 1980 and end of 2019
# This spreads + sums the values! Takes ~ 10 sec
dt_wide <- dcast(dt_long, hruid+year ~ doy, fun=sum, fill=NA)
dt_wide[, year := NULL]

all_hru_quantiles_list <- lapply(hru_seq, function(hruid_i) {
  
  hru_data <- dt_wide[hruid == hruid_i,]
  hru_data[, hruid := NULL]
  
  doy_quantile_list <- lapply(1:365, function(target_doy, df) {
    target_doy_seq <- get_doy_sequence(target_doy)
    target_doy_values <- extract_doy_cols_to_vec(df, target_doy_seq)
    target_doy_quantile_df <- get_quantile_df(target_doy_values, target_doy_seq, target_doy)
    return(target_doy_quantile_df)
  }, df = hru_data)
  
  hru_quantiles_df <- do.call("rbind", doy_quantile_list)
  hru_quantiles_df <- cbind(hruid = hruid_i, hru_quantiles_df)
  
  return(hru_quantiles_df)
})

all_hru_quantiles_df <- do.call("rbind", all_hru_quantiles_list)

quantile_fn <- sprintf("grouped_quantiles/total_storage_quantiles_%s_to_%s.csv", head(hru_seq, 1), tail(hru_seq, 1))
fwrite(all_hru_quantiles_df, quantile_fn)

# Timekeeping to see how long it takes
end <- Sys.time()
time_passed <- end - start
fwrite(list(start = as.character(start), 
            end = as.character(end), 
            time_passed = time_passed), 
       sprintf("time_passed_%s_%s.txt", head(hru_seq, 1), tail(hru_seq, 1))) 
# finished in 5 min for 1:1000
