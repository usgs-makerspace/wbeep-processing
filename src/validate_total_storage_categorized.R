library(assertthat)

validate_total_storage_categorized <- function(data_categorized, n_hrus = 114958) {
  
  ##### Test: Key columns exist in the data #####
  
  assert_that("hru_id_nat" %in% names(data_categorized))
  assert_that("value" %in% names(data_categorized))
  
  ##### Test: All HRUs are in the data and in the right order #####
  
  assert_that(nrow(data_categorized) == n_hrus)
  assert_that(all(data_categorized$hru_id_nat == 1:n_hrus))
  
  ##### Test: Only expected categories exist in the value column #####
  
  # In case we are missing historic data for quantiles their daily data will be Undefined
  problem_hruids <- c(12099, 12107, 12108, 12692, 12731, 40871, 40880, 40882, 40956, 40957, 40971, 40979, 40983, 43167, 43168, 43171, 43172, 77834, 89590, 104167, 104168, 104173, 107629, 107649)
  data_categorized_problem_hru <- data_categorized[data_categorized$hru_id_nat %in% problem_hruids,]
  data_categorized_good_hrus <- data_categorized[!data_categorized$hru_id_nat %in% problem_hruids,]
  
  assert_that(is.character(data_categorized$value))
  assert_that(all(data_categorized_problem_hru$value == "Undefined"))
  assert_that(!"Undefined" %in% unique(data_categorized_good_hrus$value))
  
}
