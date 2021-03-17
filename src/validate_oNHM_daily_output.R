library(assertthat)
library(ncmeta)

validate_oNHM_daily_output <- function(var, fn, test_date, data_nc, hruids, time, 
                                       time_fixed, validate_fn, n_hrus = 114958) {
  
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
    message("DATA = GOOD")
    # Write out a text file that won't have Jenkins send an email.
    # Add information about the current var to the file.
    write(x = sprintf("%s data:\nNo values above 10,000", var), 
          file = validate_fn,
          append = TRUE)
  } else {
    message("DATA = BAD")
    # Write out a text file that will eventually cause the Jenkins file to send an email
    # Add information about the current var to the file.
    bad_data_hruids <- hruids[which(data_nc >= 10000)]
    message("The following HRUIDs have problematic data >= 10,000: ", 
            var," \n", paste(bad_data_hruids, collapse = "\n"))
    write(x = sprintf("The following HRUIDs have %s data >= 10,000: %s", 
                      var, paste(bad_data_hruids, collapse = ", ")), 
          file = validate_fn,
          append = TRUE)
  }
  
  # Compare today's data against variable-specific quantiles
  # Read in variable's historic quantile data -- keep only hruid and 95% column to calculate max value for comparison
  # Make sure to order by hruid so when we add today's data its in the right order
  filename <- paste0(var,"_quantiles.rds")
  var_quantile_df <- readRDS(filename) %>%
    filter(DOY == lubridate::yday(today)) %>%
    rename(hruid = nhru) %>%
    arrange(hruid) %>%
    select(hruid,`95%`) %>%
    
  # add max value for comparison 150% of the max value/90th value
    mutate(max_value =`95%`*1.5) %>%
    mutate(today = data_nc)
  
  # keep table of data to share
  higher_than_max <- var_quantile_df %>%
    filter(today > max_value)
  
  message("There were ", nrow(higher_than_max)," values above max expected for ", var, ".")
  write(x = sprintf("There were %s values above max expected for %s.",nrow(higher_than_max), var), 
        file = validate_fn,
        append = TRUE)
  write.csv(higher_than_max,paste0(var,"_higher_than_max_",today,".csv"), row.names = FALSE)
  
  # compare with table of max values for each hru, irregardless of day of year
  var_max_hru <- read.csv(paste0("max_",var,".csv")) %>%
    mutate(today = data_nc)
  
  higher_than_ever <- var_max_hru %>%
    filter(today > max_value)
  
  message("There were ", nrow(higher_than_ever)," values above their highest max for ", var, ".")
  write(x = sprintf("There were %s values above their highest max for %s.\n",nrow(higher_than_ever), var), 
        file = validate_fn,
        append = TRUE)
  write.csv(higher_than_ever,paste0(var,"_higher_than_ever_",today,".csv"), row.names = FALSE)
}
