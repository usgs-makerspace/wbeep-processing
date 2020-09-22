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

# TO DO: 
#   1. Use task_id to loop through groups of HRUs using slurm - haven't been able to get a test working
#   2. Fix this to work with incomplete years & leap years
#   3. Add check to test that HRUs and dates across 6 files match.

start <- Sys.time()

library(data.table)

########## Functions ########## 
task_id_to_hru_seq <- function(task_id, n_hrus_per_task = 1000) {
  # Convert task id to HRU ids (increment by n_hrus_per_task)
  hru_id_start <- ((task_id-1)*n_hrus_per_task + 1) # which hru to start with
  hru_id_end <- hru_id_start + (n_hrus_per_task-1) # which hru to end with
  
  # If we are past the last column, cut the final col id off
  n_hrus <- 114958
  hru_id_end <- ifelse(hru_id_end > n_hrus,
                       yes = n_hrus,
                       no = hru_id_end)
  
  hru_seq <- hru_id_start:hru_id_end
  return(hru_seq)
}
########## ////// ########## 

# Identify task id from yeti environment & convert to HRU ids ----
task_id <- as.numeric(Sys.getenv('SLURM_ARRAY_TASK_ID', 'NA'))
hru_seq <- task_id_to_hru_seq(task_id)
hru_start <- sprintf("%.0f", head(hru_seq, 1)) # prevents hruid from being in scientific notation as character
hru_end <- sprintf("%.0f", tail(hru_seq, 1))

message(sprintf("Started this task at %s", Sys.time()))

total_storage_group_data <- feather::read_feather(sprintf("grouped_total_storage/total_storage_data_%s_to_%s.feather", hru_start, hru_end))
quantile_fn <- sprintf("grouped_quantiles/total_storage_quantiles_%s_to_%s.feather", hru_start, hru_end)

if(!file.exists(quantile_fn)) {

  message("Reformatting data")
  
  # Reshape data
  dt <- as.data.table(total_storage_group_data)
  dt_long <- melt(dt, id.vars = "hruid", variable.name = "year_doy")
  
  # Split year_doy into separate columns
  # Converting to numeric (type_convert = TRUE) slows down
  dt_long[, c("year", "doy") := tstrsplit(year_doy, "_", fixed=TRUE)]
  
  # `fill = NA` to account for missing dates at beginning 
  #   of 1980 and end of 2019
  # This spreads & puts values per doy in a column
  dt_wide <- dcast(dt_long, hruid+year ~ doy, fun=c, fill=NA)
  dt_wide[, year := NULL]
  
  message(sprintf("Start calculating quantiles at %s", Sys.time()))
  
  all_hru_quantiles_list <- lapply(hru_seq, function(hruid_i) {

    message(sprintf("Starting quant calc %s ...", hruid_i))
    
    hru_data <- dt_wide[hruid == hruid_i,]
    
    ############# WORKING ON THIS
    # Still need to figure out best solution for leap years
    #############
    
    all_doy_seq <- 1:365
    doy_quantile_list <- lapply(all_doy_seq, function(target_doy, dt) {
      
      # Get doy sequence
      # Create doy vector that may extend into negative or beyond 365
      # If below 1 or beyond 365, wrap around so all numbers are between 1 and 365
      target_doy_seq_literal <- (-5:5) + target_doy # 5 = window to use around date
      target_doy_seq <- ((target_doy_seq_literal - 1) %% 365) + 1 
      
      # Extract doy cols into a vector
      doy_seq_colnames <- sprintf("%03d", target_doy_seq)
      target_dt <- dt[, doy_seq_colnames, with=FALSE]
      target_doy_values <- unlist(target_dt, use.names = FALSE)
      
      # Calculate quantiles
      target_doy_quantiles <- quantile(target_doy_values, 
                                       probs = seq(0.05, 0.95, by=0.05), #c(0.10, 0.25, 0.75, 0.90) 
                                       type = 6, na.rm = TRUE)
      
      return(target_doy_quantiles)
    }, dt = hru_data)
    
    hru_quantiles_mat <- do.call("rbind", doy_quantile_list)
    hru_quantiles_mat <- cbind(hruid = hruid_i, DOY = all_doy_seq, hru_quantiles_mat)
    
    return(hru_quantiles_mat)
  })
  
  message(sprintf("Complete calc & start combining quantiles at %s", Sys.time()))
  
  all_hru_quantiles_df <- do.call("rbind", all_hru_quantiles_list)
  
  feather::write_feather(as.data.frame(all_hru_quantiles_df), quantile_fn)
  
  # Timekeeping to see how long it takes
  end <- Sys.time()
  time_passed <- end - start
  fwrite(data.frame(name = c("start", "end", "time_passed"),
                    value = c(start, end, time_passed)), 
                         sprintf("grouped_quantiles/time_passed_%s_%s.txt", hru_start, hru_end)) 
  # finished in 5 min for 1:1000
} else {
  message(sprintf("Quantiles already complete for HRUs %s to %s. Delete or rename the file to override and re-calculate.", hru_start, hru_end))
}
