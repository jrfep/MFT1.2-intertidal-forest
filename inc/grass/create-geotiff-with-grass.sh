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
## get the buffer column (this is terribly slow, probably due to the overlap of polygons)
v.in.ogr input="PG:host=localhost dbname=gisdata user=jferrer" layer=wcmc.mangroveusgs2011_v1_3 output=WCMC_mangroves_buffer geometry=buffer

v.to.rast input=WCMC_mangroves output=MFT1.2_major use=val
v.to.rast input=WCMC_mangroves_buffer output=MFT1.2_minor use=val
r.colors map=MFT1.2_major rules=DumparkMapColors.txt





 ## merge all together with resolution near 1km using average vlaues and LZW compression
 gdalwarp --config GDAL_CACHEMAX 2000 -wm 2000 $(find . -wholename "*.tif") -co "COMPRESS=LZW" -tr 0.00833 0.00833 -r average merged.tif
 ## half minute
 gdalwarp --config GDAL_CACHEMAX 2000 -wm 2000 $(find . -wholename "*.tif") -co "COMPRESS=LZW" -tr 0.00833 0.00833 -r max MT1.2.30s.max.tif
## 5 minute
 gdalwarp --config GDAL_CACHEMAX 2000 -wm 2000 $(find . -wholename "*.tif") -co "COMPRESS=LZW" -tr 0.0833 0.0833 -r max MT1.2.10m.max.tif


 r.in.gdal --overwrite input=MT1.2.10m.max.tif output=MT1.2.minor
 r.in.gdal --overwrite input=MT1.2.30s.max.tif output=MT1.2.major
 r.mapcalc --overwrite expression="MT1.2.IM.v2=if(MT1.2.major,1,if(MT1.2.minor,2,null()))"
##r.null map=MT1.2.IM.v2 setnull=0
#r.colors map=MT1.2.IM.v2  color=greens
r.colors map=MT1.2.IM.v2 rules=DumparkMapColors.txt



export OUTDIR=$WORKDIR/grass_output
mkdir -p $OUTDIR/mapbox
r.out.gdal --overwrite input=MT1.2.IM.v2 output=tmp.tif nodata=0 createopt="COMPRESS=LZW"
gdalwarp -t_srs EPSG:3857 -r near -co COMPRESS=LZW tmp.tif ${OUTDIR}/mapbox/MT1.2.IM.orig_v2.0.tif
rm tmp.tif

  Rscript --vanilla $SCRIPTDIR/inc/R/upload-geotiff-mapbox.R ${OUTDIR}/mapbox/ MT1.2


exit
