library(leaflet)
require(DT)
require(tidyr)

navbarPage("MFT1.2 Intertidal forests and shrublands",
  tabPanel("Map of level 4 units", 
    fluidPage(
      titlePanel( div(column(width = 3, tags$a(href='http://ec2-13-236-200-14.ap-southeast-2.compute.amazonaws.com:3838/Mangroves/',
                                                      tags$img(src='logo.png', width = 170))),
                             column(width = 9, h1("MFT1.2 Intertidal forests and shrublands"),
                                    h2("Preliminary level 4 units"))),
                         windowTitle="MFT1.2-Intertidal-forests-preliminary-level-4"
             ),
      fluidRow(column(10,offset = 1,   
           leafletOutput("map"))),
      fluidRow(column(4, plotOutput("barplot", height="300px"),br(),
                             selectInput(inputId="slcvar", label="Variable", vars)),
              column(8,  
                        h2(htmlOutput("uName")),
                        tableOutput("table")
                        )))),
  tabPanel("Characteristic Biota",
           h2(htmlOutput("selectedName")),
           h3("Key Mangrove Species"),
           DTOutput("keySppTable"),
           h3("Species associated with Mangroves"),
           DTOutput("assocSppTable")
  ),
  tabPanel("Description of units",
           h2("Selected unit"),
           h1(textOutput("XMLname")),
           htmlOutput("XMLdesc")
           ),
  tabPanel("Instructions", 
           h2("IUCN Global Ecosystem typology"),
           p("Preliminary Level 4 units for ", strong("MFT1.2 Intertidal forests and shrublands"),"."),
           p("Based on:", br(), "MJ Bishop, AH Altieri, TS Bianchi and DA Keith (2020)",
             tags$a(href='https://global-ecosystems.org/explore/groups/MFT1.2',target="_blank",
                               em("MFT1.2 Intertidal forests and shrublands")),
             "In: Keith, D.A., Ferrer-Paris, J.R., Nicholson, E. and Kingsford, R.T. (eds.) (2020).", 
             strong("The IUCN Global Ecosystem Typology 2.0: Descriptive profiles for biomes and ecosystem functional groups."),
             "Gland, Switzerland: IUCN.", tags$a(href='http://doi.org/10.2305/IUCN.CH.2020.13.en',target="_blank","DOI:10.2305/IUCN.CH.2020.13.en"), 
             "Content version: v2.0, updated 2020-05-29."),
             p("Maps and app prepared by JR Ferrer-Paris @ ",
             tags$a(href='https://www.ecosystem.unsw.edu.au/',target="_blank","Centre for Ecosystem Science, UNSW")),
          h3("Map of level 4 units"),
          p("Map shows the Level 4 units, hover to display boundary and labels, click on a unit to update plot and table."),
          p("Heatmap shows density of mangrove polygons (from",
            tags$a(href='https://data.unep-wcmc.org/datasets/48', 
                   target="_blank","Worthington et al. 2020"),")."),
          h4("Bar Plot"),
          p("Plot shows the breakdown of area or number of polygons per combination of class and sedimentar in the selected province."),
            h4("Table"),
            p("The table shows the list of ",
              tags$a(href='https://www.worldwildlife.org/publications/marine-ecoregions-of-the-world-a-bioregionalization-of-coastal-and-shelf-areas',
                     target="_blank","marine ecoregions and provinces"),"used to delineate the level 4 units. 
              It also includes the area (km<sup>2</sup>) of mangrove occurrences estimated for the year 2016 and the number of key mangrove species in each ecoregion."),
          h3("Characteristic biota"),
          p("The tables show the characteristic biota of the selected unit."),
          h4("Key Mangrove Species"),
          p("List of plant species considered true mangroves or key species in mangrove communities with range maps intersecting the unit. Based on spatial data provided by the Red List of Threatened Species (RLTS)."),
          h4("Species associated with Mangroves"),
          p("List of taxa that are associated with mangrove habitats  in the RLTS database. We included only species with entries for Habitat 1.7: ", em("Forest - Subtropical/Tropical Mangrove Vegetation Above High Tide Level"), " or Habitat 12.7 for ",em("Marine Intertidal - Mangrove Submerged Roots"),", and with suitability recorded as ",em("Suitable"),", Major Importance recorded as ",em("Yes"),", and any value of seasonality except ",em("Passage"),".  We further filtered species with spatial point records in GBIF (some species are excluded due to mismatch in taxonomic names or lack of georeferenced records)."),
          
          h3("Description of units"),
          p("Summary of draft descriptions for the selected unit. Currently includes a general summary, characteristic biota, abiotic environment and biotic processes and interactions."),
          
             )
)
