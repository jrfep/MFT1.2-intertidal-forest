require(dplyr)
require(magrittr)
require(sf)
require(units)

source(sprintf("%s/proyectos/IUCN-GET/MFT1.2-intertidal-forest/env/project-env.R",Sys.getenv("HOME")))
setwd(work.dir)

mgt.meow.its <- read_sf("eck4-mangrove-type-provs.gpkg")
mgt.meow.its %>%  pull(PROV_CODE) %>% unique -> slc

mi.rda <- sprintf("%s/pre-assessment.rda",work.dir)
if (file.exists(mi.rda)) {
  load(mi.rda)
} else {
  rslts <- tibble()
}

for (j in sample(slc)) {
  if (!("PROV_CODE" %in% colnames(rslts)) | !(j %in% rslts$PROV_CODE)) {
    mgt.meow.its %>% filter(PROV_CODE %in% j) -> mgt.slc
    mgt.slc %>% summarise -> out
    EOO.sf <- st_convex_hull(out)
    
    raw.grid <- st_make_grid(EOO.sf,cellsize=10000)
    raw.grid %>%  st_sf(layer = 1:length(raw.grid), geoms = ., stringsAsFactors = FALSE) -> grid
    
    data.intersect <- st_intersection(mgt.slc, grid) %>% mutate(area = st_area(.))
    grid.area <- data.intersect %>% group_by(layer) %>% summarize(area = sum(area))
  
    grid %>% mutate(total_area=st_area(geoms)) %>% st_drop_geometry() %>% inner_join(st_drop_geometry(grid.area)) %>% mutate(p.area=(area*100/total_area) %>% drop_units)  -> aoo.grid
  
    a1 <- mgt.slc %>% ungroup %>% summarise(PROV_CODE=j,Class='all',Sedimentar='all',area_poly=sum(st_area(geometry)) %>% set_units('km^2')) %>% st_drop_geometry
    a2 <- aoo.grid %>% summarise(PROV_CODE=j,Class='all',Sedimentar='all',area_grid=sum(area) %>% set_units("m^2") %>% set_units("km^2"),AOO=n(),AOO_m=sum(p.area>1)) 
    a3 <- EOO.sf %>% ungroup %>% summarise(PROV_CODE=j,Class='all',Sedimentar='all',EOO=st_area(geometry) %>% set_units('km^2')) %>% st_drop_geometry
    
    rslts %<>% bind_rows(a1 %>% left_join(a2) %>% left_join(a3))
    save(file=mi.rda,rslts)
    
    a1 <- mgt.slc %>% group_by(Class,Sedimentar) %>% summarise(area_poly=sum(st_area(geometry) %>% set_units('km^2'))) %>% st_drop_geometry
  
    grid.area <- data.intersect %>% group_by(layer,Class,Sedimentar) %>% summarize(area = sum(area))
    grid %>% mutate(total_area=st_area(geoms)) %>% st_drop_geometry() %>% inner_join(st_drop_geometry(grid.area)) %>% mutate(p.area=(area*100/total_area) %>% drop_units)  -> aoo.grid
    a2 <- aoo.grid %>% group_by(Class,Sedimentar) %>% summarise(PROV_CODE=j,area_grid=sum(area) %>% set_units("m^2") %>% set_units("km^2"),AOO=n(),AOO_m=sum(p.area>1)) 
    
    a3 <-mgt.slc %>% group_by(Class,Sedimentar) %>% summarise %>% st_convex_hull %>% mutate(EOO=st_area(geometry) %>% set_units(km^2)) %>% st_drop_geometry()
    
    rslts %<>% bind_rows(a1 %>% left_join(a2) %>% left_join(a3))
    save(file=mi.rda,rslts)
  }
}

