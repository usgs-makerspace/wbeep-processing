library(ncdf4)
args <- commandArgs(trailingOnly=TRUE)
today <- args[1]
nc <- nc_open(paste0('climate_', today, ".nc"))
hru_ids <- ncvar_get(nc, varid = "hruid")
#could verify time axis matches expected date
#generate random labels for now
#actual metric computation happens here eventually
vals <- ncvar_get(nc, varid = "prcp")[,1]
vals_without_zeros <- vals[vals != 0]
percentiles <- quantile(vals_without_zeros, probs = c(0.10, 0.30, 0.70, 0.90, 1))
percentiles <- c(0, percentiles)
categories <- c("very low", "low", "medium", "high", "very high")
vals_categorized <- cut(vals, breaks = percentiles, labels = categories, include.lowest = TRUE)
data_vals <- dplyr::tibble(hru_id_nat = hru_ids, 
                           value = as.character(vals_categorized))
readr::write_csv(data_vals, "model_output_categorized.csv")
