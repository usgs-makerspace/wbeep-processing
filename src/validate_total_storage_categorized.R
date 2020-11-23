library(assertthat)

validate_total_storage_categorized <- function(data_categorized, n_hrus = 114958) {
  
  ##### Test: Key columns exist in the data #####
  
  assert_that("hru_id_nat" %in% names(data_categorized))
  assert_that("value" %in% names(data_categorized))
  
  ##### Test: All HRUs are in the data and in the right order #####
  
  assert_that(nrow(data_categorized) == n_hrus)
  assert_that(all(data_categorized$hru_id_nat == 1:n_hrus))
  
  ##### Test: Only expected categories exist in the value column #####
  
  # We know that one CA HRU doesn't have historic data for quantiles (104388) and will be Undefined
  # This is also true for 7 other HRUs that are not in the U.S.
  #problem_hruids <- c(104388, 46760, 46766, 46767, 82924, 82971, 82983, 82984)
  #data_categorized_problem_hru <- data_categorized[data_categorized$nhru %in% problem_hruids,]
  #data_categorized_good_hrus <- data_categorized[!data_categorized$nhru %in% problem_hruids,]
  
  assert_that(is.character(data_categorized$value))
  #assert_that(all(data_categorized_problem_hru$value == "Undefined"))
  #assert_that(!"Undefined" %in% unique(data_categorized_good_hrus$value))
  
}
