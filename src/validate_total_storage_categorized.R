library(assertthat)

validate_total_storage_categorized <- function(data_categorized, validate_fn, n_hrus = 114958) {
  
  write(x = sprintf("<h2>Validating the total storage categorization</h2>"),
        file = validate_fn,
        append = TRUE)
  
  ##### Test: Key columns exist in the data #####
  
  if (assert_that("hru_id_nat" %in% names(data_categorized)) && assert_that("value" %in% names(data_categorized))) {
    write(x = sprintf("<img src='icon-check.png' alt='test passed'> Key columns exist in the data <br />"), 
          file = validate_fn,
          append = TRUE)
  }
  ##### Test: All HRUs are in the data and in the right order #####
  
  if (assert_that(nrow(data_categorized) == n_hrus) && assert_that(all(data_categorized$hru_id_nat == 1:n_hrus))) {
    write(x = sprintf("<img src='icon-check.png' alt='test passed'> All HRUs are in the data and in the right order <br />"), 
          file = validate_fn,
          append = TRUE)
  }
  ##### Test: Only expected categories exist in the value column #####
  
  # In case we are missing historic data for quantiles their daily data will be Undefined
  problem_hruids <- c(12099, 12107, 12108, 12692, 12731, 40871, 40880, 40882, 40956, 40957, 40971, 40979, 40983, 43167, 43168, 43171, 43172, 77834, 89590, 104167, 104168, 104173, 107629, 107649)
  data_categorized_problem_hru <- data_categorized[data_categorized$hru_id_nat %in% problem_hruids,]
  data_categorized_good_hrus <- data_categorized[!data_categorized$hru_id_nat %in% problem_hruids,]
  
  if (assert_that(is.character(data_categorized$value))) {
    write(x = sprintf("<img src='icon-check.png' alt='test passed'> Category data are in the expected character format.<br />"), 
          file = validate_fn,
          append = TRUE)
  }
  # Use validate_that instead of assert_that so we get a warning instead of an error
  validate_that(all(data_categorized_problem_hru$value == "Undefined"), msg = "Expecting all Undefined categorization, other value found.")
  validate_that(!"Undefined" %in% unique(data_categorized_good_hrus$value), msg = "Expecting all properly categorized data, Undefined found")
  all_new_problem_hrus <- values_categorized[which(values_categorized$value=='Undefined'),]
  all_undefined_hrus <- all_new_problem_hrus$hru_id_nat
  newest_problem_hrus <- all_undefined_hrus[!all_new_problem_hrus %in% problem_hruids]
  
  if (length(newest_problem_hrus)>0) {
    write(x = sprintf("<img src='icon-x.png' alt='test failed - warning'> There are unexpected/new HRUs with the categorization of Undefined. <br />"), 
        file = validate_fn,
        append = TRUE)
    write(x=sprintf("<img src='icon-x.png' alt='test failed - warning'> We have new problem HRUs for today, unexpected/new Undefined categorization for the following HRUs: %s <br />", newest_problem_hrus),
        file = validate_fn,
        append = TRUE)
    maptitle <- paste0("new_undefined_",today,".png")
    validate_oNHM_maps(newest_problem_hrus, maptitle, "new problem/undefined HRUs for today")
    write(x = sprintf("<a href='%s' target='_blank'><img src='%s' alt='map showing hrus that have an unexpected/new categorization of Undefined'></a><br />", maptitle, maptitle), 
        file = validate_fn,
        append = TRUE)
  } else {
    write(x = sprintf("<img src='icon-check.png' alt='test passed'> All HRUs categorized as problems are correctly categorized as Undefined and no new/unexpected Undefined values have been found. <br />"),
          file = validate_fn,
          append = TRUE)
  }
}
