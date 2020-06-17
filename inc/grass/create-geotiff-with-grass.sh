# Maps based exclusively on ecoregions (TEOW and FEOW)
# We export these to a new mapset in R
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
r.out.gdal --overwrite input=MT1.2.IM.v2 output=tmp.tif nodata=0 createopt="COMPRESS=LZW"
gdalwarp -t_srs EPSG:3857 -r near -co COMPRESS=LZW tmp.tif ${OUTDIR}/mapbox/MT1.2.IM.orig_v2.0.tif
rm tmp.tif

  Rscript --vanilla $SCRIPTDIR/inc/R/upload-geotiff-mapbox.R ${OUTDIR}/mapbox/ MT1.2


exit
