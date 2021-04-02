library(sf)
library(sp)
library(ggplot2)

validate_oNHM_maps <- function(bad_data_hruids, mapfilename, var) {
  
  # Read in the shapefiles for hrus and background states layer so we can map the hrus that are flagged
  hrus <- read_sf(dsn=".",layer="hrus")
  states <- read_sf(dsn=".",layer="states")
  
  # Subset the HRUs geospatial data by the ones we need to plot
  hrus_to_plot <- hrus[hrus$nhru_v1_1 %in% bad_data_hruids,]
  
  # Transform geospatial data and subset states for the area we need
  proj_string <- 4326
  hrus_to_plot2 <- st_transform(hrus_to_plot, crs = proj_string)
  states2 <- st_transform(states, crs = proj_string)

  ggplot() + 
    geom_sf(data = states2, size=1, color="gray", fill="white") +
    geom_sf(data = hrus_to_plot2, size = 2, color = "red", fill = "white") + 
    geom_sf_text(data = hrus_to_plot2,
                 aes(label = nhru_v1_1),
                 size=3,
                 color="blue",
                 nudge_x = -1, 
                 nudge_y = -1) +
    ggtitle(sprintf("hrus with %s data >= 10,000",var)) + 
    coord_sf(#xlim = stat_sf_coordinates(bbox)[c(1,2)], # min & max of x values
             #ylim = stat_sf_coordinates(bbox)[c(2,3),2]
      ) # min & max of y values
  ggsave(mapfilename, plot=last_plot(), device=NULL, width=10, height= 8, units="in")
  
}