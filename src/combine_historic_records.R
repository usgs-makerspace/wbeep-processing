library(data.table)
library(dplyr)

read_period_of_record_data <- function(fn) {
  
  data <- fread(fn, header=TRUE)
  data[, Date := as.Date(Date)]
  
  #### Delete this section for the real deal
  # For now, just play with 1 year:
  data[, Year := as.numeric(format(Date, "%Y"))]
  max_year <- max(data$Year)
  data_one_yr <- data[Year >= (max_year-1) ]
  data_one_yr[, Year := NULL]
  data <- data_one_yr
  ####
  
  return(data)
}

combine_variables_to_one_df <- function(dflist) {
  # Using bind_rows ensures that the columns are lined up with each other
  #   post-binding even if they aren't in the same order in the separate dfs
  #   e.g. bind_rows(mtcars[1:2], mtcars[2:1])
  # Started at 1:30 & took 30 minutes for two of the variables!
  message("binding rows of data frames in list")
  variable_df <- bind_rows(dflist) 
  
  return(variable_df)
}

# Read the data sources ----
soil_moist_tot <- read_period_of_record_data("nhru_soil_moist_tot.csv")
pkwater_equiv <- read_period_of_record_data("nhru_pkwater_equiv.csv")
#hru_intcpstor <- read_period_of_record_data("nhru_hru_intcpstor.csv")
#hru_impervstor <- read_period_of_record_data("nhru_hru_impervstor.csv")
#gwres_stor <- read_period_of_record_data("nhru_gwres_stor.csv")
#dprst_stor <- read_period_of_record_data("nhru_dprst_stor_hru.csv")

# Combine data sources into a single list ----
variable_df_list <- list(
  pkwater_equiv = pkwater_equiv,
  soil_moist_tot = soil_moist_tot#,
  #hru_intcpstor = hru_intcpstor,
  #hru_impervstor = hru_impervstor,
  #gwres_stor = gwres_stor,
  #dprst_stor = dprst_stor
)

# Combine all variables into one df ----
variable_df <- combine_variables_to_one_df(variable_df_list)
saveRDS(variable_df, "combined_vars.rds")
