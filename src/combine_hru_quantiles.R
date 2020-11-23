# Combine the resulting files from the parallel tasks in
# process_quantiles_by_hru.R into one file and push to S3.

library(data.table)
source("src/validate_historic_quantile_data.R") # load code to test model data

files_to_combine <- list.files(path = "grouped_quantiles", 
                               pattern = "total_storage_quantiles",
                               full.names = TRUE)

#gets daily data
message("Read in each HRU group of quantiles file to a list")
file_contents_list <- lapply(files_to_combine, feather::read_feather)

message("Turn each HRU group of quantiles from list into single dataset")
combined_data <- do.call("rbind", file_contents_list) 

# Add -inf and +inf here since it will be the same for all 
message("Fix quantiles to add 0% and 100%")
original_quantiles <- tail(names(combined_data), -2)
combined_data <- as.data.table(combined_data)
combined_data[, "0%" := -Inf]
combined_data[, "100%" := Inf]
setcolorder(combined_data, c("hruid", "DOY", "0%",
                             original_quantiles,
                             "100%"))

# Validate that outgoing quantiles are as expected
message("Started tests for validating calcalated quantiles")
validate_historic_quantile_data(combined_data)
message("Completed tests for validating calcalated quantiles")

message("Save quantiles `as all_quantiles.rds`")
saveRDS(combined_data, "all_quantiles.rds")
## manually push RDS file to S3
