#!R --vanilla
require(dplyr)
require(magrittr)
require(sf)
require(units)
require(readr)
require(stringr)
require(units)

args = commandArgs(trailingOnly=TRUE)
biome <- args[1]

work.dir <- Sys.getenv("WORKDIR")
gis.data <- Sys.getenv("GISDATA")
setwd(work.dir)
system(sprintf("mkdir -p %s/Rdata",work.dir))

rda.file <- sprintf("%s/Rdata/GMW-2016-agg-TEOW-%s.rda",work.dir,biome)
if (file.exists(rda.file)) {
   load(rda.file)
}

## using individual ecoregion polygons with spatially valid polygons
teow.valid.dir <- sprintf("%s/ecoregions/global/TEOW/teow2017-valid-output/%s",gis.data,biome)

## original data contains invalid polygons
##mgv.iv <- read_sf("01_Data/GMW_2016_v2.shp")

## validated polygons using ogr2ogr
mgv <- read_sf(sprintf("%s/ecosystems/global/WCMC-mangroves-GMW/GMW-valid-output/GMW_2016_valid.gpkg",gis.data))

if (!exists("all_ecoregs")) {
   all_ecoregs <- read_csv(sprintf("%s/../Ecoregions2017.csv", teow.valid.dir))

   all_ecoregs %<>% mutate(ready=FALSE,crop_rows=as.integer(0),intersection_rows=as.integer(0),fallos=NA) %>% filter(ECO_BIOME_ %in% biome)
}

## exclude rocks and ice polygon
all_ecoregs %<>% mutate(
   ready=if_else(ECO_ID %in% 0, TRUE, ready),
               fallos=if_else(ECO_ID %in% 0 , FALSE, fallos))

if (!exists("rslts.teow")) {
   rslts.teow <- tibble()
}

all.files  <- list.files(teow.valid.dir, "gpkg", recursive=T, full.names=T)

for (arch in sample(all.files)) {
   codes <- gsub("teow|/|.gpkg","", gsub(teow.valid.dir,"",arch)) %>% str_split("_",simplify = T)
   all_ecoregs %>% filter(ECO_ID %in% codes[1,2]) -> slc
   if (slc %>% pull(ready)) {
      cat(sprintf("Ecoregion %s has already been added\n",
      slc %>% pull(ECO_NAME)))
   } else {
      teow <- try(read_sf(arch))
      if (any(class(teow) %in% "try-error")) {
         slc %>% transmute(message=sprintf("problem with %s\n", ECO_NAME)) %>% pull %>% cat

         all_ecoregs %<>% mutate(
            ready=if_else(ECO_ID %in% codes[1,2], TRUE, ready),
            fallos=if_else(ECO_ID %in% codes[1,2], TRUE, fallos)
         )
         save(file=rda.file,all_ecoregs,rslts.teow)

         break
      }
      if (!st_is_valid(teow)) {
         teow %<>% st_make_valid()
         slc %>% transmute(message=sprintf("polygon for %s required a fix, done !\n", ECO_NAME)) %>% pull %>% cat
      } else {
         slc %>% transmute(message=sprintf("polygon for %s is valid, moving on...\n", ECO_NAME)) %>% pull %>% cat
      }

      mgv.clip <- try(st_crop(mgv,teow))
      if (any(class(mgv.clip) %in% "try-error")) {
         slc %>% transmute(message=sprintf("problem with %s\n", ECO_NAME)) %>% pull %>% cat

         all_ecoregs %<>% mutate(
            ready=if_else(ECO_ID %in% codes[1,2], TRUE, ready),
            fallos=if_else(ECO_ID %in% codes[1,2], TRUE, fallos)
         )
         save(file=rda.file,all_ecoregs,rslts.teow)

         break
      }


      if (nrow(mgv.clip)>0) {
         mgv.clip %>% mutate(centroid=st_centroid(geom)) %>% transmute(ogc_fid, ECO_BIOME_=teow$ECO_BIOME_, ECO_ID=teow$ECO_ID, lon=st_coordinates(centroid)[,1], lat=st_coordinates(centroid)[,2]) %>% st_drop_geometry() -> clip.rslt

         plot(st_geometry(teow),border = "rosybrown3", col = "antiquewhite")
         plot(st_geometry(mgv.clip), add=T, col="darkgreen", border="palegreen")

         ## xcross <- st_intersection(mgv.clip,teow)
         ## dist.matrix <- st_distance(mgv.clip,teow)
         xcross <- st_intersection(st_make_valid(mgv.clip),teow)

         xcross %>% mutate(centroid=st_centroid(geom)) %>% transmute(ogc_fid, ECO_BIOME_, ECO_ID, area=st_area(geom)) %>% st_drop_geometry() %>% full_join(clip.rslt, by = c("ogc_fid", "ECO_BIOME_", "ECO_ID")) %>% rbind(rslts.teow) -> rslts.teow

         cat(sprintf("Ecoregion %s : %s rows added, result tibble with %s rows \n", slc %>% pull(ECO_NAME), nrow(mgv.clip), nrow(rslts.teow)))
         all_ecoregs %<>% mutate(
               ready=if_else(ECO_ID %in% codes[1,2], TRUE, ready),
               crop_rows=if_else(ECO_ID %in% codes[1,2], nrow(mgv.clip), crop_rows),
               intersection_rows=if_else(ECO_ID %in% codes[1,2], nrow(xcross), intersection_rows),
               fallos=if_else(ECO_ID %in% codes[1,2] , FALSE, fallos))

         all_ecoregs %>% summarise(ready=sum(ready),total=n()) %>% transmute(sprintf("We have completed %s from %s ecoregions so far. \n",ready,total))   %>% pull %>% cat
         save(file=rda.file,all_ecoregs,rslts.teow)

            #stop("debugging: detener para revisar resultados")
      } else  {
            cat(sprintf("Ecoregion %s has no mangroves\n",teow$ECO_NAME))
            all_ecoregs %<>% mutate(
               ready=if_else(ECO_ID %in% codes[1,2], TRUE, ready),
                           fallos=if_else(ECO_ID %in% codes[1,2] , FALSE, fallos))
           save(file=rda.file,all_ecoregs,rslts.teow)

      }
   }
}
all_ecoregs %>%  filter(ready)
all_ecoregs %>% filter(fallos)
nrow(rslts.teow)

save(file=rda.file,all_ecoregs,rslts.teow)
