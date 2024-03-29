# Code for total storage daily build

library(ncdf4)
library(dplyr)

args <- commandArgs(trailingOnly=TRUE)
today <- args[1] #today <- "2019-10-31"
validate_data <- args[2] == "yes" # defaults to 'yes'

# Remove the file if it exists in the workspace before checks begin
#   to avoid any contamination from older jobs
validate_fn <- paste0("order_of_magnitude_test_",today,".html")
if(validate_data & file.exists(validate_fn)) {
  file.remove(validate_fn)
}

source("src/validate_oNHM_daily_output.R") # load code to test model data
source("src/validate_total_storage_categorized.R") # load code to test output of this categorization

# Combine nc files for each var
vars <- c("soil_moist_tot", "hru_intcpstor", "pkwater_equiv",
          "hru_impervstor", "gwres_stor", "dprst_stor_hru")

write(x = sprintf("<html><head><title>oNHM daily model output test result report for %s</title><link rel='stylesheet' href='styles.css'></head><body><br /><h1>oNHM daily model output test result report for %s</h1><br/><br/><div class='left'>", today, today), 
      file = validate_fn)

var_data_list <- lapply(vars, function(var) {
  fn <- sprintf("%s_%s.nc", today, var)
  nc <- nc_open(fn)
  time <- ncvar_get(nc, varid = "time")
  hruids <- ncvar_get(nc, varid = "hruid")

  # Convert ncdf4 times to R dates
  time_att <- ncdf4::ncatt_get(nc, "time")
  time_start <- as.Date(gsub("days since ", "", time_att$units))
  time_fixed <- time + time_start # creates dates from the "days since" var

  today_dim <- which(time_fixed == today)
  today_data_nc <- ncvar_get(nc, var, start = c(1,today_dim), count = c(-1, 1))

  # Run tests before returning any data
  if(validate_data) {
    message(sprintf("Started tests for %s", var))
    validate_oNHM_daily_output(var, fn, today, today_data_nc, hruids, time, time_fixed, validate_fn)
    message(sprintf("Completed tests for %s", var))
  }
  
  today_var_data <- data.frame(
    hruid = as.numeric(hruids),
    var_values = today_data_nc,
    DOY = as.numeric(format(as.Date(today), "%j"))
  )

  return(today_var_data)
})

var_data_all <- bind_rows(var_data_list)
total_storage_data <- var_data_all %>%
  group_by(hruid,DOY) %>%
  summarize(total_storage_today = sum(var_values))

# Read in quantile data -- this df is pretty big
quantile_df <- readRDS("all_quantiles.rds") %>% 
  filter(DOY == lubridate::yday(today)) %>%
  rename(hruid = nhru)

get_nonzero_duplicate_indices <- function(x) {
  zeros <- x == 0
  dups <- duplicated(x, fromLast = TRUE)
  !zeros & dups 
}

find_value_category <- function(value, labels, ...) {
  breaks <- as.numeric(list(...))
  
  # First, make sure actual breaks exist
  if(all(is.na(breaks))) {
    final_label <- "Undefined"
  } else {
  
    # then, check if there are non-zero duplicate quantiles
    dup_indices <- get_nonzero_duplicate_indices(breaks)
    if(any(dup_indices)) {
      breaks <- breaks[!dup_indices]
      labels <- labels[-which(dup_indices)]
    } 
    #if all zeros, mark as undefined, need check for NA in case >2 quantiles are the same
    if(value == 0 && sum(breaks[2:5], na.rm = TRUE) == 0) {
      final_label <- "Undefined"
    } else if(value == 0 && sum(breaks == 0) > 0){ 
      #if only some are zeros and value is zero, use highest zero tier
      high_zero_index <- max(which(breaks == 0))
      if(high_zero_index >= 3) {
        final_label <- labels[3]
      } else {
        final_label <- labels[high_zero_index]
      } 
    } else if(value > 0 && sum(breaks == 0) > 0) {
      high_zero_index <- max(which(breaks == 0))
      breaks <- breaks[high_zero_index:length(breaks)]
      labels <- labels[high_zero_index:length(labels)]
      final_label <- cut(value, breaks, labels, include.lowest = TRUE)
    } else {
      final_label <- cut(value, breaks, labels, include.lowest = TRUE)
    }
  }
  
  final_label <- as.character(final_label)
  return(final_label)
}

percentile_categories <- c("very low", "low", "average", "high", "very high")

values_categorized <- total_storage_data %>%
  left_join(quantile_df, by = c("hruid","DOY")) %>%
  rowwise() %>% 
  mutate(value = find_value_category(value = total_storage_today, 
                                     labels = percentile_categories,
                                     `0%`, `10%`, `25%`, `75%`, `90%`, `100%`)) %>%
  rename(hru_id_nat = hruid)

if(validate_data) {
  message("Started tests for validating categorized output")
  validate_total_storage_categorized(values_categorized, validate_fn)
  message("Completed tests for validating categorized output")
}

write(x = sprintf("</div></body></html>"), 
      file = validate_fn,
      append = TRUE)

readr::write_csv(values_categorized, "model_output_categorized.csv")
