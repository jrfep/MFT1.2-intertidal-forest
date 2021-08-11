require(dplyr)
require(magrittr)
require(sf)
require(units)
require(raster)
require(readr)
require(stringr)
require(ggplot2)
require(units)
require(tidyr)
require(scatterpie)
require(ggforce)
library(leaflet)

source(sprintf("%s/proyectos/IUCN-GET/MFT1.2-intertidal-forest/env/project-env.R",Sys.getenv("HOME")))
setwd(work.dir)

## ogr2oggr
##

mgt.meow.its <- read_sf("intersection-type-meow-provs.gpkg")

mgt.meow.its %>%  pull(PROV_CODE) %>% table

mgt.meow.its %>%  pull(PROVINCE) %>% table

## gulf of guinea
mgt.meow.its %>% filter(PROV_CODE %in% 17) %>% st_centroid -> mgt_points
mgt.meow.its %>% filter(PROV_CODE %in% 17) %>% group_by(PROV_CODE) %>% st_union %>% st_convex_hull -> mgt_hull
mgt.meow.its %>% filter(PROV_CODE %in% 17) %>% st_union %>% st_convex_hull -> mgt_hull

leaflet()  %>% addTiles(options = leafletOptions(zoomControl = FALSE)) %>% # addProviderTiles(providers$CartoDB.DarkMatter) %>%
  setView(lng = 0, lat = 0, zoom = 4) %>%  addCircleMarkers(data = mgt_points, fillColor = 'red', fillOpacity = 0.6, stroke = FALSE,
                     radius = 4, clusterOptions = markerClusterOptions()) %>% addPolygons(data = mgt_hull,
                                   color = 'grey', weight = 0.4, fillOpacity = 0.5)
