library(assertthat)

### DELETE WHEN DONE ###
combined_data <- readRDS("all_quantiles.rds")
quantile_data <- combined_data
### /////////////// ###

validate_historic_quantile_data <- function(quantile_data, n_hrus = 109951, n_days = 365) {
  
  # n_days at 365 until leap years are dealt with
  
  ##### Test: dimensions are as expected #####
  percentile_cols <- names(quantile_data)[grepl("%", names(quantile_data))]
  assert_that(nrow(quantile_data) == n_hrus*n_days) # There is one row of data per HRU per day of year
  assert_that("hruid" %in% names(quantile_data)) # must have hruid col
  assert_that("DOY" %in% names(quantile_data)) # must have DOY col
  assert_that(all(names(quantile_data) %in% c("hruid", "DOY", percentile_cols))) # Test that there are no extra columns
  
  ##### Test: percentile columns are within appropriate bounds #####
  percentile_vals <- as.numeric(gsub("%", "", percentile_cols))
  assert_that(all(percentile_vals >= 0 & percentile_vals <= 100))
  
  ##### Test: boundaries of categories #####
  assert_that(all(quantile_data[["0%"]] == -Inf))
  assert_that(all(quantile_data[["100%"]] == Inf))
  
  ##### Test: HRUs with missing quantile data #####
  
  # We know that one CA HRU doesn't have historic data for quantiles (104388) and will be Undefined
  # This is also true for 7 other HRUs that are not in the U.S.
  problem_hruids <- c(104388, 46760, 46766, 46767, 82924, 82971, 82983, 82984)
  quantiles_problem_hru <- unlist(quantile_data[quantile_data$hruid %in% problem_hruids,], use.names=FALSE)
  quantiles_good_hrus <- quantile_data[!quantile_data$hruid %in% problem_hruids,]

  ####### THIS IS NOT AS EXPECTED  ####### 
  assert_that(any(is.na(quantiles_problem_hru)))
  assert_that(!"Undefined" %in% unique(data_categorized_good_hrus$value))
  
  # General order of magnitude test
  # Max of total storage in all of historic total storage data for all HRUs is ~8,000 mm
  # Considering 300 mm is about 1 ft of water (diff between historic max and assumed max is ~ 6.5 ft of water)
  # An absolute max for order of magnitude check of 10,000 mm seems appropriate
  real_cols <- names(quantile_data)[!names(quantile_data) %in% c("0%", "100%")]
  just_quantile_data <- as.matrix(quantile_data[,grep("%", real_cols)])
  assert_that(max(just_quantile_data) < 10000) 
  
}
