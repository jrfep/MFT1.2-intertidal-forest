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


## For the larger missing provinces we will use a shortcut to approximate EOO 
faltan <- slc.2016[!slc.2016 %in% all_rslts$PROV_CODE]

rslts_approx <- tibble(PROV_CODE=numeric())

# This calculation of AOO is approximate (over-estimating area by ca. 10X) use this breaks/labels:
aoo.labs <- c("<10","10-50","50-100","100-250","250-500","500-1000",">1000")
aoo.brks <- c(0,10,50,100,250,500,1000,Inf)


for (j in faltan) {
  for (y in c(1996,2016)) {
    if (y %in% 2016) {
      # using the convex hull of the polygons instead of the polygons speeds up the processing
      mgt.2016.pols %>%  filter(PROV_CODE %in% j) %>% st_convex_hull() -> mgt.slc
    } else {
      mgt.1996.pols %>%  filter(PROV_CODE %in% j) %>% st_convex_hull() -> mgt.slc
    }
    mgt.slc %>% summarise -> out
    EOO.all <- st_convex_hull(out)
    
    raw.grid <- st_make_grid(EOO.all,cellsize=10000)
    raw.grid %>%  st_sf(layer = 1:length(raw.grid), geoms = ., stringsAsFactors = FALSE) -> grid
    
    data.intersect <- st_intersection(mgt.slc, grid) %>% mutate(area = st_area(.))
    grid.area <- data.intersect %>% group_by(layer) %>% summarize(area = sum(area))
    grid %>% mutate(total_area=st_area(geoms)) %>% st_drop_geometry() %>% inner_join(st_drop_geometry(grid.area)) %>% mutate(p.area=(area*100/total_area) %>% drop_units)  -> AOO.all
    
    a1 <- mgt.slc %>% ungroup %>% summarise(PROV_CODE=j,year=y,Class='all',Sedimentar='all',area_ogr=sum(set_units(AREA_proj,"m^2") %>% set_units("km^2")),area_poly=sum(st_area(geometry)) %>% set_units('km^2')) %>% st_drop_geometry

    a2 <- AOO.all %>% summarise(PROV_CODE=j,year=y,Class='all',Sedimentar='all',area_grid=sum(area) %>% set_units("m^2") %>% set_units("km^2"),
                                  AOO=cut(n(),breaks=aoo.brks,labels=aoo.labs))  
    a3 <- EOO.all %>% ungroup %>% summarise(PROV_CODE=j,year=y,Class='all',Sedimentar='all',EOO=st_area(geometry) %>% set_units('km^2')) %>% st_drop_geometry
    a1 %>% left_join(a2) %>% left_join(a3)
    
    rslts_approx %<>% bind_rows(a1 %>% left_join(a2) %>% left_join(a3))
  
    a1 <- mgt.slc %>% group_by(Class,Sedimentar) %>% summarise(area_ogr=sum(set_units(AREA_proj,"m^2") %>% set_units("km^2")),area_poly=sum(st_area(geometry) %>% set_units('km^2'))) %>% st_drop_geometry
    
    grid.area <- data.intersect %>% group_by(layer,Class,Sedimentar) %>% summarize(area = sum(area))
    grid %>% mutate(total_area=st_area(geoms)) %>% st_drop_geometry() %>% inner_join(st_drop_geometry(grid.area)) %>% mutate(p.area=(area*100/total_area) %>% drop_units)  -> AOO.grp
    a2 <- AOO.grp %>% group_by(Class,Sedimentar) %>% summarise(PROV_CODE=j,year=y,area_grid=sum(area) %>% set_units("m^2") %>% set_units("km^2"),AOO=cut(n(),breaks=aoo.brks,labels=aoo.labs)) 
    
    EOO.grp <- mgt.slc %>% group_by(Class,Sedimentar) %>% summarise %>% st_convex_hull %>% mutate(EOO=st_area(geometry) %>% set_units(km^2)) 
    a3 <- EOO.grp %>% st_drop_geometry()
    
    rslts_approx %<>% bind_rows(a1 %>% left_join(a2) %>% left_join(a3))
  }
}

rslts_approx

rslts_approx %>% transmute(overest=area_poly/area_ogr) %>% summarise(range(overest))

save(file=sprintf("%s/apps/L4map/assmntdata.rda",script.dir),all_rslts,rslts_approx)
