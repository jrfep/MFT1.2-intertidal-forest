## Create matrices of species per province
# Load libraries
require(dplyr)
require(magrittr)
require(sf)
require(units)
require(vegan)

# source project env variables
source(sprintf("%s/proyectos/IUCN-GET/MFT1.2-intertidal-forest/env/project-env.R",Sys.getenv("HOME")))
setwd(work.dir)

## spatial layers
meow <- read_sf(sprintf("%s/mangrove-type-data-sources.vrt",work.dir),"meow")
mangroves <- read_sf(sprintf("%s/species-dist/global/IUCN_RLTS/MANGROVES.shp",gis.data))
mgt.2016.pols <- read_sf(sprintf("%s/eck4-mangrove-type-provs.gpkg",work.dir))

## intersection matrix
mat <- mangroves %>% st_intersects(meow,sparse=F)
colnames(mat) <- meow$ECO_CODE
rownames(mat) <- mangroves$binomial

mgv.spp <- t(mat[,colSums(mat)>0])
meow %>% filter(ECO_CODE %in% rownames(mgv.spp)) -> prov.mgv.spp

if (all((1:nrow(prov.mgv.spp))==match(rownames(mgv.spp),prov.mgv.spp$ECO_CODE))) {
  prov.mgv.spp %<>% bind_cols(n_mgv_sppp=rowSums(data.frame(mgv.spp)), data.frame(mgv.spp))
}

prov.mgv.spp %>% select(n_mgv_sppp)  %>% plot

prov.mgv.spp %>% group_by(PROV_CODE) %>% summarise %>% st_geometry %>% plot

mi.rda <- sprintf("%s/www/Rdata/mgv-species-occurrence.rda",script.dir)

save(file=mi.rda, prov.mgv.spp)


##
archs <- list.files(sprintf("%s/species-dist/global/GBIF/%s",gis.data,projectname),recursive=T,pattern='.rda$',full.names=T)

## st_wrap_dateline to solve the international date line problem:
## filter provinces with data in 2016 + Lusitania
mprov.xy <- prov.mgv.spp %>%  st_wrap_dateline() %>% st_transform(crs=st_crs(mgt.2016.pols))
plot(st_geometry(mprov.xy))

## focus only on the provinces/ecoregions
mi.rda <- sprintf("%s/www/Rdata/species-occurrence.rda",script.dir)
if (file.exists(mi.rda)) {
  load(mi.rda)
} else {
  load(grep("overview",archs,value=T))
  sppXprov <- tibble(.rows=nrow(mprov.xy))
}

for (arch in grep("occ-data-spp",archs,value=T)) {
  objs <- (load(arch))
  for (oo in objs) {
    gbif.data <- get(oo)
    for (spp in unique(names(gbif.data$gbif$data))) {
      if (!(spp %in% colnames(sppXprov)) & (nrow(gbif.data$gbif$data[[spp]])>0)) {
        xys <- gbif.data$gbif$data[[spp]] %>% dplyr::select(name,latitude,longitude,key) %>% filter(!is.na(longitude)& !is.na(latitude))
        if (nrow(xys)>0) {
          spps <- st_as_sf(xys,coords=c("longitude","latitude"),crs=st_crs(meow)) %>% st_transform(st_crs(mgt.2016.pols))
          mat <- spps %>% st_intersects(mprov.xy,sparse=F)
          sppXprov %<>% bind_cols(tibble(colSums(mat),.name_repair=~c(spp)))
        }
      }
    }
  }
}
#
# not sure why it produces duplicated names: but they seem to include the same records...
#names(spps.lt1500$gbif$data)[duplicated(names(spps.lt1500$gbif$data))]
#grep("Lycaon_pictus",names(spps.lt1500$gbif$data))

dim(sppXprov)


# For species with very large number of records, we have to summarise data with a different approach

## first step...
grdXprov <- tibble(.rows=nrow(mprov.xy))
list_spps <- c()
for (arch in grep("occ-data-grid",archs,value=T)) {
  objs <- try(load(arch))
  if (any(class(objs)=='try-error')) {
    cat(sprintf('error with %s!\n',basename(arch)))
    next
  }
  for (oo in objs) {
    gbif.data <- get(oo)
    for (spp in unique(names(gbif.data$gbif$data))) {
      if ((nrow(gbif.data$gbif$data[[spp]])>0)) {
        xys <- gbif.data$gbif$data[[spp]] %>% dplyr::select(name,latitude,longitude,key) %>% filter(!is.na(longitude)& !is.na(latitude))
        if (nrow(xys)>0) {
          list_spps <- unique(c(list_spps,spp))
          spps <- st_as_sf(xys,coords=c("longitude","latitude"),crs=st_crs(meow)) %>% st_transform(st_crs(mgt.2016.pols))
          mat <- spps %>% st_intersects(mprov.xy,sparse=F)
          grdXprov %<>% bind_cols(tibble(colSums(mat),.name_repair=~c(spp)))
        }
      }
    }
  }
}

grd2Xprov <- tibble(.rows=nrow(mprov.xy))

# second step

for (spp in list_spps) {
  grd2Xprov %<>% bind_cols(
    grdXprov %>% rowwise() %>% transmute( "{spp}" := sum(c_across(starts_with(spp))))
  )
  save(file=mi.rda,sppXprov,grd2Xprov,mangrove_species,mprov.xy)

}

## combine the two matrices into one:
sppXprov %>% bind_cols(grd2Xprov) -> mtzXprov

save(file=mi.rda,mtzXprov,mangrove_species,mprov.xy)

## alternative (discarded)
## create a regular grid ## can have problem with some ecoregions
# raw.grid <- st_make_grid(mprov.xy,cellsize=500000)
# spp.grid <- st_as_sf(tibble(code=1:length(raw.grid)),raw.grid)
# spp.grid %>% plot
# plot(st_geometry(spp.grid))
# plot(mprov.xy['PROV_CODE'],add=T)
#
# sppXcell <- tibble(.rows=length(raw.grid))
# mat <- spps %>% st_intersects(spp.grid,sparse=F)
# sppXcell %<>% bind_cols(tibble(colSums(mat),.name_repair=~c(spp)))
# save(file=mi.rda,sppXcell,sppXprov,mangrove_species,mprov.xy)
# dim(sppXcell)

# grd2Xcell <- tibble(.rows=length(raw.grid))
# grdXcell <- tibble(.rows=length(raw.grid))
#
# mat <- spps %>% st_intersects(spp.grid,sparse=F)
# grdXcell %<>% bind_cols(tibble(colSums(mat),.name_repair=~c(spp)))
# grd2Xcell %<>% bind_cols(
#   grdXcell %>% rowwise() %>% transmute( "{spp}" := sum(c_across(starts_with(spp)))))
# sppXcell %>% bind_cols(grd2Xcell)

# sppXcell %>% bind_cols(grd2Xcell) -> mtzXcell
