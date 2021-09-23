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
require(xml2)


options(dplyr.summarise.inform = FALSE)

function(input, output, session) {
  
  # create a reactive value that will store the click position
  data_of_click <- reactiveValues(clickedUnit=NULL)
  
  observeEvent(input$map_shape_click,{
    data_of_click$clickedUnit <- input$map_shape_click
  })
  
  xmlData <- reactive({
    if (is.null(data_of_click$clickedUnit)) {
        code <- post_units %>% slice(1) %>% pull(unit_code)
      } else {
        code <- post_units %>% filter(unit_name %in% data_of_click$clickedUnit$id) %>% pull(unit_code)
      }
    read_xml(sprintf("../xml/Assessment_target_%s.xml",code))
  })
  
  output$map <- renderLeaflet({
     l4_labels <- sprintf("UNIT %s:<br/><strong>%s</strong><br/> Native: %s ", post_units$unit_code, post_units$unit_name, post_units$native) %>% lapply(htmltools::HTML)
 
    leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      setView(lng = 40, lat = 10, zoom = 2) %>%
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
  
  
  ## table output
  output$table <- renderTable({
    my_place=data_of_click$clickedUnit$id
    if(is.null(my_place)) {
      
    } else {
        dts <- post_units_components %>% filter(unit_name %in% my_place) %>% 
          transmute(#PROV_CODE,ECO_CODE,
                    Province=PROVINCE,Ecoregion=ECOREGION,Native=native,
                    `Area (km^2) 2016`=area_gmw_2016,`Nr. key spp.`=round(n_key_mgv_spp),Description=description
                    )
      dts
    }
  })
  
  
  #output$description=renderText({
  #  post_units %>% filter(unit_name %in% data_of_click$clickedUnit$id) %>% pull(description) -> desc
  #  htmltools::HTML(desc)
  #})
  
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
  
  output$XMLname=renderText({
    xmlData() %>% xml_find_first("//AT-name") %>% xml_text
  })
    output$XMLdesc <- renderUI({
     text1 <- xmlData() %>% xml_find_first("//AT-description") %>% xml_text
     text2 <- xmlData() %>% xml_find_first("//Biota-Summary") %>% xml_text
     text3 <- xmlData() %>% xml_find_first("//Abiotic-Summary") %>% xml_text
     text4 <- xmlData() %>% xml_find_first("//Processes-Summary") %>% xml_text
     tags$div(
       tags$h3("Unit description"),
       tags$p(text1),       
       tags$h3("Characteristic biota"),
       tags$p(text2),
       tags$h3("Abiotic environment"),
       tags$p(text3),
       tags$h3("Biotic processes"),
       tags$p(text4))
   })
  
}
