#!R --vanilla
require(dplyr)
require(magrittr)
require(sf)
require(units)
require(readr)
require(stringr)
require(units)

work.dir <- Sys.getenv("WORKDIR")
gis.data <- Sys.getenv("GISDATA")
setwd(work.dir)
system(sprintf("mkdir -p %s/Rdata",work.dir))

rda.file <- sprintf("%s/Rdata/GMW-2016-agg-LMES.rda",work.dir)
if (file.exists(rda.file)) {
   load(rda.file)
}

## LME valid polygons
lmes <- read_sf(sprintf("%s/ecoregions/global/LME/lmes_64_valid.gpkg",gis.data))

## original data contains invalid polygons
##mgv.iv <- read_sf("01_Data/GMW_2016_v2.shp")

## validated polygons using ogr2ogr
mgv <- read_sf(sprintf("%s/ecosystems/global/WCMC-mangroves-GMW/GMW-valid-output/GMW_2016_valid.gpkg",gis.data))

if (!exists("all_lmes")) {
   all_lmes <- lmes %>% arrange(LME_NUMBER) %>% st_drop_geometry()

   all_lmes %<>% mutate(ready=FALSE,crop_rows=as.integer(0),intersection_rows=as.integer(0),fallos=NA)
}

## exclude rocks and ice polygon
##all_ecoregs %<>% mutate(
##  ready=if_else(ECO_ID %in% 0, TRUE, ready),
##               fallos=if_else(ECO_ID %in% 0 , FALSE, fallos))

if (!exists("rslts_lmes")) {
   rslts_lmes <- tibble()
}

for (target in sample(1:63)) { #1:63
   all_lmes %>% filter(LME_NUMBER %in% target) -> slc
   if (slc %>% pull(ready)) {
      cat(sprintf("LME %s has already been added\n",
      slc %>% pull(LME_NAME)))
   } else {
      lmes %>% filter(LME_NUMBER %in% target) -> slc.lme

      mgv.clip <- try(st_crop(mgv,slc.lme))
      if (any(class(mgv.clip) %in% "try-error")) {
         slc %>% transmute(message=sprintf("problem with %s\n", LME_NAME)) %>% pull %>% cat

         all_lmes %<>% mutate(
            ready=if_else(LME_NUMBER %in% target, TRUE, ready),
            fallos=if_else(LME_NUMBER %in% target, TRUE, fallos)
         )
         save(file=rda.file,all_lmes,rslts_lmes)

         break
      }

      if (nrow(mgv.clip)>0) {
         mgv.clip %>% mutate(centroid=st_centroid(geom)) %>% transmute(ogc_fid, LME_NUMBER=target, lon=st_coordinates(centroid)[,1], lat=st_coordinates(centroid)[,2]) %>% st_drop_geometry() -> clip.rslt

         plot(st_geometry(slc.lme),border = "rosybrown3", col = "antiquewhite")
         plot(st_geometry(mgv.clip), add=T, col="darkgreen", border="palegreen")

         ## xcross <- st_intersection(mgv.clip,teow)
         ## dist.matrix <- st_distance(mgv.clip,teow)
         xcross <- st_intersection(mgv.clip,slc.lme)

         xcross %>% mutate(centroid=st_centroid(geom)) %>% transmute(ogc_fid, LME_NUMBER, area=st_area(geom)) %>% st_drop_geometry() %>% full_join(clip.rslt, by = c("ogc_fid", "LME_NUMBER")) %>% rbind(rslts_lmes) -> rslts_lmes

         cat(sprintf("Ecoregion %s : %s rows added, result tibble with %s rows \n", slc %>% pull(LME_NAME), nrow(mgv.clip), nrow(rslts_lmes)))
         all_lmes %<>% mutate(
               ready=if_else(LME_NUMBER %in% target, TRUE, ready),
               crop_rows=if_else(LME_NUMBER %in% target, nrow(mgv.clip), crop_rows),
               intersection_rows=if_else(LME_NUMBER %in% target, nrow(xcross), intersection_rows),
               fallos=if_else(LME_NUMBER %in% target , FALSE, fallos))

         all_lmes %>% summarise(ready=sum(ready),total=n()) %>% transmute(sprintf("We have completed %s from %s LMEs so far. \n",ready,total))   %>% pull %>% cat
         save(file=rda.file,all_lmes,rslts_lmes)

            #stop("debugging: detener para revisar resultados")
      } else  {
            cat(sprintf("LME %s has no mangroves\n",slc %>% pull(LME_NAME)))
            all_lmes %<>% mutate(
               ready=if_else(LME_NUMBER %in% target, TRUE, ready),
                           fallos=if_else(LME_NUMBER %in% target , FALSE, fallos))
           save(file=rda.file,all_lmes,rslts_lmes)

      }
   }
}
all_lmes %>%  filter(ready)
all_lmes %>% filter(fallos)
nrow(rslts_lmes)
save(file=rda.file,all_lmes,rslts_lmes)
