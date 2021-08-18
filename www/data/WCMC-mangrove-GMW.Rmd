# Global Mangrove Watch (1996 - 2016)

> The GMW aims to provide geospatial information about mangrove extent and changes to the Ramsar Convention, national wetland practitioners, decision makers and NGOs. It is part of the Ramsar Science and Technical Review Panel (STRP) work plan for 2016-2018 and a Pilot Project to the Ramsar Global Wetlands Observation System (GWOS), which is implemented under the GEO-Wetlands Initiative. The primary objective of the GMW has been to provide countries lacking a national mangrove monitoring system with first cut mangrove extent and change maps, to help safeguard against further mangrove forest loss and degradation.

> The GMW has generated a global baseline map of mangroves for 2010 using ALOS PALSAR and Landsat (optical) data, and changes from this baseline for six epochs between 1996 and 2016 derived from JERS-1 SAR, ALOS PALSAR and ALOS-2 PALSAR-2. Annual maps are planned from 2018 and onwards.

## Citation

> Bunting P., Rosenqvist A., Lucas R., Rebelo L-M., Hilarides L., Thomas N., Hardy A., Itoh T., Shimada M. and Finlayson C.M. (2018). The Global Mangrove Watch – a New 2010 Global Baseline of Mangrove Extent. Remote Sensing 10(10): 1669. doi: 10.3390/rs1010669.

> Thomas N, Lucas R, Bunting P, Hardy A, Rosenqvist A, Simard M. (2017). Distribution and drivers of global mangrove forest change, 1996-2010. PLOS ONE 12: e0179302. doi: 10.1371/journal.pone.0179302

## Data access
Available at WCMC:
http://data.unep-wcmc.org/datasets/45


## Data download and preparation

```sh
source ~/proyectos/UNSW/cesdata/env/project-env.sh


mkdir -p $GISDATA/ecosystems/global/WCMC-mangroves-GMW
cd $GISDATA/ecosystems/global/WCMC-mangroves-GMW

wget --continue http://wcmc.io/GMW_001 --output-document=WCMC-mangroves-GMW.zip

```

```sh
qsub -I -l select=1:ncpus=12:mem=120gb,walltime=24:00:00

source ~/proyectos/UNSW/cesdata/env/project-env.sh

module add sqlite/3.31.1 spatialite/5.0.0b0 python/3.8.3 perl/5.28.0 gdal/3.2.1 geos/3.8.1

export WD=$GISDATA/ecosystems/global/WCMC-mangroves-GMW

cd  $WD
unzip -u $WD/WCMC-mangroves-GMW.zip
export OUTPUT=$WD/GMW-valid-output
mkdir -p $OUTPUT
cd $OUTPUT
for YEAR in 2016 1996 2007 2008 2009 2010 2015
do
   echo $YEAR
   if [ $(ogrinfo --version | grep "GDAL 3.2" -c) -eq 1 ]
   then
      ogr2ogr -f "GPKG" GMW_${YEAR}_valid.gpkg $WD/01_Data/GMW_${YEAR}_v2.shp GMW_${YEAR}_v2 -nlt PROMOTE_TO_MULTI -makevalid
   else
      echo " ogr version does not support -makevalid flag"
      ##ogr2ogr -f "GPKG" GMW_${YEAR}_valid.gpkg $WD/01_Data/GMW_${YEAR}_v2.shp GMW_${YEAR}_v2 -nlt PROMOTE_TO_MULTI
   fi      

    echo GMW $YEAR done! $(date)

done
```


Alternative approach using PostGIS (in localhost)

```sh
export WD=$GISDATA/ecosystems/global/WCMC-mangroves-GMW

cd  $WD
unzip -u $WD/WCMC-mangroves-GMW.zip

psql gisdata -c "CREATE SCHEMA wcmc"

for YEAR in 2016 1996 2007 2008 2009 2010 2015
do
   echo $YEAR
   ogr2ogr -f "PostgreSQL" PG:"host=localhost user=jferrer dbname=gisdata"  $WD/01_Data/GMW_${YEAR}_v2.shp -lco SCHEMA=wcmc -nlt PROMOTE_TO_MULTI -nln gmw_${YEAR}

    echo GMW $YEAR done! $(date)

done

```


```sql

\dt wcmc.

SELECT ogc_fid,ST_AREA(wkb_geometry),ST_AsText(ST_CENTROID(wkb_geometry))  FROM  wcmc.gmw_2016 where ST_IsValid(wkb_geometry) LIMIT 10;

-- SELECT ST_IsValid(wkb_geometry) as valid,count(*) FROM  wcmc.gmw_2016 GROUP BY valid;
-- SELECT ogc_fid,ST_AREA(ST_MakeValid(wkb_geometry)),ST_AsText(ST_CENTROID(wkb_geometry)),ST_IsValid(wkb_geometry) FROM  wcmc.gmw_2016 where NOT ST_IsValid(wkb_geometry) LIMIT 10;

-- this throws many lines of warnings
UPDATE wcmc.gmw_2016 set wkb_geometry=ST_MakeValid(wkb_geometry) WHERE NOT ST_IsValid(wkb_geometry); -- UPDATE 63099

UPDATE wcmc.gmw_2015 set wkb_geometry=ST_MakeValid(wkb_geometry) WHERE NOT ST_IsValid(wkb_geometry); --

UPDATE wcmc.gmw_1996 set wkb_geometry=ST_MakeValid(wkb_geometry) WHERE NOT ST_IsValid(wkb_geometry); --

UPDATE wcmc.gmw_2007 set wkb_geometry=ST_MakeValid(wkb_geometry) WHERE NOT ST_IsValid(wkb_geometry); --
UPDATE wcmc.gmw_2008 set wkb_geometry=ST_MakeValid(wkb_geometry) WHERE NOT ST_IsValid(wkb_geometry); --
UPDATE wcmc.gmw_2009 set wkb_geometry=ST_MakeValid(wkb_geometry) WHERE NOT ST_IsValid(wkb_geometry); --
UPDATE wcmc.gmw_2010 set wkb_geometry=ST_MakeValid(wkb_geometry) WHERE NOT ST_IsValid(wkb_geometry); --


```
