# Combine the resulting files from the parallel tasks in
# process_quantiles_by_hru.R into one file and push to S3.

library(dplyr)
library(purrr) # needed for `reduce`
library(tidyr)


files <- list.files(path = "src/quantiles_by_hru", pattern = "total_storage_quantiles", full.names = TRUE)
stack <- do.call("bind_rows", lapply(files, readRDS))
combined_data_reformatted <- gather(stack, key = hruid, value = total_storage_quantiles, -DOY)

saveRDS(combined_data_reformatted, "all_quantiles.rds")
## manually push RDS file to S3
