## Download data from GBIF for species associated with 
# Load libraries
require(spocc)
require(dplyr)
require(RPostgreSQL)

# source project env variables
source(sprintf("%s/proyectos/IUCN-GET/MFT1.2-intertidal-forest/env/project-env.R",Sys.getenv("HOME")))
setwd(work.dir)

# Define target directory
target.dir <- sprintf("%s/species-dist/global/GBIF/%s/spocc/%s", gis.data, projectname, Sys.Date())
system(sprintf("mkdir -p %s",target.dir))


mi.rda <- sprintf('%s/mangrove-species-overview.rda',target.dir)
if (file.exists(mi.rda)) {
  load(mi.rda)
} else {
  
  #Check species associated with mangroves:
  drv <- dbDriver("PostgreSQL") ## remember to update .pgpass file
  con <- dbConnect(drv, dbname = iucn.dbinfo[["database"]],
                   host = iucn.dbinfo[["host"]],
                   port = iucn.dbinfo[["port"]],
                   user = iucn.dbinfo[["user"]])
  
  qry <- "SELECT taxonid,kingdom_name, phylum_name,   class_name, order_name, family_name, genus_name, scientific_name, taxonomic_authority, infra_rank, infra_name, population, category,  main_common_name, code,habitat, suitability, season, majorimportance FROM rlts_spp_taxonomy LEFT JOIN rlts_spp_habitats USING  (taxonid) where habitat like '%Mangr%'"
  mangrove_species <- dbGetQuery(con,qry)
  dbDisconnect(con)
  
  # quick query to know how many records to download for each species
  
  mangrove_species$gbif_records <- NA
  mangrove_species$gbif_xy_records <- NA
  for (j in 1:nrow(mangrove_species)) {
    cat(sprintf("Species %s: ",j))
    if (is.na(mangrove_species[j,"gbif_records"])) {
      tst <- occ(query = mangrove_species$scientific_name[j], from = 'gbif',limit=1)
      mangrove_species[j,"gbif_records"] <- tst$gbif$meta$found
      cat(sprintf("/ with %s GBIF records",tst$gbif$meta$found))
    }
    if (is.na(mangrove_species[j,"gbif_xy_records"])) {
      tst <- occ(query = mangrove_species$scientific_name[j], from = 'gbif',limit=1,has_coords = TRUE)
      mangrove_species[j,"gbif_xy_records"] <- tst$gbif$meta$found
      cat(sprintf("/ %s records with coordinates",tst$gbif$meta$found))
    }
    cat(sprintf("/ %0.2f %% ready\n ",j*100/nrow(mangrove_species)))
  }
  save(file=mi.rda,mangrove_species)
}

# Download data from GBIF according to the amount of records available, 
# first species with few records:

mi.rda <- sprintf('%s/occ-data-spps-few-records.rda',target.dir)

if (!file.exists(mi.rda)) {
  mangrove_species %>% filter(gbif_records>0 & gbif_records<500) %>% pull(scientific_name) -> spps
  spps.lt500 <- occ(query = spps, from = 'gbif',limit=500)
  mangrove_species %>% filter(gbif_records>499 & gbif_records<1000) %>% pull(scientific_name) -> spps
  spps.lt1000 <- occ(query = spps, from = 'gbif',limit=1000)
  save(file=mi.rda,spps.lt1000,spps.lt500)
}

# For species with more than 1000 records, we focus on the georeferenced records:

mi.rda <- sprintf('%s/occ-data-spps-mids-records.rda',target.dir)

if (!file.exists(mi.rda)) {
  mangrove_species %>% filter(gbif_records>999 & gbif_xy_records<1500) %>% pull(scientific_name) -> spps
  spps.lt1500 <- occ(query = spps, from = 'gbif',limit=5000,has_coords = TRUE)
  save(file=mi.rda,spps.lt1500)
}

# For species with more than 1500 records, we download species by species:
  
mangrove_species %>% filter(gbif_xy_records>1499 & gbif_xy_records<10000) %>% pull(scientific_name) -> spps
for (spp in spps) {
  mi.rda <- sprintf('%s/occ-data-spp-%s.rda',target.dir,gsub(" ","_",spp))
  if (!file.exists(mi.rda)) {
    spp_occ_data <- occ(query = spp, from = 'gbif',limit=10000,has_coords = TRUE)
    save(file=mi.rda,spp_occ_data)
  }
}

mangrove_species %>% filter(gbif_xy_records>9999 & gbif_xy_records<100000) %>% pull(scientific_name) -> spps
for (spp in spps) {
  mi.rda <- sprintf('%s/occ-data-spp-%s.rda',target.dir,gsub(" ","_",spp))
  if (!file.exists(mi.rda)) {
    spp_occ_data <- occ(query = spp, from = 'gbif',limit=100000,has_coords = TRUE)
    save(file=mi.rda,spp_occ_data)
  }
}

## what to do with species with more than 100000 records?
mangrove_species %>% filter(gbif_xy_records>9999 & gbif_xy_records>100000)

