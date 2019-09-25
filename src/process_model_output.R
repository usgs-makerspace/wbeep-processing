library(ncdf4)
library(dplyr)
library(tidyverse)

args <- commandArgs(trailingOnly=TRUE)
today <- args[1]
todayUnderscores <- gsub("-","_",today)

#### Code for total storage daily build
#This section is code for what I think will replace the precip code when the percentile code is complete.
# test for now b/c of the data we have

today <- "2019-07-31"

# Combine nc files for each var
vars <- c("soil_moist_tot", "pkwater_equiv", "hru_intcpstor",
          "hru_impervstor", "gwres_stor", "dprst_stor_hru")

var_data_list <- lapply(vars, function(var) {
  nc <- nc_open(sprintf("%s_%s_out.nc", todayUnderscores, var))
  time <- ncvar_get(nc, varid = "time")
  hruids <- ncvar_get(nc, varid = "hruid")

  # Convert ncdf4 times to R dates
  time_att <- ncdf4::ncatt_get(nc, "time")
  time_start <- as.Date(gsub("days since ", "", time_att$units))
  time_fixed <- time + time_start # creates dates from the "days since" var

  today_dim <- which(time_fixed == today)
  today_data_nc <- ncvar_get(nc, var, start = c(1,today_dim), count = c(-1, 1))

  today_var_data <- data.frame(
    hruid = as.character(hruids),
    var_values = today_data_nc,
    DOY = as.numeric(format(as.Date(today), "%j"))
  )

  return(today_var_data)
})

var_data_all <- bind_rows(var_data_list)
total_storage_data <- var_data_all %>%
  group_by(hruid) %>%
  summarize(total_storage_today = sum(var_values))

# Read in quantile data
quantile_df <- readRDS("all_quantiles.rds")

quantile_df %>% 
  dplyr::mutate(total_storage_quantiles=purrr::map(total_storage_quantiles, setNames, c("0%","10%","25%","75%","90%", "100%"))) %>% 
  unnest_wider(total_storage_quantiles)

# Join quantiles to values by hruid
# mutate a column to get category
find_quantile_group <- function(value, breaks, labels) {
  cut(value, unique(breaks), unique(labels)[-1], include.lowest = TRUE)
}

percentile_categories <- c("very low", "low", "average", "high", "very high")
values_categorized <- total_storage_data %>%
  left_join(quantile_df, by = c("hruid")) %>%
  mutate(map_cat = find_quantile_group(total_storage_today, total_storage_quantiles, percentile_categories)) %>%
  select(hru_id_nat = hruid,
         value = as.character(map_cat))

readr::write_csv(values_categorized, "model_output_categorized.csv")

nc <- nc_open(paste0('climate_', todayUnderscores, ".nc"))
hru_ids <- ncvar_get(nc, varid = "hruid")
#could verify time axis matches expected date
#generate random labels for now
#actual metric computation happens here eventually
vals <- ncvar_get(nc, varid = "prcp")
vals_without_zeros <- vals[vals != 0]
percentiles <- quantile(vals_without_zeros, probs = c(0.10, 0.30, 0.70, 0.90, 1))
percentiles <- c(0, percentiles)
categories <- c("very low", "low", "medium", "high", "very high")
vals_categorized <- cut(vals, breaks = percentiles, labels = categories, include.lowest = TRUE)
data_vals <- dplyr::tibble(hru_id_nat = hru_ids, 
                           value = as.character(vals_categorized))
readr::write_csv(data_vals, "model_output_categorized.csv")
