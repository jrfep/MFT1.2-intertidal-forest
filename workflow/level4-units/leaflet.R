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

mgt_hull <- read_sf("convex-hull.gpkg")
st_area(mgt_hull) %>% set_units(km^2)
mgt_hull %>% slice(25) %>% pull(2)
plot(mgt_hull %>% slice(-25) %>% dplyr::select(PROV_CODE))

mgt_hull %>% slice(-25) -> mgt_plgns
leaflet()  %>% addTiles(options = leafletOptions(zoomControl = FALSE)) %>% # addProviderTiles(providers$CartoDB.DarkMatter) %>%
  setView(lng = 0, lat = 0, zoom = 4) %>% addPolygons(data = mgt_plgns,
                color = 'grey', weight = 0.4, fillOpacity = 0.5)

## gulf of guinea
mgt.meow.its %>% filter(PROV_CODE %in% 17) %>% st_centroid -> mgt_points
mgt.meow.its %>%  st_centroid -> mgt_points

bin_pal = colorFactor('Accent', mgt_plgns$PROV_CODE )

labels = sprintf("<strong>Province</strong><br/>%s",
                 mgt_plgns$PROVINCE ) %>% lapply(htmltools::HTML)

leaflet()  %>% addTiles(options = leafletOptions(zoomControl = FALSE)) %>% # addProviderTiles(providers$CartoDB.DarkMatter) %>%
  setView(lng = 0, lat = 0, zoom = 4) %>%  addCircleMarkers(data = mgt_points, fillColor = 'red', fillOpacity = 0.6, stroke = FALSE,
                     radius = 4, clusterOptions = markerClusterOptions()) %>% addPolygons(data = mgt_plgns, fillColor = ~bin_pal(mgt_plgns$PROV_CODE),highlightOptions = highlightOptions(weight = 2, color = 'black'),
                                   color = 'grey', weight = 0.4, fillOpacity = 0.5,label=labels)

leaflet()  %>% addTiles(options = leafletOptions(zoomControl = FALSE)) %>% addPolygons(data = mgt_plgns, highlightOptions = highlightOptions(weight = 2, color = 'black'),color = 'grey', weight = 0.4,fillOpacity = 0.15,label=labels) %>%
 setView(lng = 0, lat = 0, zoom = 4) %>% leaflet.extras::addHeatmap(data = mgt_points, blur = 20, max = 0.05, radius = 12)
