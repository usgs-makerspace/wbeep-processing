library(assertthat)

validate_historic_quantile_data <- function(quantile_data, n_hrus = 114958, n_days = 365) {
  
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
  
  # We used to have problem hruids that produced bad quantiles. With the Sep 2020 update,
  # that no longer seems to be an issue. Leaving this functionality here in case
  # some do come to light in the future. 
  problem_hruids <- c() # HRUIDs with bad quantiles as numberic values
  real_cols <- percentile_cols[!percentile_cols %in% c("0%", "100%")]
  quantiles_problem_hru <- unlist(quantile_data[quantile_data$hruid %in% problem_hruids, real_cols, with=FALSE], use.names=F)
  quantiles_good_hrus <- unlist(quantile_data[!quantile_data$hruid %in% problem_hruids, real_cols, with=FALSE], use.names=F)
  assert_that(all(quantiles_problem_hru == 0)) # Every quantile will be 0 for these bad HRUs
  assert_that(any(quantiles_good_hrus > 0)) # There will be some that are greater than zero
  
  ##### Test: General order of magnitude #####
  
  # Max of total storage in all of historic total storage data for all HRUs is ~8,000 mm
  # Considering 300 mm is about 1 ft of water (diff between historic max and assumed max is ~ 6.5 ft of water)
  # An absolute max for order of magnitude check of 10,000 mm seems appropriate
  just_quantile_data <- as.matrix(quantile_data[,real_cols, with=FALSE])
  assert_that(max(just_quantile_data) < 10000) 
  
}
