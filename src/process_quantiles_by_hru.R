library(dplyr)

# Processing code to create percentiles for each HRU

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

# Function to combine all 6 vars into one ----
combine_vars_to_total_storage_df <- function(hruid) {
  
  # Read all 6 vars
  vars <- c("soil_moist_tot", "pkwater_equiv", "hru_intcpstor", 
            "hru_impervstor", "gwres_stor", "dprst_stor_hru")
  hru_files <- sprintf("cache/%s_%s.rds", vars, hruid)
  hru_df <- bind_rows(lapply(hru_files, readRDS))
  
  hru_df$Date <- as.Date(hru_df$time_fixed, origin = "1970-01-01")
  hru_df$time_fixed <- NULL
  
  # Rename column with values to hru id
  names(hru_df)[!grepl("Date", names(hru_df))] <- "values"
  
  # Sum rows to get the "total storage" value for each day
  total_storage_hru_df <- hru_df %>%
    group_by(Date) %>%
    summarize(total_storage = sum(values))
  
  # Rename column with values back to hru id
  names(total_storage_hru_df)[!grepl("Date", names(total_storage_hru_df))] <- hruid
  
  return(total_storage_hru_df)
}

# Function to calculate the percentiles associated with a set of HRUs ----
calcuate_percentiles <- function(total_storage_df, hruid) {
  
  # Add column with numeric DOY
  total_storage_df$DOY <- as.numeric(format(total_storage_df$Date, "%j"))
  
  # Calculate quantiles for each DOY using a moving window
  # centered at the current DOY for each HRU column
  
  # doy = current day of year as number
  # df = data frame with all data, assumes cols DOY and
  # window = number of days to look behind and ahead of the current doy
  get_quantiles_doy <- function(doy, df, hruid, window = 5) {
    
    # Determine which doy to start & end with in the window
    begin_doy <- doy - window
    end_doy <- doy + window
    
    # Handle edge cases:
    if(begin_doy < 0) {
      # Need to look backward into last days of the year
      seq_doy <- c((366 + begin_doy):366, 1:end_doy)
    } else if (end_doy > 366) {
      # Need to look forward into first days of the year
      seq_doy <- c(begin_doy:366, 1:(end_doy - 366))
    } else {
      seq_doy <- begin_doy:end_doy
    }
    
    # Filter giant dataset to just those with the right days
    values_to_calc_df <- filter(df, DOY %in% seq_doy)
    doy_quantiles <- quantile(values_to_calc_df[[hruid]],
                              probs = c(0, 0.10, 0.25, 0.75, 0.90, 1))
    
    return(list(doy_quantiles))
  }
  
  hru_quantiles <- total_storage_df %>%
    rowwise() %>%
    mutate(DOY_Quantiles = get_quantiles_doy(DOY, total_storage_df, hruid)) %>%
    select(DOY, DOY_Quantiles) %>%
    unique() %>%
    ungroup()
  
  # Rename the second column (which is always "DOY_QUANTILES" based on the select above)
  names(hru_quantiles)[2] <- hruid
  
  return(hru_quantiles)
}

message(sprintf("Started task at %s", Sys.time()))

# Identify task id from yeti environment & convert to HRU ids ----
task_id <- as.numeric(Sys.getenv('SLURM_ARRAY_TASK_ID', 'NA'))

# Convert task id to HRU ids (increment by n_hrus_per_task)
n_hrus_per_task <- 1100
hru_id_start <- ((task_id-1)*n_hrus_per_task + 1) # tells you which HRU
hru_id_end <- hru_id_start + (n_hrus_per_task-1) # gives location of final col

# If we are past the last column, cut the final col id off
n_hrus <- 109951
hru_id_end <- ifelse(hru_id_end > n_hrus,
                     yes = n_hrus,
                     no = hru_id_end)

message(sprintf("Task %s", task_id))
message(sprintf("starting with %s and ending with %s", hru_id_start, hru_id_end))

hrus_to_loop_through <- hru_id_start:hru_id_end

# For each HRU, calculate the percentiles and save a file ----
hru_quantile_list <- lapply(hrus_to_loop_through, function(hruid) {
  hruid <- as.character(hruid)
  total_storage_df <- combine_vars_to_total_storage_df(hruid)
  hru_quantile_df <- calcuate_percentiles(total_storage_df, hruid)
  
  # Need to save inside this so that they don't run out of memory.
  message(sprintf("Saving the percentile df, %s", Sys.time()))
  saveRDS(hru_quantile_df, sprintf("quantiles_by_hru/total_storage_quantiles_%s.rds", hruid))
  return(hru_quantile_df)
})

message(sprintf("Completed task at %s", Sys.time()))
