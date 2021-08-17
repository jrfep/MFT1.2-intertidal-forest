require(sf)
source(sprintf("%s/proyectos/IUCN-GET/MFT1.2-intertidal-forest/env/project-env.R",Sys.getenv("HOME")))
setwd(work.dir)
meow <- read_sf("mangrove-type-data-sources.vrt","meow")
meow %>% filter(PROV_CODE %in% slc) %>% group_by(PROV_CODE,PROVINCE) %>% summarise(geom=st_union(geom)) -> mprovs
ll.grid <- st_make_grid(mprovs,cellsize=5)

save(file=sprintf("%s/Rdata/grid-for-gbif-query.rda",script.dir),ll.grid)
