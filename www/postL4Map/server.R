library(shiny)
library(leaflet)
library(leaflet.providers)
library(dplyr)
library(sf)
require(DT)
require(tidyr)
library(ggplot2)
library(units)
library(ggforce)


options(dplyr.summarise.inform = FALSE)

function(input, output, session) {
  
  # create a reactive value that will store the click position
  data_of_click <- reactiveValues(clickedUnit=NULL)
  
  observeEvent(input$map_shape_click,{
    data_of_click$clickedUnit <- input$map_shape_click
  })
  
  output$map <- renderLeaflet({
  #  pr_labels <- sprintf("PROVINCE:<br/><strong>%s</strong> ",
   #                       provs$PROVINCE) %>% lapply(htmltools::HTML)
    l4_labels <- sprintf("UNIT:<br/><strong>%s</strong><br/> Native: %s ", post_units$unit_name, post_units$native) %>% lapply(htmltools::HTML)
    #ku_labels <- sprintf("%s", known_mgv$message) %>% lapply(htmltools::HTML)

    leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      setView(lng = 40, lat = 10, zoom = 2) %>%
         # addPolygons(data = provs, color = 'yellow',  weight = 2, fillOpacity = 0.15,
        #            highlightOptions = highlightOptions(weight = 2, color = 'black'),
        #            label=pr_labels,
        #            group='Marine provinces')  %>%
      addMarkers(data=known_mgv,group='Known unmapped occurrences',label=~message) %>%
      addPolygons(data = post_units, layerId= ~unit_name, color = 'red',  weight = 2, fillOpacity = 0.15,label=l4_labels,
                              highlightOptions = highlightOptions(weight = 2, color = 'black'),
                              group='Level 4 units') %>%
      leaflet.extras::addHeatmap(data = mgt_points, blur = 20, max = 0.05, radius = 12,group="Heatmap mangrove polygons (2016)") %>%
      addLayersControl(
          overlayGroups = c("Level 4 units", "Heatmap mangrove polygons (2016)","Known unmapped occurrences"),
          options = layersControlOptions(collapsed = FALSE), position = "topright") 
        })
  
  ## test of text output
  output$uName=renderText({
    data_of_click$clickedUnit$id
    })
  output$description=renderText({
    post_units %>% filter(unit_name %in% data_of_click$clickedUnit$id) %>% pull(description) -> desc
    htmltools::HTML(desc)
  })
  
  # Make a barplot 
  output$barplot=renderPlot({
    uname = data_of_click$clickedUnit$id
    if(is.null(uname)){
      dts <- units_table %>% group_by(Class,Sedimentar) %>% summarise(total=sum(total))
      if ( input$slcvar=='npols') {
        ggplot(dts, aes(x=Class,fill=Sedimentar,y=npols)) + geom_col() + labs(title="All regions")
      } else {
        ggplot(dts, aes(x=Class,fill=Sedimentar,y=total)) + geom_col() + labs(title="All regions") + ylab("Area")
      }
    } else {
      dts <- units_table %>% filter(unit_name %in% uname)
      # Make a barplot of area or number depending of the selected input
      if ( input$slcvar=='npols') {
        ggplot(dts, aes(x=Class,fill=Sedimentar,y=npols)) + geom_col() + labs(title=uname) + ylab("Number of polygons")
      } else {
        ggplot(dts, aes(x=Class,fill=Sedimentar,y=total)) + geom_col() + labs(title=uname) + ylab("Area")
      }
    }
  })  
  
}
