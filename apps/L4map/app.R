library(shiny)
library(leaflet)
library(leaflet.providers)
library(leaflet.extras)
library(ggplot2)
library(dplyr)
library(magrittr)

load("mapdata.rda")
prov_table %<>% mutate(Sedimentar=factor(Sedimentar),Class=factor(Class))

vars <- c(
    "Area" = "total",
    "Number of polygons" = "npols"
)

server <- function(input, output) {
    # create a reactive value that will store the click position
    data_of_click <- reactiveValues(clickedMarker=NULL)
    # Leaflet map with 2 markers
    output$map <- renderLeaflet({
        leaflet() %>%
            addProviderTiles(providers$Esri.OceanBasemap) %>%
            setView(lng = 0, lat = 0, zoom = 2) %>%
            addPolygons(data = mprovs, layerId= ~PROV_CODE, fillColor = "snow3", highlightOptions = highlightOptions(weight = 2, color = 'black'), color = 'grey', weight = 0.4, fillOpacity = 0.15,label=labels) %>%
            leaflet.extras::addHeatmap(data = mgt_points, blur = 20, max = 0.05, radius = 12) %>%
            addCircleMarkers(data=qs, ~x , ~y, layerId=~id, popup=~q, radius=8 , color="black",  fillColor="red", stroke = TRUE, fillOpacity = 0.8)
    })
    # store the click
    observeEvent(input$map_marker_click,{
        data_of_click$clickedMarker <- input$map_marker_click
    })

    # store the click
    observeEvent(input$map_shape_click,{
        data_of_click$clickedMarker <- input$map_shape_click
    })


    # Make a barplot or scatterplot depending of the selected point
    output$plot=renderPlot({
        my_place=data_of_click$clickedMarker$id
        if(is.null(my_place)){my_place="place1"}
        if(my_place=="place1"){
            dts <- prov_table %>% group_by(Class,Sedimentar) %>% summarise(total=sum(total))
            ggplot(dts, aes(x=Class,fill=Sedimentar,y=total)) + geom_col()
        }else{
            dts <- prov_table %>% filter(PROV_CODE==my_place)
            prov_name <- dts %>% pull(PROVINCE) %>% unique
            # Make a barplot of area or number depending of the selected input
            if ( input$slcvar=='npols') {
                ggplot(dts, aes(x=Class,fill=Sedimentar,y=npols)) + geom_col() + labs(title=prov_name) + ylab("Number of polygons")
            } else {
                ggplot(dts, aes(x=Class,fill=Sedimentar,y=total)) + geom_col() + labs(title=prov_name) + ylab("Area")
            }
        }
    })
}
ui <- fluidPage(
    titlePanel("MFT1.2 Intertidal forests and shrublands - level 4 units"),
    br(),
    column(8,leafletOutput("map", height="600px")),
    column(4,  selectInput(inputId="slcvar", label="Variable", vars),br(),br(),
           plotOutput("plot", height="300px"),br(),br(),plotOutput("plotPols", height="300px")),
    br()
)
shinyApp(ui = ui, server = server)
