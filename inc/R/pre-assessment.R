require(dplyr)
require(magrittr)
require(sf)
require(units)

args <- commandArgs(TRUE)
j <- as.numeric(args[1])

rslts <- tibble(PROV_CODE=numeric())
for (y in c(1996,2016)) { 
  mi.rda <- sprintf("pre-assessment-%s.rda",y)
  mgt.slc <- read_sf(sprintf("mgt-%s.gpkg",y))
  mgt.slc %>% summarise -> out
  EOO.all <- st_convex_hull(out)
  
  raw.grid <- st_make_grid(EOO.all,cellsize=10000)
  raw.grid %>%  st_sf(layer = 1:length(raw.grid), geoms = ., stringsAsFactors = FALSE) -> grid
  
  data.intersect <- st_intersection(mgt.slc, grid) %>% mutate(area = st_area(.))
  grid.area <- data.intersect %>% group_by(layer) %>% summarize(area = sum(area))

  grid %>% mutate(total_area=st_area(geoms)) %>% st_drop_geometry() %>% inner_join(st_drop_geometry(grid.area)) %>% mutate(p.area=(area*100/total_area) %>% drop_units)  -> AOO.all

  a1 <- mgt.slc %>% ungroup %>% summarise(PROV_CODE=j,year=y,Class='all',Sedimentar='all',area_ogr=sum(set_units(AREA_proj,"m^2") %>% set_units("km^2")),area_poly=sum(st_area(geometry)) %>% set_units('km^2')) %>% st_drop_geometry
  a2 <- AOO.all %>% summarise(PROV_CODE=j,year=y,Class='all',Sedimentar='all',area_grid=sum(area) %>% set_units("m^2") %>% set_units("km^2"),AOO=n(),AOO_m=sum(p.area>1)) 
  a3 <- EOO.all %>% ungroup %>% summarise(PROV_CODE=j,year=y,Class='all',Sedimentar='all',EOO=st_area(geometry) %>% set_units('km^2')) %>% st_drop_geometry
  
  rslts %<>% bind_rows(a1 %>% left_join(a2) %>% left_join(a3))
  
  save(file=mi.rda,rslts,EOO.all,AOO.all)
  
  a1 <- mgt.slc %>% group_by(Class,Sedimentar) %>% summarise(area_ogr=sum(set_units(AREA_proj,"m^2") %>% set_units("km^2")),area_poly=sum(st_area(geometry) %>% set_units('km^2'))) %>% st_drop_geometry

  grid.area <- data.intersect %>% group_by(layer,Class,Sedimentar) %>% summarize(area = sum(area))
  grid %>% mutate(total_area=st_area(geoms)) %>% st_drop_geometry() %>% inner_join(st_drop_geometry(grid.area)) %>% mutate(p.area=(area*100/total_area) %>% drop_units)  -> AOO.grp
  a2 <- AOO.grp %>% group_by(Class,Sedimentar) %>% summarise(PROV_CODE=j,year=y,area_grid=sum(area) %>% set_units("m^2") %>% set_units("km^2"),AOO=n(),AOO_m=sum(p.area>1)) 
  
  EOO.grp <- mgt.slc %>% group_by(Class,Sedimentar) %>% summarise %>% st_convex_hull %>% mutate(EOO=st_area(geometry) %>% set_units(km^2)) 
  a3 <- EOO.grp %>% st_drop_geometry()

  rslts %<>% bind_rows(a1 %>% left_join(a2) %>% left_join(a3))
  save(file=mi.rda,rslts,EOO.all,AOO.all,EOO.grp,AOO.grp)
}
  

