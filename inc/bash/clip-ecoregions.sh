#!/usr/bin/bash
MIBIOME=$1

ogr2ogr -f "GPKG" teow.gpkg $WORKDIR/Ecoregions2017.shp Ecoregions2017 -where "ECO_BIOME_='${MIBIOME}'" -nlt PROMOTE_TO_MULTI -t_srs "+proj=longlat +datum=WGS84" -makevalid

export SPAT=$(ogrinfo teow.gpkg -al | grep Extent | cut -d: -f2 | sed -e "s/) \- (/ /g" -e s/,//g -e s/[\(\)]//g)

ogr2ogr -f "GPKG" mangrove.gpkg -spat $SPAT $WORKDIR/01_Data/GMW_2016_v2.shp GMW_2016_v2 -nln mangroves -nlt PROMOTE_TO_MULTI -makevalid

ogr2ogr -f "GPKG" clip.gpkg mangrove.gpkg -clipsrc teow.gpkg
