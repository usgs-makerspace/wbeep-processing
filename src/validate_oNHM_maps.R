library(sf)
library(ggplot2)

validate_oNHM_maps <- function(bad_data_hruids, mapfilename, var, title) {
  
  # Read in the shapefiles for hrus and background states layer so we can map the hrus that are flagged
  hrus <- read_sf(dsn=".",layer="hrus")
  states <- read_sf(dsn=".",layer="states")
  
  # Subset the HRUs geospatial data by the ones we need to plot
  hrus_to_plot <- hrus[hrus$nhru_v1_1 %in% bad_data_hruids,]
  
  # Transform geospatial data and subset states for the area we need
  proj_string <- 4326
  hrus_to_plot_proj <- st_transform(hrus_to_plot, crs = proj_string)
  states_proj <- st_transform(states, crs = proj_string)
  
  ggplot() + 
    geom_sf(data = states_proj, size=1, color="gray", fill="white") +
    geom_sf(data = hrus_to_plot_proj, size = 2, color = "red") + 
    geom_sf_text(data = hrus_to_plot_proj,
                 aes(label = nhru_v1_1),
                 size=3,
                 color="blue", check_overlap = TRUE) +
    ggtitle(sprintf("%s", title)) + 
    theme(axis.title.x = element_blank()) +
    theme(axis.title.y = element_blank()) +
    theme(axis.text.x = element_blank()) +
    theme(axis.text.y = element_blank()) +
    theme(axis.ticks.x = element_blank()) +
    theme(axis.ticks.y = element_blank()) +
    theme(panel.grid.major = element_line(color="transparent")) +
    theme(panel.background = element_blank()) +
    theme(plot.margin=grid::unit(c(0,0,0,0), "mm")) +
    coord_sf(xlim=c(-126,-66), ylim=c(24,49), expand = FALSE) 
  ggsave(mapfilename, plot=last_plot(), device=NULL, width=10, height= 8, units="in")
  
}