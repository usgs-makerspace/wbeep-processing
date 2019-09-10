
# Combine the resulting files from the parallel tasks in
# process_quantiles_by_hru.R into one file and push to S3.

files_to_combine <- list.files(pattern = "total_storage_quantiles")
list_of_files <- lapply(files_to_combine, readRDS)
combined_data <- reduce(left_join, list_of_files)

## [code to push to S3 goes here]
