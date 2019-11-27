library(assertthat)
library(ncmeta)

validate_oNHM_daily_output <- function(var, fn, test_date, data_nc, hruids, time, time_fixed, n_hrus = 109951) {
  
  ##### Test: NetCDF dimensions and variables are as expected #####
  
  # Get a bit more detailed metadata
  meta_info <- nc_meta(fn)
  
  assert_that(meta_info$dimension$name[1] == "hruid")
  assert_that(meta_info$dimension$name[2] == "time")
  assert_that(meta_info$dimension$length[1] == n_hrus) # Expect all hruids
  assert_that(meta_info$dimension$length[2] == 1) # Expect only one date
  
  # Test unit for variable
  units_att_list <- nc_att(fn, var, "units")[["value"]]
  assert_that(unlist(units_att_list) == "mm") # Expect millimeters
  
  ##### Test: NetCDF hruids are in expected order and the expected data type #####
  assert_that(is.integer(hruids))
  # need to make hruids a vector instead of matrix w 1 dim in order to test sameness
  assert_that(all(as.vector(hruids) == 1:n_hrus)) 
  
  ##### Test: NetCDF time is in expected order and expected data type #####
  assert_that(is.integer(time))
  assert_that(length(time) == 1) # Expect only 1 day of data 
  assert_that(as.character(time_fixed) == test_date) # Expect that day to match the current date
  
  ##### Test: NetCDF actual data is formatted as expected #####
  assert_that(is.double(data_nc))
  assert_that(dim(data_nc) == n_hrus) 
  
  # General order of magnitude test
  # Max of total storage in all of historic data for all HRUs is ~8,000 mm
  # Considering 300 mm is about 1 ft of water
  # An absolute max for order of magnitude check of 10,000 mm seems appropriate
  data_is_good <- all(data_nc < 10000)
  if(data_is_good) {
    # Write out a text file that won't have Jenkins send an email.
    writeLines("NULL", "order_of_magnitude_test.txt")
  } else {
    # Write out a text file that will eventually cause the Jenkins file to send an email
    bad_data_hruids <- hruids[which(data_nc >= 10000)]
    writeLines(text = sprintf("The following HRUIDs have data >= 10,000: %s", 
                              paste(bad_data_hruids, collapse = ", ")), 
               con = "order_of_magnitude_test.txt")
  }
  
}
