cd $WORKDIR

conda deactivate
grass --text ${GISDB}/ecosphere/earth/PERMANENT
g.mapset -c update_IM
g.region n=90 s=-90 e=180 w=-180 res=0.008333333333333

## Dark and pale red colors...
echo "
1 193:15:2:255
2 247:157:150:255
" > DumparkMapColors.txt

## get the wkb_geometry column
v.in.ogr input="PG:host=localhost dbname=gisdata user=jferrer" layer=wcmc.mangroveusgs2011_v1_3 output=WCMC_mangroves geometry=wkb_geometry
## do the union first in postgis and then import, much faster
v.in.ogr input="PG:host=localhost dbname=gisdata user=jferrer" layer=wcmc.mangrove_buffer output=WCMC_mangroves_buffer

v.to.rast input=WCMC_mangroves output=MFT1.2_major use=val
v.to.rast input=WCMC_mangroves_buffer output=MFT1.2_minor use=val
 r.mapcalc --overwrite expression="MFT1.2.IM.v2=if(MFT1.2_minor,if(isnull(MFT1.2_major),2,1))"
r.stats -ac MFT1.2_major,MFT1.2_minor,MFT1.2.IM.v2

r.colors map=MFT1.2.IM.v2 rules=DumparkMapColors.txt


export OUTDIR=$WORKDIR/grass_output
mkdir -p $OUTDIR/mapbox
r.out.gdal --overwrite input=MFT1.2.IM.v2 output=tmp.tif nodata=0 createopt="COMPRESS=LZW"
gdalwarp -t_srs EPSG:3857 -r near -co COMPRESS=LZW tmp.tif ${OUTDIR}/mapbox/MFT1.2.web.orig_v2.0.tif
rm tmp.tif

export target=MFT1.2

psql -d iucn_ecos -c "UPDATE  map_metadata SET status='replaced',update=CURRENT_TIMESTAMP(0) where code='${target}' AND map_type='Web navigation'"
psql -d iucn_ecos -c "INSERT INTO map_metadata(code,map_code,map_version,map_type,status,map_source,contributors) VALUES ('${target}','${target}.web.orig','v2.0','Web navigation','TO DO','The indicative map of Intertidal forests and shrublands (MFT1.2) was developed by resampling the known global distribution of mangrove forests for the year 2000 mapped by Giri et al. (2011). We used a buffer of 1km around the distribution data and a 30 arc second grid, thus large aggregations (> 1km<sup>2</sup>) are depicted as major occurrences, and the buffer areas with small occurrences are shown as minor occurrences. The original high-resolution data is available at [UNEP-WCMC](http://data.unep-wcmc.org/datasets/4).','{JR Ferrer-Paris,DA Keith}') ON CONFLICT ON CONSTRAINT map_metadata_pkey DO UPDATE SET (map_source,contributors,status,update)=(EXCLUDED.map_source,EXCLUDED.contributors,'UPDATE',CURRENT_TIMESTAMP(0))"
psql -d iucn_ecos -c "INSERT INTO map_references(map_code,map_version,ref_code,source_of,dataset) VALUES ('${target}.web.orig','v2.0','Giri C et al. 2011','modeled and validated distribution from remote sensors','USGS-Mangroves-2011') ON CONFLICT DO NOTHING"

UPDATE map_metadata set map_source='Freshwater ecoregions containing major or minor occurrences of this functional group were identified by consulting available ecoregion descriptions (Abell et al. 2008), global and regional reviews, maps of relevant ecosystems, and expertise of authors.' where map_source like 'Freshwater ecoregions containing major or minor occurrences this functional group were identified by consulting available ecoregion descriptions (Abell et al. 2008), global and regional reviews, maps of relevant ecosystems, and expertise of authors.'

Rscript --vanilla $SCRIPTDIR/inc/R/upload-geotiff-mapbox.R ${OUTDIR}/mapbox/ MFT1.2 "from mangrove map"

exit
