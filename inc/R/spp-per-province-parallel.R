## Create matrices of species per province
# Load libraries
require(dplyr)
require(magrittr)
require(sf)
require(parallel)
require(doParallel)

# source project env variables
source(sprintf("%s/proyectos/IUCN-GET/MFT1.2-intertidal-forest/env/project-env.R",Sys.getenv("HOME")))
setwd(work.dir)



# this could be a nice excercise for parallelization with foreach + %dopar%

cl <- parallel::makeCluster(detectCores())
doParallel::registerDoParallel(cl)


## spatial layers
meow <- read_sf(sprintf("%s/mangrove-type-data-sources.vrt",work.dir),"meow")
mangroves <- read_sf(sprintf("%s/species-dist/global/IUCN_RLTS/MANGROVES.shp",gis.data))
## mgt.2016.pols <- read_sf(sprintf("%s/eck4-mangrove-type-provs.gpkg",work.dir))
## st_crs(mgt.2016.pols)$proj4string
eck4.p4s <- "+proj=eck4 +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs "


## intersection matrix
mat <- mangroves %>% st_intersects(meow,sparse=F)
colnames(mat) <- meow$ECO_CODE
rownames(mat) <- mangroves$binomial

mgv.spp <- t(mat[,colSums(mat)>0])
meow %>% filter(ECO_CODE %in% rownames(mgv.spp)) -> prov.mgv.spp

if (all((1:nrow(prov.mgv.spp))==match(rownames(mgv.spp),prov.mgv.spp$ECO_CODE))) {
  prov.mgv.spp %<>% bind_cols(n_mgv_sppp=rowSums(data.frame(mgv.spp)), data.frame(mgv.spp))
}

mprov.xy <- prov.mgv.spp %>%  st_wrap_dateline() %>% st_transform(crs=eck4.p4s)
plot(st_geometry(mprov.xy))

archs <- list.files(sprintf("%s/species-dist/global/GBIF/%s",gis.data,projectname),recursive=T,pattern='.rda$',full.names=T)

##crs1 <- st_crs(meow)$proj4string
#"+proj=longlat +datum=WGS84 +no_defs "


gbif2grid <- function(a,xypol) {
  objs <- try(load(a))
  gXp <- tibble(.rows=nrow(xypol))
  if (any(class(objs)=='try-error')) {
    cat(sprintf('error with %s!\n',basename(a)))
  } else {
    for (oo in objs) {
      gbif.data <- get(oo)
      for (spp in unique(names(gbif.data$gbif$data))) {
        if ((nrow(gbif.data$gbif$data[[spp]])>0)) {
          xys <- gbif.data$gbif$data[[spp]] %>% dplyr::select(name,latitude,longitude,key) %>% filter(!is.na(longitude)& !is.na(latitude))
          if (nrow(xys)>0) {
            spps <- st_as_sf(xys,coords=c("longitude","latitude"),crs="+proj=longlat +datum=WGS84 +no_defs ") %>% st_transform("+proj=eck4 +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs ")
            mat <- spps %>% st_intersects(xypol,sparse=F)
            gXp %<>% bind_cols(tibble(colSums(mat),.name_repair=~c(spp)))
          }
        }
      }
    }
    return(gXp)
  }
}


slc.arch <- grep("occ-data-spp|occ-data-grid",archs,value=T)

time_foreach <- system.time({
  sppXprov <- foreach::foreach(
    i = 1:length(slc.arch),
    .combine = bind_cols,
    .packages = c("dplyr","magrittr","sf")) %dopar% {
      gbif2grid(slc.arch[i],mprov.xy)
    }
})
## with 16 cores:
# time_foreach
#    user  system elapsed
# 4.420   1.491 223.346
length(slc.arch)
dim(sppXprov)

# second step
list_spps <- unique(gsub("...[0-9]+","",colnames(sppXprov)))
length(list_spps)

time_foreach <- system.time({
  mtzXprov <- foreach::foreach(
    i = 1:length(list_spps),
    .combine = bind_cols,
    .packages = c("dplyr","magrittr","sf")) %dopar% {
      spp = list_spps[i]
      sppXprov %>% rowwise() %>% transmute( "{spp}" := sum(c_across(starts_with(spp))))
    }
})
## time_foreach
##  user  system elapsed
##  44.023   1.672 105.683

# going serial:
# time_foreach <- system.time({
#   grd2Xprov <- tibble(.rows=nrow(mprov.xy))
# for (spp in list_spps) {
#   grd2Xprov %<>% bind_cols(
#     grdXprov %>% rowwise() %>% transmute( "{spp}" := sum(c_across(starts_with(spp))))
#   )}
# })
#time_foreach
#   user  system elapsed
# 35.475   1.334  36.804

mi.rda <- sprintf("%s/www/Rdata/species-occurrence-test.rda", script.dir)

save(file=mi.rda,mtzXprov,mangrove_species,mprov.xy)

parallel::stopCluster(cl)
