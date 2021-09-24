#! R --vanilla

require(dplyr)
require(XML)
require(sf)
require(readr)

source(sprintf("%s/proyectos/IUCN-GET/MFT1.2-intertidal-forest/env/project-env.R",Sys.getenv("HOME")))
for (rda.file in c("mgt-point-data.rda","selected-units.rda","species-occurrence.rda","mangrove-species-units.rda"))
  load(file=sprintf("%s/www/Rdata/%s",script.dir,rda.file))


# Assessment unit correspond to _Regional ecosystem subgroups_ (level 4 of the IUCN Global Ecosystem Typology).

## translation tables:
categories <- c(CR="Critically Endangered",EN="Endangered",VU="Vulnerable")
presence <- c("NA"="occurs in this region","Breeding Season"="breeds in the mangroves of this region","Non-Breeding Season"="occurs in this region","Resident"="is a resident of the mangroves in this region", "Seasonal Occurrence Unknown"="occurs in this region")

threats <- read_csv(file=sprintf("%s/input/threats.csv",script.dir),col_types = "cccccccc")

## Initialize document
post_units %>% st_drop_geometry %>% select(unit_code,unit_name,shortname) -> slc

for (k in 1:nrow(slc)) {
  doc = newXMLDoc()
  cdg <- slc$unit_code[k]
  unit_name <- slc$unit_name[k]
  short_name <- slc$shortname[k]
  
  top = newXMLNode("Case-Study", doc=doc)

  unit_components <- post_units_components %>% filter(unit_code %in% cdg) %>% transmute(qry=sprintf("%s (%s province)",ECOREGION,PROVINCE)) %>% pull %>% paste(collapse=', ')

  key_spp_data %>% select(!!short_name) %>% pull -> ss
  key_spp_data %>% filter(ss) -> key.spp
  if (short_name %in% colnames(mga_spp_data)) {
    mga_spp_data %>% select(!!short_name) %>% pull -> ss
    mga_spp_data %>% filter(!is.na(ss)) -> assoc.spp
  } else {
    assoc.spp <- mga_spp_data %>% slice(0)
  }
  
  

  short_desc <- sprintf("The '%s' is a regional ecosystem subgroup (level 4 unit of the IUCN Global Ecosystem Typology) that includes intertidal forest and shrublands of the marine ecoregions of %s. The biota is characterised by %01d species of true mangroves and other key plant taxa that provide structure and resources for other mangove-associated taxa. Mangroves in this subgroup have a mapped extent of at least ... km2 in ... countries and are predominantly ... and .... They are threatened by  conversion for urban and tourism development, agriculture and aquaculture, and by increases in frequency of tropical storms. ", unit_name,unit_components,nrow(key.spp))


    ## Initialize first level nodes
  ## The assessment target node has 14 children nodes:
  AT.id <- newXMLNode("AT-id",cdg)
  AT.descriptions <- newXMLNode("AT-descriptions",
                                children=list(newXMLNode("AT-description", attrs=list(lang="en"),
                                                         short_desc)))
  AT.names <- newXMLNode("AT-names",
                         children=list(newXMLNode("AT-name", attrs=list(lang="en"), unit_name),
                                       newXMLNode("AT-name", attrs=list(lang="es"), gsub("Mangroves of","Bosques de Manglar de",unit_name)
                                       )))

  AT.biota <- newXMLNode("Characteristic-biota")
  AT.abiotic <- newXMLNode("Abiotic-environment")
  AT.biotic <- newXMLNode("Biotic-processes")
  AT.services <- newXMLNode("Ecosystem-services")
  AT.threats <- newXMLNode("Threats")
  AT.actions <- newXMLNode("Conservation-actions")
  AT.research <- newXMLNode("Research-needs")
  AT.CEM <- newXMLNode("Conceptual-ecosystem-model")
  AT.class <- newXMLNode("Classifications")
  AT.dist <- newXMLNode("Distribution")
  AT.collapse <- newXMLNode("Collapse-definition")

  ## Populate nodes
  ### Classification
  # Add classification information based on the IUCN Global ecosystem typology and the IUCN habitat classification scheme:
  class.typ <- newXMLNode("Classification-system", attrs=list(id="IUCN GET", version="2.0", selected="yes", `assigned-by`="Assessment authors"),
                          parent=AT.class)

  newXMLNode("Classification-element", "Transitional Marine-Freshwater-Terrestrial realm", attrs=list(level="1"), parent=class.typ)
  newXMLNode("Classification-element", "MFT1 Brackish tidal biome", attrs=list(level="2"), parent=class.typ)
  newXMLNode("Classification-element", "MFT1.2 Intertidal forests and shrublands", attrs=list(level="3"), parent=class.typ)
  newXMLNode("Classification-element", sprintf("%s %s",cdg,unit_name), attrs=list(level="4"), parent=class.typ)


  class.typ <- newXMLNode("Classification-system", attrs=list(id="IUCN habitat", version="3.1", selected="no", `assigned-by`="Assessment authors"),
                          parent=AT.class)

  newXMLNode("Classification-element", "1 Forest", attrs=list(level="1"), parent=class.typ)
  newXMLNode("Classification-element", "1.7 Forest – Subtropical/tropical mangrove vegetation above high tide level", attrs=list(level="2"), parent=class.typ)
  newXMLNode("Classification-element", "12 Marine Intertidal", attrs=list(level="1"), parent=class.typ)
  newXMLNode("Classification-element", "12.7 Marine Intertidal - Mangrove Submerged Roots", attrs=list(level="2"), parent=class.typ)

  ### Characteristic biota
  # For this node we need to add a summary and list of species:

    biota_desc <- sprintf("The biota of '%s' is characterised by the presence of %01d true mangrove and other key plant species. There are at least %02d species of the %s that have been associated with mangrove habitats in the Red List of Threatened Species database and have natural history collection records or observations within the distribution of this unit (GBIF 2021). ", unit_name,nrow(key.spp), nrow(assoc.spp), paste(unique(assoc.spp$class_name),collapse=", "))

    nThreatened <- {assoc.spp %>% filter(category %in% c("VU","EN","CR")) %>% nrow()}

    biota_thr <- switch(nThreatened+1,
           "",
           {
             assoc.spp %>% filter(category %in% c("VU","EN","CR")) -> tst
             sprintf("The %s %s %s.",
                     categories[tst$category], tst$main_common_name, presence[tst$season])
           },
           sprintf("These include %s threatened species.",nThreatened))
    

  newXMLNode("Biota-Summaries",
             children=list(
               newXMLNode("Biota-Summary",
                          paste0(biota_desc,biota_thr),
                          attrs=list(lang="en"))),
             parent=AT.biota)

  spp.list <- unique(c(key.spp$binomial,
                assoc.spp$scientific_name))
  
  taxon.list <- newXMLNode("taxons",parent=AT.biota)

  for (taxon in spp.list)
    newXMLNode("taxon",taxon, #attrs=list(lang="scientific"),
               parent=taxon.list)


  ### Distribution
  #Here I write some placeholder text based on the profile for the ecosystem functional group.

  country.list <- post_units_countries %>% filter(unit_code %in% cdg)

  dist_desc <- sprintf("The '%s' includes intertidal forest and shrublands of the marine ecoregions of %s, that extent across %s countries and territories in the regions of %s. ", unit_name, unit_components,
                       nrow(country.list), paste(unique(country.list$REGION_WB),collapse=", "))

  newXMLNode("Distribution-Summaries",
             children=list(
               newXMLNode("Distribution-Summary",
                          dist_desc,
                          attrs=list(lang="en"))),
             parent=AT.dist)

  country.items <- newXMLNode("Countries",parent=AT.dist)

  for (j in 1:nrow(country.list))
    newXMLNode("Country",{country.list %>% slice(j) %>% pull(WB_NAME)}, attrs=list(`iso-code-2`={country.list %>% slice(j) %>% pull(ISO_A2)}),
               parent=country.items)

  post_units %>% filter(unit_code %in% cdg) %>% st_bbox -> bbx
  newXMLNode("Spatial-data",
             children=list(
               newXMLNode("Spatial-point",attrs=list(datum="WGS84", proj=st_crs(post_units)$proj4string, type="lower-left-corner"), children=list(newXMLNode("x",bbx[[1]]), newXMLNode("y",bbx[[2]]),newXMLNode("radius",1000,attrs=list(units="m")))),
               newXMLNode("Spatial-point",attrs=list(datum="WGS84", proj=st_crs(post_units)$proj4string, type="lower-left-corner"), children=list(newXMLNode("x",bbx[[3]]), newXMLNode("y",bbx[[4]]),newXMLNode("radius",1000,attrs=list(units="m"))))
             ),
             parent=AT.dist)




  #    <Geographic-region></Geographic-region>
# <Biogeographic-realms><Biogeographic-realm></Biogeographic-real></Biogeographic-realms>
    # <Region> <Region-classification-system id="" version="0" selected="" assigned-by=""> <Region-classification-element level=""></Region-classification-element> </Region-classification-system> </Region>

## Abiotic environment
  
  abiotic1 <- "Mangroves are physiologically intolerant of low temperatures, which excludes them from regions where mean air temperature during the coldest months is below 20°C, where the seasonal temperature range exceeds 10°C, or where ground frost occurs. At the latitudinal limits of their distribution mangroves might show plastic ranges with discontinuous or intermittent presence."
  
  abiotic2 <- "Many mangrove soils are low in nutrients, especially nitrogen and phosphorus. Regional distributions are influenced by interactions among landscape position, rainfall, hydrology, sea level, sediment dynamics, subsidence, storm-driven processes, and disturbance by pests and predators. Rainfall and sediment supply from rivers and currents promote mangrove establishment and persistence, while waves and large tidal currents destabilise and erode mangrove substrates, mediating local-scale dynamics in ecosystem distributions. High rainfall reduces salinity stress and increases nutrient loading from adjacent catchments, while tidal flushing also regulates salinity."
  
  abiotic_desc <- if_else(grepl("Temperate",unit_name) | cdg %in% c("MFT1.2_4_MP_12b", "MFT1.2_4_MP_51", "MFT1.2_4_MP_16", "MFT1.2_4_MP_28"),paste(abiotic1,abiotic2),abiotic2)

  newXMLNode("Abiotic-Summaries",
             children=list(
               newXMLNode("Abiotic-Summary",
                          abiotic_desc,
                          attrs=list(lang="en"))),
             parent=AT.abiotic)
  
  ## Biotic processes
  newXMLNode("Processes-Summaries",
             children=list(newXMLNode("Processes-Summary",
                                      "Mangroves are structural engineers and possess traits including pneumatophores, salt excretion glands, vivipary, and propagule buoyancy that promote survival and recruitment in poorly aerated, saline, mobile, and tidally inundated substrates. They are highly efficient in nitrogen use efficiency and nutrient resorption. They produce large amounts of detritus (e.g. leaves, twigs, and bark), which is either buried in waterlogged sediments, consumed by crabs, or more commonly decomposed by fungi and bacteria, mobilising carbon and nutrients to higher trophic levels. These ecosystems are also major blue carbon sinks, incorporating organic matter into sediments and living biomass. Although highly productive, these ecosystems are less speciose than other coastal biogenic systems. Crabs are among the most abundant and important invertebrates. Their burrows oxygenate sediments, enhance groundwater penetration, and provide habitat for other invertebrates such as molluscs and worms. Specialised roots (pneumatophores) provide a complex habitat structure that protects juvenile fish from predators and serves as hard substrate for the attachment of algae as well as sessile and mobile invertebrates (e.g. oysters, mussels, sponges, and gastropods). Mangrove canopies support invertebrate herbivores and other terrestrial biota including invertebrates, reptiles, small mammals, and extensive bird communities. ",
                                      attrs=list(lang="en"))),parent=AT.biotic)
  ## Ecosystem services
  newXMLNode("Services",children=list(newXMLNode("Ecosystem-service")),parent=AT.services)
  newXMLNode("Services-Summaries", children=list(newXMLNode("Services-Summary","These systems are among the most productive coastal environments. These ecosystems are also major blue carbon sinks, incorporating organic matter into sediments and living biomass. They have well-documented ability of  to protect coastal regions from storms. ",attrs=list(lang="en"))),parent=AT.services)
  ## Finalise and write output

  ## Threats
  
  newXMLNode("Threats-Summaries",children=list(newXMLNode("Threats-Summary",attrs=list(lang="en"),"Mangrove deforestation due to aquaculture. Urbanisation and the associated coastal development, over-harvesting, and pollution from domestic, industrial and agricultural land use urbanisation (coastal development). The position of mangrove forests in intertidal areas renders them vulnerable to predicted sea-level rise as a result of climate change. Tropical storms can damage mangrove forests through direct defoliation and destruction of trees, as well as through the mass mortality of animal communities within the ecosystems. ")),parent=AT.threats)
  
  
  for (k in threats %>%  distinct(Name) %>% pull ) {
    this.Threat.class <- newXMLNode("Threat-classification",
                                    attrs=list(id="IUCN", version="3.2", selected="yes",
                                               `assigned-by`="Assessment authors"))
    for (thr in {threats %>% filter(Name %in% k & !is.na(level1)) %>% distinct(level1) %>% pull}) {
      newXMLNode("Threat-classification-element",thr,attrs=list(level=1),parent=this.Threat.class)
    }
    for (thr in {threats %>% filter(Name %in% k & !is.na(level2)) %>% distinct(level2) %>% pull}) {
      newXMLNode("Threat-classification-element",thr,attrs=list(level=2),parent=this.Threat.class)
    }
    for (thr in {threats %>% filter(Name %in% k & !is.na(level3)) %>% distinct(level3) %>% pull}) {
      newXMLNode("Threat-classification-element",thr,attrs=list(level=3),parent=this.Threat.class)
    }
    thr.info <- {threats %>% filter(Name %in% k & !is.na(Description))}
    newXMLNode("Threat",
               children=list(
                 newXMLNode("Threat-name",k),
                 newXMLNode("Threat-description",thr.info$Description,attrs=list(lang="en")),
                 newXMLNode("Threat-Impact",
                            children=list(
                              newXMLNode("Threat-Timing",thr.info$timing,attrs=list(id="IUCN", version="3.2", selected="yes", `assigned-by`="JRFP")),
                              newXMLNode("Threat-Scope",thr.info$scope,attrs=list(id="IUCN", version="3.2", selected="yes", `assigned-by`="JRFP")),
                              newXMLNode("Threat-Severity",thr.info$severity,attrs=list(id="IUCN", version="3.2", selected="yes", `assigned-by`="JRFP"))
                            )),
                 this.Threat.class
               ),
               parent=AT.threats)
  }
  
  ## Collapse definition
  
  newXMLNode("Collapse-summaries",children=list(newXMLNode("Collapse-summary",attrs=list(lang="en"))),parent=AT.collapse)
  newXMLNode("Spatial-collapse-definitions",children=list(newXMLNode("Spatial-collapse","Mangroves are structural engineers and possess specialised traits that promote high nitrogen use efficiency and nutrient resorption that influences major processes and functions in this ecosystem. Ecosystem collapse is considered to occur when the tree cover of diagnostic species of true mangroves declines to zero (100% loss).",
                                                                     attrs=list(lang="en"))),parent=AT.collapse)
  
  newXMLNode("Functional-collapse-definitions",children=list(newXMLNode("Functional-collapse","These are highly dynamic systems, with species distributions adjusting to local changes in sediment distribution, tidal regimes, and local inundation and salinity gradients. Processes that disrupt this dynamic can lead to ecosystem collapse. Ecosystem collapse may occur under any of the following: a) climatic conditions (low temperatures) restrict recruitment and survival of diagnostic true mangroves; b) changes in rainfall and river inputs and/or waves and tidal currents destabilise and erode substrates and disrupt recruitment and growth, c) changes in rainfall and tidal flushing change salinity stress and nutrient loadings affecting survival.",
                                                                        attrs=list(lang="en"))),parent=AT.collapse)
  
  
  
  # Aggregate all nodes to the parent node:

  AT = newXMLNode("Assessment-Target", attrs=list(date="2021-09-14", `updated-by`="JRFP", status="draft"), parent=top,
                  children=list(AT.id, AT.descriptions, AT.names, AT.biota, AT.abiotic, AT.biotic, AT.services, AT.threats, AT.actions, AT.research, AT.CEM, AT.class, AT.dist, AT.collapse))



  #Write output document:


  output.file <- sprintf("%s/www/xml/Assessment_target_%s.xml",script.dir,cdg)

  saveXML(doc,file=output.file,
          prefix = '<?xml version="1.0" encoding="UTF-8"?>
          <?xml-stylesheet type="text/xsl" href="target.xsl"?> ',
          indent = TRUE,
          encoding = "UTF-8")
  rm(doc,top)
  gc()
  system(sprintf("xmllint --format %s > tst",output.file))
  system(sprintf("mv tst %s",output.file))
}

## if we want to add a style:
# <?xml-stylesheet type="text/xsl" href="target.xsl"?>
