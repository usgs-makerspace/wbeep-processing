library(ncdf4)
args <- commandArgs(trailingOnly=TRUE)
today <- args[1]
nc <- nc_open(paste0('climate_', today, ".nc"))
hru_ids <- ncvar_get(nc, varid = "hruid")
#could verify time axis matches expected date
#generate random labels for now
#actual metric computation happens here eventually
categories <- rep(c("low", "medium", "high"), length.out = length(hru_ids))
data_vals <- dplyr::tibble(hru_id_nat = hru_ids, 
                    value = categories)
readr::write_csv(data_vals, "model_output_categorized.csv")


