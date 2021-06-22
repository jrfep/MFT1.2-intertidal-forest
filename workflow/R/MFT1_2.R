#!R --vanilla
require(dplyr)
require(magrittr)
require(sf)
require(units)
require(raster)
require(readr)
require(stringr)
require(ggplot2)
require(units)

source(sprintf("%s/proyectos/UNSW/MFT1.2-intertidal-forest/env/project-env.R",Sys.getenv("HOME")))
work.dir <- sprintf("/srv/scratch/%s/tmp/GET-indicative-maps-GIS/",Sys.getenv("USER"))
gis.data <- sprintf("/srv/scratch/cesdata/gisdata")
setwd(work.dir)

(load("GMW-2016-agg-TEOW.rda"))
all_ecoregs %>% pull(ready) %>% table
all_ecoregs %>% pull(fallos) %>% table

rda.dir <- sprintf("%s/Rdata",work.dir)
total_ecoreg <- tibble()
rslts_teow <- tibble()
for (k in dir(rda.dir,"TEOW")) {
  load(sprintf("%s/Rdata/%s",work.dir,k))
  total_ecoreg %<>% bind_rows(all_ecoregs)
  rslts_teow %<>% bind_rows(rslts.teow)

}

total_ecoreg %>% pull(ready) %>% table
total_ecoreg %>% pull(fallos) %>% table
# who is missing :
total_ecoreg %>% filter(!ready) %>% pull(ECO_BIOME_) %>% table

nrow(rslts_teow)
total_ecoreg %>%  filter(ready & intersection_rows>0)
total_ecoreg %>%  filter(ready & crop_rows>0)

rslts_teow %>% filter(area>set_units(0,"m^2"))

rslts_teow %>% slice_head()
rslts_teow %>% summarise(n=n(),nfid=n_distinct(ogc_fid),neco=n_distinct(ECO_ID),total_area=sum(area)/1e6)
rslts_teow %>% group_by(ECO_ID) %>% summarise(total_area=sum(drop_units(area)/1e6,na.rm=T),n_polygons=n_distinct(ogc_fid),x=weighted.mean(lon,weight=area),y=weighted.mean(lat,weight=area)) %>% filter(total_area > 0 )-> rsm.teow

## check AF01 (previously  errors in the Niger Delta due to invalid polygons)
total_ecoreg %>% filter(ECO_BIOME_ %in% "AF01" & ready) %>% dplyr::select(ECO_NAME,ready,fallos,crop_rows,intersection_rows) %>%  print.AsIs()



## LME
(load(sprintf("%s/Rdata/%s",work.dir,dir(rda.dir,"LME"))))

all_lmes %>%  pull(ready) %>% table
nrow(rslts.lmes)
rslts.lme %>% group_by(LME_NUMBER) %>% summarise(total_area=sum(drop_units(area)/1e6),n_polygons=n_distinct(ogc_fid),x=weighted.mean(lon,weight=area),y=weighted.mean(lat,weight=area)) -> rsm.lme


## validated polygons using ogr2ogr
mgv <- read_sf(sprintf("%s/ecosystems/global/WCMC-mangroves-GMW/GMW-valid-output/GMW_2016_valid.gpkg",gis.data))


## LME
mgv.lme <- read_sf("intersection-lmes.gpkg")
mgv.lme %>% mutate(area=st_area(geometry),centroid=st_centroid(geometry)) %>% st_drop_geometry  %>% transmute(oid,LME_NUMBER,area,lon=st_coordinates(centroid)[,1],lat=st_coordinates(centroid)[,2]) -> rslts.lme

rslts.lme %>% group_by(LME_NUMBER) %>% summarise(total_area=sum(drop_units(area)/1e6),n_polygons=n_distinct(oid),x=weighted.mean(lon,weight=area),y=weighted.mean(lat,weight=area)) -> rsm.lme


## this is for MEOW intersection:
mgv.meow <- read_sf("intersection-meow.gpkg")
mgv.meow %>% mutate(area=st_area(geometry),centroid=st_centroid(geometry)) %>% st_drop_geometry  %>% transmute(oid,ECO_CODE,area,lon=st_coordinates(centroid)[,1],lat=st_coordinates(centroid)[,2]) -> rslts.meow

