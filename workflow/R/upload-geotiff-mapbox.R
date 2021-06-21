#!R --vanilla
require(jsonlite)
require("RPostgreSQL")

work.dir <- Sys.getenv("WORKDIR")
setwd(work.dir)

args <- commandArgs(TRUE)
if (length(args)==3) {
  upload.dir <- args[1]
  EFG <- args[2]
  mapdesc <- args[3]
} else {
  print("something is missing")
  q()
}


drv <- dbDriver("PostgreSQL") ## remember to update .pgpass file
con <- dbConnect(drv, dbname = "iucn_ecos",
                 host = ifelse( system("hostname -s",intern=T)=="terra","localhost","terra.ad.unsw.edu.au"),
                 port = 5432,
                 user = "jferrer")

qry <- sprintf("select map_code,map_version,map_url,status from map_metadata where code='%s' and map_type='Web navigation'",EFG);

res <- dbGetQuery(con,qry)

res <- subset(res,status %in% c("TO DO","UPDATE"))
upload.arch <- sprintf("%s_%s.tif",res$map_code,res$map_version)
tile.name <- gsub("\\.","_",res$map_code)


if (nrow(res)!=1 | !file.exists(sprintf("%s/%s",upload.dir,upload.arch))) {
  print("Need to fix this code!")
} else {


  MB.token <- readLines("~/.mapbox.upload.token")
  MB.user <- "jrfep"
  rslt <- system(sprintf("curl -X POST https://api.mapbox.com/uploads/v1/%s/credentials?access_token=%s",MB.user,MB.token),intern=T)
  dts <-  parse_json(rslt)

  Sys.setenv( AWS_ACCESS_KEY_ID=dts$accessKeyId,
    AWS_SECRET_ACCESS_KEY=dts$secretAccessKey,
    AWS_SESSION_TOKEN=dts$sessionToken)

  system(sprintf("aws s3 cp %s/%s s3://%s/%s --region us-east-1",upload.dir,upload.arch,dts$bucket,dts$key))

  rslt <- system(sprintf("curl -X POST -H \"Content-Type: application/json\" -H \"Cache-Control: no-cache\" -d '{
    \"url\": \"%1$s\",
    \"tileset\": \"%2$s.%3$s\",
    \"name\": \"Indicative map %5$s %6$s\"
  }' https://api.mapbox.com/uploads/v1/%2$s?access_token=%4$s
  ", dts$url, MB.user, tile.name, MB.token, EFG, mapdesc),intern=T)

  final <- parse_json(rslt)
  qry <- sprintf("UPDATE map_metadata SET map_url='https://studio.mapbox.com/tilesets/%s',update='%s',status='UPLOADED' WHERE map_code='%s' AND map_version='%s'",final$tileset,final$modified,res$map_code,res$map_version)
  dbSendQuery(con,qry)
  print(final)

}


dbDisconnect(con)
