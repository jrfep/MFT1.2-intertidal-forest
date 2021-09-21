#! R --vanilla

require(dplyr)
require(XML)
require(sf)
require(readr)

source(sprintf("%s/proyectos/IUCN-GET/MFT1.2-intertidal-forest/env/project-env.R",Sys.getenv("HOME")))
for (rda.file in c("mgt-point-data.rda","selected-units.rda","species-occurrence.rda"))
  load(file=sprintf("%s/www/Rdata/%s",script.dir,rda.file))


# Assessment unit correspond to _Regional ecosystem subgroups_ (level 4 of the IUCN Global Ecosystem Typology).

## Initialize document
post_units %>% st_drop_geometry %>% select(unit_code,unit_name) -> slc

for (k in 1:nrow(slc)) {
  doc = newXMLDoc()
  cdg <- slc$unit_code[k]
  unit_name <- slc$unit_name[k]
  top = newXMLNode("Case-Study", doc=doc)

  unit_components <- post_units_components %>% filter(unit_code %in% cdg) %>% transmute(qry=sprintf("%s (%s province)",ECOREGION,PROVINCE)) %>% pull %>% paste(collapse=', ')

  mprov.xy %>% filter(ECO_CODE %in% {post_units_components %>% filter(unit_code %in% cdg) %>% pull(ECO_CODE)}) %>% st_drop_geometry %>% select(Dolichandrone.spathacea:Ceriops.australis) %>% t()-> ss
  
  key.spp <- ss[rowSums(ss)>0,,drop=FALSE]
  
  mtzXprov %>% filter(mprov.xy$ECO_CODE %in% {post_units_components %>% filter(unit_code %in% cdg) %>% pull(ECO_CODE)}) %>% t %>% rowSums() -> assoc.spp

  
  short_desc <- sprintf("The '%s' is a regional ecosystem subgroup (level 4 unit of the IUCN Global Ecosystem Typology) that includes intertidal forest and shrublands of the marine ecoregions of %s. The biota is characterised by %01d species of true mangroves and other key plant taxa that provide structure and resources for approx. %01d mangove-associated taxa. Mangroves in this subgroup have a mapped extent of at least ... km2 in ... countries and are predominantly ... and .... They are threatened by  conversion for urban and tourism development, agriculture and aquaculture, and by increases in frequency of tropical storms. ", unit_name,unit_components,nrow(key.spp),(sum(assoc.spp>0) %/% 10) * 10)
  
  
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
  
    biota_desc <- sprintf("The biota of '%s' is characterised by the presence of %01d true mangrove and other key plant species. The range maps of %s overlap with most of the distribution of this unit. There are %02d species that have been associated with mangrove habitats in the Red List of Threatened Species database and that have natural history collection records or observations within the distribution of this unit (GBIF 2021). ", unit_name,nrow(key.spp), paste(gsub("."," ",rownames(key.spp)[apply(key.spp,1,all) ],fixed=T), collapse=", "), sum(assoc.spp>0))
    
  
  newXMLNode("Biota-Summaries",
             children=list(
               newXMLNode("Biota-Summary",
                          biota_desc,
                          attrs=list(lang="en"))),
             parent=AT.biota)
  
  spp.list <- c(rownames(key.spp)[apply(key.spp,1,all) ],
                rownames(key.spp),
                names(assoc.spp[assoc.spp>0])
  )
  spp.list <- unique(gsub("\\.|_"," ",spp.list))
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

  
  ## Finalise and write output
  
  # Aggregate all nodes to the parent node:
  
  AT = newXMLNode("Assessment-Target", attrs=list(date="2021-09-14", `updated-by`="JRFP", status="draft"), parent=top,
                  children=list(AT.id, AT.descriptions, AT.names, AT.biota, AT.abiotic, AT.biotic, AT.services, AT.threats, AT.actions, AT.research, AT.CEM, AT.class, AT.dist, AT.collapse))
  
  
  
  #Write output document:
  
  
  output.file <- sprintf("%s/xml/Assessment_target_%s.xml",script.dir,cdg)
  
  saveXML(doc,file=output.file,
          prefix = '<?xml version="1.0" encoding="UTF-8"?>',
          indent = TRUE,
          encoding = "UTF-8")
  rm(doc,top)
  gc()
}

## if we want to add a style:
# <?xml-stylesheet type="text/xsl" href="target.xsl"?> 

