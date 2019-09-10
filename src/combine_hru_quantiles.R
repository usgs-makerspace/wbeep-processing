# Combine the resulting files from the parallel tasks in
# process_quantiles_by_hru.R into one file and push to S3.

library(dplyr)
library(purrr) # needed for `reduce`

files_to_combine <- list.files(path = "quantiles_by_task", 
                               pattern = "total_storage_quantiles",
                               full.names = TRUE)
list_of_files <- lapply(files_to_combine, readRDS)
combined_data <- reduce(list_of_files, left_join)

saveRDS(combined_data, "all_quantiles.rds")
## [code to push to S3 goes here]
