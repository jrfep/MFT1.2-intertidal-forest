require(dplyr)
require(magrittr)
require(sf)
require(units)

source(sprintf("%s/proyectos/IUCN-GET/MFT1.2-intertidal-forest/env/project-env.R",Sys.getenv("HOME")))
setwd(work.dir)

mgt.2016.pols <- read_sf("eck4-mangrove-type-provs.gpkg")
mgt.1996.pols <- read_sf("eck4-mangrove-type-provs-1996.gpkg")
mgt.2016.pols %>%  pull(PROV_CODE) %>% unique -> slc.2016
mgt.1996.pols %>%  pull(PROV_CODE) %>% unique -> slc.1996

all(slc.1996 %in% slc.2016)
all(slc.2016 %in% slc.1996)



archs <- list.files("pre-assessment/","2016.rda$",recursive=T,full.names = TRUE)

all_rslts <- tibble()

for (arch in archs) {
  load(arch)

  rslts %>% filter(year %in% 2016) %>% transmute(PROV_CODE,Class,Sedimentar,Area_2016=area_ogr,EOO,AOO,AOO_m) -> a1
  rslts %>% filter(year %in% 1996) %>% transmute(PROV_CODE,Class,Sedimentar,Area_1996=area_ogr) -> a2
  
  all_rslts %<>% bind_rows(
    a1 %>% left_join(a2) %>% 
      transmute(PROV_CODE, Class, Sedimentar, Area=Area_2016, 
                Area_Change=((Area_2016-Area_1996)/Area_1996) %>% set_units('%'),
                AOO,AOO_m,EOO) 
  )
}
save(file=sprintf("%s/apps/L4map/assmntdata.rda",script.dir),all_rslts)

