#!/usr/bin/R --vanilla
require(dplyr)
require(magrittr)
require(readr)
require(RPostgreSQL)
require(sf)

source(sprintf("%s/proyectos/IUCN-GET/MFT1.2-intertidal-forest/env/project-env.R",Sys.getenv("HOME")))
setwd(work.dir)

drv <- dbDriver("PostgreSQL") ## remember to update .pgpass file

con <- dbConnect(drv, dbname = dbinfo['database'],
              host = dbinfo['host'],
              port = dbinfo['port'],
              user = dbinfo['user'])

mgt.meow.its <- read_sf("intersection-type-meow-provs.gpkg")

mgt.meow.its %>% st_drop_geometry -> mgt.table

mgt.table %>% distinct(Class,Sedimentar,PROV_CODE,PROVINCE) %>% mutate(GT=as.numeric(as.factor(Class))*10 + as.numeric(as.factor(Sedimentar))) -> smr.table

smr.table %>% transmute(qry=
  str_glue(
    "INSERT INTO  bio_geo_ecotype (bge_code,code,name,shortdesc,status,contributors)
    VALUES(
      'MFT1.2-MP{PROV_CODE}-GT{GT}','MFT1.2','MFT1.2 Intertidal forests and shrublands of biophysical type *{Class} ({Sedimentar})* in the *{PROVINCE}* province', 'Spatial overlap of Global biophysical typology of mangroves (class={Class} and sedimentar={Sedimentar}) and the marine province of {PROVINCE} (PROV_CODE={PROV_CODE}).','draft','{{JRFP,Global Mangrove Alliance}}'
    ) ON CONFLICT DO NOTHING")) %>% pull-> qries

for (qry in qries) {
  dbSendQuery(con,qry)
}

mgt.meow.its %>% group_by(Class,Sedimentar,PROV_CODE) %>% summarise(area=sum(st_area(geometry))) -> mgt.area
