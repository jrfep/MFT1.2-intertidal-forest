library(leaflet)
require(DT)
require(tidyr)

navbarPage("Level 4 units",
tabsetPanel(
  tabPanel("Map of level 4 units", leafletOutput("map")),
  tabPanel("List of level 4 units", h1("We will have great content here!"))
)
)