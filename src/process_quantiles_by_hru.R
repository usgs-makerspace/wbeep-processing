library(data.table)
library(dplyr)
library(purrr) # needed for `reduce`

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

# Function to calculate the percentiles associated with a set of HRUs ----
calcuate_percentiles_by_hru <- function() {
  
  # Read in data that has all data for all HRUs
  # This is going to be a massive file.
  message("Reading in data for all HRUs.")
  variable_df <- readRDS("combined_vars.rds")
  
  #from yeti environment
  task_id <- as.numeric(Sys.getenv('SLURM_ARRAY_TASK_ID', 'NA'))
  
  # Convert task id to column numbers (increment by 25 & add one for Date col)
  hru_id_start <- ((task_id-1)*25 + 1) # tells you which HRU
  col_id_start <- hru_id_start + 1 # adds one for the date column
  col_id_end <- col_id_start + 24 # gives location of final col
  # If we are past the last column, cut the final col id off
  col_id_end <- ifelse(col_id_end > ncol(variable_df),
                       yes = ncol(variable_df),
                       no = col_id_end)

  # Isolate data for single HRU
  columns_to_select <- c(1, col_id_start:col_id_end)
  task_df <- variable_df[, .SD, .SDcols = columns_to_select]

  # Sum rows to get the "total storage" value for each day
  total_storage_task_df <- task_df[, lapply(.SD, sum), by = Date]

  # Add column with numeric DOY
  total_storage_task_df[, DOY := as.numeric(format(Date, "%j"))]

  # Calculate quantiles for each DOY using a moving window
  # centered at the current DOY for each HRU column
  message("Calculating quantiles for each HRU in this set.")
  hrus <- names(total_storage_task_df)[-grep("DOY|Date", names(total_storage_task_df))]
  hru_quantile_list <- lapply(hrus, function(hru_id) {

    # Subset to just Date and this HRUs column
    hru_df <- select(total_storage_task_df, Date, DOY, matches(hru_id))

    # doy = current day of year as number
    # df = data frame with all data, assumes cols DOY and
    # window = number of days to look behind and ahead of the current doy
    get_quantiles_doy <- function(doy, df, hru_id, window = 5) {

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
      doy_quantiles <- quantile(values_to_calc_df[[hru_id]],
                                probs = c(0, 0.10, 0.25, 0.75, 0.90, 1))

      return(list(doy_quantiles))
    }

    hru_quantiles <- hru_df %>%
      rowwise() %>%
      mutate(DOY_Quantiles = get_quantiles_doy(DOY, hru_df, hru_id)) %>%
      select(DOY, DOY_Quantiles) %>%
      unique() %>%
      ungroup()

    # Rename the second column (which is always "DOY_QUANTILES" based on the select above)
    names(hru_quantiles)[2] <- hru_id

    return(hru_quantiles)
  })

  # Combine data frames of HRU quantiles into one by joining on DOY
  total_storage_quantiles <- hru_quantile_list %>%
    reduce(left_join, by = "DOY")

  saveRDS(total_storage_quantiles,
          sprintf("quantiles_by_task/total_storage_quantiles_%s.rds",
                  task_id))
  return(total_storage_quantiles)
}
