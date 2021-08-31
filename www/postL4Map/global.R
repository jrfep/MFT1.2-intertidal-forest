library(dplyr)
library(magrittr)
require(sf)
options(dplyr.summarise.inform = FALSE)


#load("mapdata.rda")
#load("assmntdata.rda")
load("../Rdata/prov-data.rda")
load("../Rdata/mgv-species-occurrence.rda")


L4units <- prov.mgv.spp %>% filter(!(PROV_CODE %in% c(45,3,22,4,5,8,36,50,62)) & !(ECOREGION %in% c("Auckland Island","Snares Island","South New Zealand","Cocos Islands","Revillagigedos"))) %>% mutate(unit_name=PROVINCE,native=if_else(PROV_CODE %in% c(39,37,38,40),FALSE,TRUE))

L4units %<>% mutate(unit_name=case_when(
  PROVINCE %in% c('Northern New Zealand','Southern New Zealand') ~ "New Zealand Mangroves",
  ECOREGION %in% "Bermuda" ~ "Bermuda",
  ECOREGION %in% "Leeuwin" ~ "West Central Australian Shelf",
  ECOREGION %in% c("Great Australian Bight", "South Australian Gulfs", "Western Bassian")~ "Mangroves of South Australia",
  TRUE ~ unit_name
))

provs <- L4units  %>% group_by(PROVINCE,PROV_CODE) %>%
  st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=0")) %>% summarise(native=max(native))
for (slc in c("Hawaii","Southern New Zealand","Northern New Zealand","Central Polynesia","Central Polynesia","Marshall, Gilbert and Ellis Islands","Tropical Southwestern Pacific","Southeast Polynesia" )) {
  g <- provs %>% filter(PROVINCE %in% slc) %>% st_geometry
  provs$geom[provs$PROVINCE %in% slc] <- (g + c(360,90)) %% c(360) - c(0,90)
}

 L4u <-  L4units  %>% group_by(unit_name) %>%
   st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=0")) %>% summarise(native=max(native))
 for (slc in c("Hawaii","New Zealand Mangroves","Central Polynesia","Central Polynesia","Marshall, Gilbert and Ellis Islands","Tropical Southwestern Pacific","Southeast Polynesia" )) {
   g <- L4u %>% filter(unit_name %in% slc) %>% st_geometry
   L4u$geom[L4u$unit_name %in% slc] <- (g + c(360,90)) %% c(360) - c(0,90)
 }

 L4u %<>% mutate(id= sprintf("MFT1.2_G%02d",vctrs::vec_group_id(unit_name)))

#plot(provs['PROVINCE'])

##st_geometry(provs) = (st_geometry(provs) + c(360,90)) %% c(360) - c(0,90)
