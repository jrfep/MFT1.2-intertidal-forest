require(dplyr)
require(units)
require(sf)
options(dplyr.summarise.inform = FALSE)
library(RPostgreSQL)


source("~/proyectos/IUCN-GET/MFT1.2-intertidal-forest/env/project-env.R")
mi.rda <- sprintf('%s/www/dbquery.rda',script.dir)

drv <- dbDriver("PostgreSQL") ## remember to update .pgpass file
con <- dbConnect(drv, dbname = dbinfo["database"],
                   host = dbinfo["host"], port = dbinfo["port"],
                   user = dbinfo["user"])
  
prg <- 
    "SELECT eco_id, eco_name, eco_name_orig, eco_name_lang, u.countries, level, membership, assigned_by, asm_id, assessment_date, overall_risk_category, risk_category_bounds,ref_code
FROM rle.assessment_get_xwalk x
LEFT JOIN rle.assessment_units u USING(eco_id) 
LEFT JOIN rle.assessment_overall o USING(eco_id) 
LEFT JOIN rle.assessments a USING(asm_id)
WHERE efg_code = 'MFT1.2'"
  
  asm_units <- dbGetQuery(con,prg)
  
  prg <- 
    "SELECT eco_id, eco_name, eco_name_orig, eco_name_lang, u.countries, level, membership, assigned_by, asm_id, assessment_date, overall_risk_category, risk_category_bounds,ref_code,u.xy_geom as geometry
FROM rle.assessment_get_xwalk x
LEFT JOIN rle.assessment_units u USING(eco_id) 
LEFT JOIN rle.assessment_overall o USING(eco_id) 
LEFT JOIN rle.assessments a USING(asm_id)
WHERE efg_code = 'MFT1.2' AND u.xy_geom IS NOT NULL"
  
  asm_xy <- read_sf(con,query=prg)    
  
  prg <- sprintf("SELECT l.eco_id,asm_id,url,url_description,ref_code,eco_name_orig FROM rle.assessment_links l LEFT JOIN rle.assessments a USING(asm_id) LEFT JOIN rle.assessment_units u ON l.eco_id=u.eco_id  WHERE l.eco_id IN ('%s') OR (l.eco_id IS NULL AND asm_id IN ('%s'))", paste(asm_units$eco_id, collapse="','"), paste(unique(asm_units$asm_id), collapse="','"))
  
  asm_links <- dbGetQuery(con,prg)
  
  prg <- sprintf("SELECT asm_id,ref_code,assessment_protocol_code,risk_category_code,name,countries,asm_type,status FROM rle.assessments WHERE asm_id IN ('%s')", paste(asm_units$asm_id, collapse="','"))
  
  assessments <- dbGetQuery(con,prg)
  
  
  
  prg <- sprintf("SELECT * FROM ref_list WHERE ref_code IN ('%s')", paste(assessments$ref_code, collapse="','"))
  
  references <- dbGetQuery(con,prg)
  dbDisconnect(con)
  
  save(file=mi.rda,asm_units,asm_links,assessments,references,asm_xy)
