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
load("assmntdata.rda")
prov_table$Sedimentar <- factor(prov_table$Sedimentar)
prov_table$Class <- factor(prov_table$Class)

vars <- c(
    "Area" = "total",
    "Number of polygons" = "npols"
)

server <- function(input, output) {

#    output$instructions <- renderText("Instructions")

    # create a reactive value that will store the click position
    data_of_click <- reactiveValues(clickedMarker=NULL)
    #labels
    my_labels = sprintf("<strong>Province</strong><br/>%s", mprovs$PROVINCE ) %>% lapply(htmltools::HTML)

    # Leaflet map
    output$map <- renderLeaflet({
        leaflet() %>%
            addProviderTiles(providers$Esri.OceanBasemap) %>%
            setView(lng = 0, lat = 0, zoom = 2) %>%
            addPolygons(data = mprovs, layerId= ~PROV_CODE, fillColor = "snow3", highlightOptions = highlightOptions(weight = 2, color = 'black'), color = 'grey', weight = 0.4, fillOpacity = 0.15,label=my_labels, group="Marine provinces") %>%
            leaflet.extras::addHeatmap(data = mgt_points, blur = 20, max = 0.05, radius = 12,group="Heatmap mangrove polygons") %>%
            addCircleMarkers(data=qs, ~x , ~y, layerId=~id, popup=~q, radius=8 , color="black",  fillColor="red", stroke = TRUE, fillOpacity = 0.8,group="Issues")  %>%
            addLayersControl(
                overlayGroups = c("Marine provinces","Heatmap mangrove polygons","Issues" ),
                options = layersControlOptions(collapsed = FALSE),
                position = "topright"
            )
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
            if (my_place %in% all_rslts$PROV_CODE) {
                dts <- all_rslts %>% filter(PROV_CODE==my_place) %>% dplyr::select(-1)
            } else {
                dts <- rslts_approx %>% filter(PROV_CODE==my_place) %>% dplyr::select(-1)
            }
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
    titlePanel( div(column(width = 3, tags$a(href='http://ec2-13-236-200-14.ap-southeast-2.compute.amazonaws.com:3838/Mangroves/',
                                             tags$img(src='logo.png', width = 300))),
                    column(width = 9, h1("MFT1.2 Intertidal forests and shrublands"),
                    h2("Preliminary level 4 units"))),
                windowTitle="MFT1.2-Intertidal-forests-preliminary-level-4"
    ),
    fluidRow(column(12,leafletOutput("map", height="400px"))),
    fluidRow(column(4,  plotOutput("plot", height="300px"),br(),
                    selectInput(inputId="slcvar", label="Variable", vars)),
             column(2,
                    tabsetPanel(
                        tabPanel("1",
                                 strong("Instructions"),
                                 p("Click on a Province to update plot and table."),
                                 p("Click on red markers to show issue to resolve.")
                        ),
                        tabPanel("2",
                                    strong("Map"),
                                    p("Heatmap shows density of mangrove polygons (from",
                                      tags$a(href='https://data.unep-wcmc.org/datasets/48',
                                             target="_blank","Worthington et al. 2020"),
                                      ").",
                                      tags$a(href='https://www.worldwildlife.org/publications/marine-ecoregions-of-the-world-a-bioregionalization-of-coastal-and-shelf-areas',
                                             target="_blank","Marine Provinces"),
                                      "shaded in grey, hover to display boundary and labels.",
                                      "Red markers indicate areas to review."),
                        ),
                        tabPanel("3",
                                 strong("Plot"),
                                 p("Plot shows the breakdown of area or number of polygons per combination of class and sedimentar in the selected province."),

                        ),
                        tabPanel("4",
                                 strong("Table"),
                                 p("The table shows preliminary statistics calculated for the mangrove polygons within each province."),
                                 p("Area in km^2, Area change in %; EOO: extent of occurrence in km^2; AOO: area of occupancy (number of cells); AOO_m: AOO cells with > 1km^2 occupancy")
                        ),
                        tabPanel("5",
                                 strong("IUCN Global Ecosystem typology"),
                                 p("Preliminary Level 4 units for MFT1.2 Intertidal forests and shrublands."),
                                 p("Based on",tags$a(href='https://global-ecosystems.org/explore/groups/MFT1.2',target="_blank",
                                                     "Bishop et al. (2020)"),br(),"Maps and app prepared by JR Ferrer-Paris @ ",
                                   tags$a(href='https://www.ecosystem.unsw.edu.au/',target="_blank","Centre for Ecosystem Science, UNSW"))
                    )
             )),
           column(6,  tableOutput("table")))
)
shinyApp(ui = ui, server = server)