rslts.meow %>% group_by(ECO_CODE) %>% summarise(total_area=sum(drop_units(area)/1e6),n_polygons=n_distinct(oid),x=weighted.mean(lon,weight=area),y=weighted.mean(lat,weight=area)) -> rsm.meow


rsm.meow %>% summarise(range(x),range(y))
rsm.teow %>% summarise(range(x),range(y))
rsm.lme %>% summarise(range(x),range(y))

world <- map_data("world")

world.plot <- ggplot() +
  geom_map(
    data = world, map = world,
    aes(long, lat, map_id = region),
    color = "rosybrown3", fill = "antiquewhite", size = 0.1)  +  theme_void()


p1 <- world.plot +  expand_limits(x = rsm.teow$x, y = rsm.teow$y)+  theme_void() + labs(title=sprintf("Mangrove polygons (from GMW 2016) aggregated by Terrestrial Ecoregions: %s distinct units", nrow(rsm.teow)),caption="Circles indicate centroid of group",color = "Nr. of polygons",size="Area [km^2]") +
  geom_point(data=rsm.teow,aes(x=x,y=y,size=total_area,color=n_polygons)) + coord_fixed(xlim = c(-180, 180), ylim = c(-40, 40))

p2 <- world.plot + labs(title=sprintf("Mangrove polygons (from GMW 2016) aggregated by Marine Ecoregions: %s distinct units", nrow(rsm.meow)),caption="Circles indicate centroid of group",color = "Nr. of polygons",size="Area [km^2]") +
  geom_point(data=rsm.meow,aes(x=x,y=y,size=total_area,color=n_polygons)) + coord_fixed(xlim = c(-180, 180), ylim = c(-40, 40))


p3 <- world.plot + labs(title=sprintf("Mangrove polygons (from GMW 2016) aggregated by Large Marine Ecosystems: %s distinct units", nrow(rsm.lme)),caption="Circles indicate centroid of group",color = "Nr. of polygons",size="Area [km^2]") +
  geom_point(data=rsm.lme,aes(x=x,y=y,size=total_area,color=n_polygons)) + coord_fixed(xlim = c(-180, 180), ylim = c(-40, 40))

## with ggpubr
##ggarrange(p1,p2,common.legend = TRUE)

# this includes all polygons in the marine, but not all in the terrestrial
rslts.meow %>% summarise(total=n_distinct(oid))
rslts_teow %>% summarise(total=n_distinct(ogc_fid))
rslts.lme %>% summarise(total=n_distinct(oid))

work.dir
ggsave(plot=p2,file=sprintf('%s/Mangrove-aggregated-by-Marine-ecoregions.pdf',work.dir),device=pdf)
ggsave(plot=p1,file=sprintf('%s/Mangrove-aggregated-by-Terrestrial-ecoregions.pdf',work.dir),device=pdf)

qry <- read_csv( file="query/list_units.csv")
qry %>% summarise(n_oid=n_distinct(oid),total=n())
qry %>% group_by(ECO_CODE) %>% summarise(count=n(),total_area=sum(area))

r1 <- raster("output-GeoTiff/MFT1.2.IM.orig.v3.0.tif")
plot(r1,col=c('black','red'))

##summary(values(r1))
table(values(r1))
#0         2
#933110513      9487

e <- extent(-74,-57,7,13)
r2 <- crop(r1,e)
##NAvalue(r2) <- 0
plot(r2,col=c('black','red'))

tst <- read_sf("mangrove_ll.gpkg")

mgv.meow <- read_sf("intersection-meow.gpkg")
plot(st_geometry(tst))


mgv <- read_sf("mangrove_type_1996.gpkg")
tst <- head(mgv)
tst %<>% mutate(buffer=st_buffer(geom,1000))

tst  %>% group_by(class) %>% summarise(count=n(),area=sum(AREA_proj))

tst %>% filter(AREA_proj < set_units(1e6, m^2)) %>% group_by(class) %>% summarise(total=n())
