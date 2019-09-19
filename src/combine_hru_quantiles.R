# Combine the resulting files from the parallel tasks in
# process_quantiles_by_hru.R into one file and push to S3.

library(dplyr)
library(purrr) # needed for `reduce`
library(tidyr)

files_to_combine <- list.files(path = "quantiles_by_hru", 
                               pattern = "total_storage_quantiles",
                               full.names = TRUE)
list_of_files <- lapply(files_to_combine, readRDS)
combined_data <- reduce(list_of_files, left_join)
combined_data_reformatted <- gather(combined_data, key = hruid, value = total_storage_quantiles, -DOY)

saveRDS(combined_data_reformatted, "all_quantiles.rds")
## manually push RDS file to S3
