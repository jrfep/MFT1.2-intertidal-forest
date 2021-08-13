library(shiny)
library(leaflet)
library(leaflet.providers)
library(leaflet.extras)
library(ggplot2)
library(dplyr)
library(sf)
library(units)
library(ggforce)

load("mapdata.rda")
prov_table$Sedimentar <- factor(prov_table$Sedimentar)
prov_table$Class <- factor(prov_table$Class)

vars <- c(
    "Area" = "total",
    "Number of polygons" = "npols"
)

server <- function(input, output) {
    # create a reactive value that will store the click position
    data_of_click <- reactiveValues(clickedMarker=NULL)
    #labels
    my_labels = sprintf("<strong>Province</strong><br/>%s", mprovs$PROVINCE ) %>% lapply(htmltools::HTML)

    # Leaflet map
    output$map <- renderLeaflet({
        leaflet() %>%
            addProviderTiles(providers$Esri.OceanBasemap) %>%
            setView(lng = 0, lat = 0, zoom = 2) %>%
            addPolygons(data = mprovs, layerId= ~PROV_CODE, fillColor = "snow3", highlightOptions = highlightOptions(weight = 2, color = 'black'), color = 'grey', weight = 0.4, fillOpacity = 0.15,label=my_labels) %>%
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

    # output table
    output$table <- renderTable({
        my_place=data_of_click$clickedMarker$id
        if(is.null(my_place)) {
            
        } else {
            dts <- prov_table %>% filter(PROV_CODE==my_place) %>% ungroup %>% select(Class,Sedimentar,total,npols)
            dts   
        }
    })
    # Make a barplot or scatterplot depending of the selected point
    output$plot=renderPlot({
        my_place=data_of_click$clickedMarker$id
        if(is.null(my_place)){my_place="place1"}
        if(my_place=="place1"){
            dts <- prov_table %>% group_by(Class,Sedimentar) %>% summarise(total=sum(total))
            if ( input$slcvar=='npols') {
            ggplot(dts, aes(x=Class,fill=Sedimentar,y=npols)) + geom_col() + labs(title="All regions")
            } else {
                ggplot(dts, aes(x=Class,fill=Sedimentar,y=total)) + geom_col() + labs(title="All regions") + ylab("Area")
            }
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
    titlePanel( div(column(width = 3, tags$a(href='https://global-ecosystems.org/explore/groups/MFT1.2',
                                             tags$img(src='logo.png'))),
                    column(width = 9, h1("MFT1.2 Intertidal forests and shrublands - level 4 units"))),
                windowTitle="MyPage"
    ),
    column(8,leafletOutput("map", height="600px")),
    column(4,  selectInput(inputId="slcvar", label="Variable", vars),br(),br(),
           plotOutput("plot", height="300px"),br(),br(),tableOutput("table")),
    br()
)
shinyApp(ui = ui, server = server)
