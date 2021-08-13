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

mgt.meow.its <- read_sf("intersection-type-meow-provs.gpkg")
mgt.meow.its %>%  pull(PROV_CODE) %>% unique -> slc

mgt.meow.its %>% filter(PROV_CODE %in% 20) -> mgt.slc


meow <- read_sf("mangrove-type-data-sources.vrt","meow")
meow %>% filter(PROV_CODE %in% slc) %>% group_by(PROV_CODE,PROVINCE) %>% summarise(geom=st_union(geom)) -> mprovs

mgt.meow.its %>% mutate(area=st_area(geometry),centroid=st_centroid(geometry)) %>% st_drop_geometry  %>% transmute(ID,PROVINCE,PROV_CODE,ECO_CODE, Class, Sedimentar,area,lon=st_coordinates(centroid)[,1],lat=st_coordinates(centroid)[,2]) -> rslts_meow

rslts_meow %>% group_by(PROV_CODE,PROVINCE,Class,Sedimentar) %>% summarise(total=sum(area) %>% drop_units) %>% pivot_wider(id=c(PROV_CODE), names_from=c(Class,Sedimentar), values_from=total) %>% replace(is.na(.), 0) -> prov_areas

rslts_meow %>% group_by(PROV_CODE,PROVINCE,Class,Sedimentar) %>% summarise(npols=n(),total=sum(area) %>% set_units('km^2')) -> prov_table

#
qs <- tibble(id=13,y=10, x=-60.59,q="Confirm boundaries (north) of North Brazil Shelf")
qs <- tibble(id=13,y=-0.35, x=-41.44,q="Confirm boundaries (south) of North Brazil Shelf") %>% bind_rows(qs)

qs %<>% bind_rows(tibble(id=6,y=28.4590, x=-85.995,q="Boundary between tropical and temperate in North west Atlantic: merge or keep as different provinces?"))

qs %<>% bind_rows(tibble(id=6,y=-21.7575, x=-41.433,q="Boundary between tropical and temperate in South western Atlantic: merge or keep as different provinces?"))

qs %<>% bind_rows(tibble(id=44,y=-1.050 , x=-90.429,q="Keep Galapagos as a different province?"))
qs %<>% bind_rows(tibble(id=16,y=14.434 , x=-15.426,q="Merge West African Transition with Gulf of Guinea"))
qs %<>% bind_rows(tibble(id=51,y=-27.994, x=33.263,q="Where is the boundary between Agulhas and West Indian Ocean provinces?"))
qs %<>% bind_rows(tibble(id=18,y=12.382 , x=47.570,q="Confirm if Gulf of Aden is kept together with Red Sea, split or merge with Somali/Arabian province?"))
qs %<>% bind_rows(tibble(id=21,y=8.146,x=80.175,q="Keep Sri Lanka in West and South Indian Shelf, combine with Bay of Bengal or split in own region?"))
# Confirm general  boundaries between provinces in Asia and Oceania
qs %<>% bind_rows(tibble(id=28,y=23.40,x=126.74,q="Keep South Kuroshio province? merge with others?"))
qs %<>% bind_rows(tibble(id=25,y=24.035,x=120.980,q="Confirm boundaries between provinces in Taiwan"))
qs %<>% bind_rows(tibble(id=57,y=-34.86,x=138.80,q="Confirm south east and south west Australian shelves"))
qs %<>% bind_rows(tibble(id=37,y=20.30,x=-157.13,q="Status of Hawaii?"))
qs %<>% bind_rows(tibble(id=39,y=-14.43,x=-173.130,q="Keep Central Polynesia? or merge with Tropical Southwestern Pacific"))



save(file=sprintf("%s/apps/L4map/mapdata.rda",script.dir), prov_table, mgt_points, mprovs, qs)
#save(file="~/tmp/shiny-test/mapdata.rda",prov_table,mgt_points,mprovs,qs)


mgt_hull <- read_sf("convex-hull.gpkg")
st_area(mgt_hull) %>% set_units(km^2)
mgt_hull %>% slice(25) %>% pull(2)
plot(mgt_hull %>% slice(-25) %>% dplyr::select(PROV_CODE))

mgt_hull %>% slice(-25) -> mgt_plgns
## gulf of guinea
##mgt.meow.its %>% filter(PROV_CODE %in% 17) %>% st_centroid -> mgt_points
mgt.meow.its %>%  st_centroid -> mgt_points


## providers: Stadia.OSMBright Thunderforest.Pioneer Thunderforest.Neighbourhood CyclOSM Jawg.Terrain Jawg.Light Stamen.TonerLite Esri.OceanBasemap CartoDB.VoyagerLabelsUnder Esri.NatGeoWorldMap
m <- leaflet(options = leafletOptions(worldCopyJump = TRUE,zoomControl = TRUE))  %>%  addProviderTiles(providers$Esri.OceanBasemap) %>%
  setView(lng = 0, lat = 0, zoom = 2)

#bin_pal = colorFactor('Accent', factor(mprovs$PROV_CODE ))
#bin_pal = colorFactor(sample(colors(),10), factor(mprovs$PROV_CODE ))
labels = sprintf("<strong>Province</strong><br/>%s", mprovs$PROVINCE ) %>% lapply(htmltools::HTML)

#m <- m %>% addCircleMarkers(data = mgt_points, fillColor = 'red', fillOpacity = 0.6, stroke = FALSE, radius = 4, clusterOptions = markerClusterOptions())

m %>% addPolygons(data = mprovs, fillColor = "snow3", highlightOptions = highlightOptions(weight = 2, color = 'black'), color = 'grey', weight = 0.4, fillOpacity = 0.15,label=labels) %>% leaflet.extras::addHeatmap(data = mgt_points, blur = 20, max = 0.05, radius = 12)

prov_table %>% filter(PROV_CODE==17)

save(file="~/tmp/mangrove-maps/mapdata.rda",prov_table,mgt_points,mprovs)


# Show barplot for a given province

   showProvPopup <- function(slccode, lat, lng) {
       selectedProv <- prov_table %>% filter(PROV_CODE==slccode)

       output$barPlot <- renderPlot({
           barplot(selectedProv$total,names.arg=paste(selectedProv$Class,selectedProv$Sedimentar))
           # ggplot(selectedProv, aes(x=Class,fill=Sedimentar,y=total)) + geom_col()
       })
   }


# bin_pal = colorFactor('Accent', mgt_plgns$PROV_CODE )
#
# labels = sprintf("<strong>Province</strong><br/>%s",
#                  mgt_plgns$PROVINCE ) %>% lapply(htmltools::HTML)
#
#
# leaflet()  %>% addTiles(options = leafletOptions(zoomControl = FALSE)) %>% # addProviderTiles(providers$CartoDB.DarkMatter) %>%
#   setView(lng = 0, lat = 0, zoom = 4) %>%  addCircleMarkers(data = mgt_points, fillColor = 'red', fillOpacity = 0.6, stroke = FALSE,
#                      radius = 4, clusterOptions = markerClusterOptions()) %>% addPolygons(data = mgt_plgns, fillColor = ~bin_pal(mgt_plgns$PROV_CODE),highlightOptions = highlightOptions(weight = 2, color = 'black'),
#                                    color = 'grey', weight = 0.4, fillOpacity = 0.5,label=labels)




m %>%
   addPopups(data=qs,popup=qs$question)
