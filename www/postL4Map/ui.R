library(leaflet)
require(DT)
require(tidyr)

navbarPage("MFT1.2 Intertidal forests and shrublands",
  tabsetPanel(
    tabPanel("Map of level 4 units", 
             leafletOutput("map"),
             fluidRow(column(4,  plotOutput("barplot", height="300px"),br(),
                             selectInput(inputId="slcvar", label="Variable", vars)),
                      column(4,  
                        h2(htmlOutput("uName")),
                        p(htmlOutput("description"))),
                      column(4,  
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
                             )
                             )
                      )
             ),
    tabPanel("List of level 4 units", 
             h1("We will have great content here!"))
  )
)

# 
# fluidPage(
#     ,div(column(width = 3, tags$a(href='http://ec2-13-236-200-14.ap-southeast-2.compute.amazonaws.com:3838/Mangroves/',
#tags$img(src='logo.png', width = 300))),
#column(width = 9, h1("MFT1.2 Intertidal forests and shrublands"),
#       h2("Preliminary level 4 units")))
#     fluidRow(column(12,leafletOutput("map", height="400px"))),
#     fluidRow(column(4,  plotOutput("plot", height="300px"),br(),
#                     selectInput(inputId="slcvar", label="Variable", vars)),
#              column(2,  
#                     tabsetPanel(
#                         tabPanel("1",
#                                  strong("Instructions"),
#                                  p("Click on a Province to update plot and table."),
#                                  p("Click on red markers to show issue to resolve.")
#                         ), 
#                         tabPanel("2",
#                                     strong("Map"),
#                                     p("Heatmap shows density of mangrove polygons (from",
#                                       tags$a(href='https://data.unep-wcmc.org/datasets/48',
#                                              target="_blank","Worthington et al. 2020"),
#                                       ").",
#                                       tags$a(href='https://www.worldwildlife.org/publications/marine-ecoregions-of-the-world-a-bioregionalization-of-coastal-and-shelf-areas', 
#                                              target="_blank","Marine Provinces"),
#                                       "shaded in grey, hover to display boundary and labels.",
#                                       "Red markers indicate areas to review."),
#                         ), 
#                         tabPanel("3",
#                                  strong("Plot"),
#                                  p("Plot shows the breakdown of area or number of polygons per combination of class and sedimentar in the selected province."),
#                                  
#                         ), 
#                         tabPanel("4", 
#                                  strong("Table"),
#                                  p("The table shows preliminary statistics calculated for the mangrove polygons within each province."),
#                                  p("Area in km^2, Area change in %; EOO: extent of occurrence in km^2; AOO: area of occupancy (number of cells); AOO_m: AOO cells with > 1km^2 occupancy")
#                         ), 
#                         tabPanel("5", 
#                                  strong("IUCN Global Ecosystem typology"),
#                                  p("Preliminary Level 4 units for MFT1.2 Intertidal forests and shrublands."),
#                                  p("Based on",tags$a(href='https://global-ecosystems.org/explore/groups/MFT1.2',target="_blank",
#                                                      "Bishop et al. (2020)"),br(),"Maps and app prepared by JR Ferrer-Paris @ ",
#                                    tags$a(href='https://www.ecosystem.unsw.edu.au/',target="_blank","Centre for Ecosystem Science, UNSW"))
#                     )
#              )),
#            column(6,  tableOutput("table")))
# )