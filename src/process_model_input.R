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

library(data.table)
library(dplyr)

# Location for where HRU quantile rds files should be stored 
file_location <- "" # needs to include ending `/`

#################################################################
# Might want to break this into two separate steps - 
#   1) Create combined dataset for all HRUs for all variables (read_period_of_record_data + combine_variables_to_one_df)
#   2) for each HRU, sum totS, calc quantiles (parallel using calcuate_percentiles_by_hru)
# OR
#   1) Create combined dataset for all HRUs for all variables & sum totS (parallel?)
#   2) for each HRU, calc quantiles (parallel)
#################################################################


##### Functions to do the work

read_period_of_record_data <- function(fn) {
  
  data <- fread(fn, header=TRUE)
  data[, Date := as.Date(Date)]
  
  #### Delete this section for the real deal
  # For now, just play with 1 year:
  data[, Year := as.numeric(format(Date, "%Y"))]
  max_year <- max(data$Year)
  data_one_yr <- data[Year >= (max_year-1) ]
  data_one_yr[, Year := NULL]
  data <- data_one_yr
  ####
  
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

calcuate_percentiles_by_hru <- function(task_id, variable_df) {
  
  # Isolate data for single HRU
  columns_to_select <- c(1, (task_id+1))
  task_df <- variable_df[, .SD, .SDcols = columns_to_select]
  
  # Rename column of HRU to use later (it's always the second column)
  current_hru <- names(task_df)[2]
  names(task_df)[2] <- "Current_HRU_Vals"
  
  # Sum rows to get the "total storage" value for each day
  total_storage_task_df <- task_df[, lapply(.SD, sum), by = Date]
  
  # Now calculate quantiles for each DOY using a moving window
  # centered at the current DOY
  
  total_storage_task_df[, DOY := as.numeric(format(Date, "%j"))] 
  
  # doy = current day of year as number
  # df = data frame with all data, assumes cols DOY and 
  # window = number of days to look behind and ahead of the current doy
  get_quantiles_doy <- function(doy, df, window = 5) {
    
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
    doy_quantiles <- quantile(values_to_calc_df$Current_HRU_Vals, 
                              probs = c(0, 0.10, 0.25, 0.75, 0.90, 1))
    
    return(list(doy_quantiles))
  }
  
  total_storage_quantiles <- total_storage_task_df %>% 
    rowwise() %>% 
    mutate(DOY_Quantiles = get_quantiles_doy(DOY, total_storage_task_df)) %>% 
    select(DOY, DOY_Quantiles) %>% 
    unique()
  
  saveRDS(total_storage_quantiles, 
          sprintf("%stotal_storage_quantiles_%s.rds", 
                  file_location, 
                  current_hru))
  return(total_storage_quantiles)
}

##### Execute commands

# Read the data sources ----

pkwater_equiv <- read_period_of_record_data("nhru_pkwater_equiv.csv")
soil_moist_tot <- read_period_of_record_data("nhru_soil_moist_tot.csv")
#hru_intcpstor <- read_period_of_record_data("nhru_hru_intcpstor.csv")
#hru_impervstor <- read_period_of_record_data("nhru_hru_impervstor.csv")
#gwres_stor <- read_period_of_record_data("nhru_gwres_stor.csv")
#dprst_stor <- read_period_of_record_data("nhru_dprst_stor_hru.csv")

# Combine data sources into a single list ----

variable_df_list <- list(
  pkwater_equiv = pkwater_equiv,
  soil_moist_tot = soil_moist_tot#,
  #hru_intcpstor = hru_intcpstor,
  #hru_impervstor = hru_impervstor,
  #gwres_stor = gwres_stor,
  #dprst_stor = dprst_stor
)

# Combine all variables into one df ----

# This step takes ~30 min
variable_df <- combine_variables_to_one_df(variable_df_list)

# Now code for only one HRU at time:
# "task_id" will be by column, but adding 1 since the date column is first

####
# For testing purposes, delete when done

task_id <- 90

# Calculate the percentiles associated with one HRU ----

task_quantile_df <- calcuate_percentiles_by_hru(task_id, variable_df)

####
