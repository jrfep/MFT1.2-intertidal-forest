library(shiny)
library(leaflet)
library(leaflet.providers)
library(dplyr)
library(sf)
require(DT)
require(tidyr)

options(dplyr.summarise.inform = FALSE)

function(input, output, session) {
  output$map <- renderLeaflet({
    pr_labels <- sprintf("PROVINCE:<br/><strong>%s</strong> ",
                          provs$PROVINCE) %>% lapply(htmltools::HTML)
    l4_labels <- sprintf("UNIT %s:<br/><strong>%s</strong><br/> Native: %s ", L4u$id, L4u$unit_name, L4u$native) %>% lapply(htmltools::HTML)

    leaflet() %>%
        addProviderTiles(providers$CartoDB.Positron) %>%
         setView(lng = 40, lat = 10, zoom = 2) %>%
         # addPolygons(data = provs, color = 'yellow',  weight = 2, fillOpacity = 0.15,
        #            highlightOptions = highlightOptions(weight = 2, color = 'black'),
        #            label=pr_labels,
        #            group='Marine provinces')  %>%
         addPolygons(data = L4u, color = 'red',  weight = 2, fillOpacity = 0.15,label=l4_labels,
                              highlightOptions = highlightOptions(weight = 2, color = 'black'),
                              group='Level 4 units')
      })
}
