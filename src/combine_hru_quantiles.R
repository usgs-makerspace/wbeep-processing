# Combine the resulting files from the parallel tasks in
# process_quantiles_by_hru.R into one file and push to S3.
library(dplyr)
library(tidyr)
library(pryr)
ptm <- proc.time()
files_to_combine <- list.files(path = "src/quantiles_by_hru", 
                               pattern = "total_storage_quantiles",
                               full.names = TRUE)
#gets daily data
file_contents_list <- lapply(files_to_combine, readRDS)
print(proc.time() - ptm)
ptm <- proc.time()
print(pryr::object_size(file_contents_list))
#check order of all  DOY columns by doing a logical compare
#could throw in an arrange here 
sample <- file_contents_list[[1]]$DOY
checks <- sapply(X = file_contents_list, 
                 FUN = function(x, sample) {all(x$DOY == sample)},
                 sample = sample)
print(proc.time() - ptm)
ptm <- proc.time()
stopifnot(all(checks))

combined_data <- do.call("bind_cols", file_contents_list) %>%  
  select(DOY, matches('^[0-9]*$')) %>% 
  pivot_longer(cols = -DOY, names_to = "hruid",
               values_to = "total_storage_quantiles")
print(pryr::object_size(combined_data))
print(proc.time() - ptm)

combined_data_unnested <- combined_data %>%
  dplyr::mutate(total_storage_quantiles=purrr::map(total_storage_quantiles, setNames, c("0%","10%","25%","75%","90%", "100%"))) %>%
  unnest_wider(total_storage_quantiles)

saveRDS(combined_data_unnested, "all_quantiles.rds")
## manually push RDS file to S3
