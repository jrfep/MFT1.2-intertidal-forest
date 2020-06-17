# Global Distribution of Mangroves USGS, version 1.3

This dataset shows the global distribution of mangrove forests, derived from earth observation satellite imagery. The dataset was created using Global Land Survey (GLS) data and the Landsat archive. Approximately 1,000 Landsat scenes were interpreted using hybrid supervised and unsupervised digital image classification techniques. See Giri et al. (2011) for full details.

This dataset is shown at a coarser resolution for display purposes.

#### Citation

> Giri C, Ochieng E, Tieszen LL, Zhu Z, Singh A, Loveland T, Masek J, Duke N (2011). *Status and distribution of mangrove forests of the world using earth observation satellite data* (version 1.3, updated by UNEP-WCMC). **Global Ecology and Biogeography** 20: 154-159. doi: [10.1111/j.1466-8238.2010.00584.x] .

> Giri, C., E. Ochieng, L.L.Tieszen, Z. Zhu, A. Singh, T. Loveland, J. Masek, and N. Duke. 2013. **Global Mangrove Forests Distribution, 2000**. Palisades, NY: NASA Socioeconomic Data and Applications Center (SEDAC). https://doi.org/10.7927/H4J67DW8. Accessed DAY MONTH YEAR


#### Data download
 Data URL: http://data.unep-wcmc.org/datasets/4
https://sedac.ciesin.columbia.edu/data/set/lulc-global-mangrove-forests-distribution-2000

```sh
mkdir -p $GISDATA/ecosystems/USGS-Mangroves
cd $GISDATA/ecosystems/USGS-Mangroves
mv ~/Downloads/WCMC010_MangrovesUSGS2011_v1_3.zip $GISDATA/ecosystems/USGS-Mangroves

```

Explore the file and import to postgis using *ogr*-functions

```sh
cd $WORKDIR
unzip $GISDATA/ecosystems/USGS-Mangroves/WCMC010_MangrovesUSGS2011_v1_3.zip

ogrinfo -al -so DataPack-14_001_WCMC010_MangrovesUSGS2011_v1_3/01_Data/

ogrinfo -geom=no DataPack-14_001_WCMC010_MangrovesUSGS2011_v1_3/01_Data/ -sql "SELECT grid_code,ISO3,PARISO3,CTYPE FROM \"14_001_WCMC010_MangroveUSGS2011_v1_3\""

psql gisdata -c "CREATE SCHEMA WCMC"
# use -unsetFieldWidth to avoid *ERROR:  numeric field overflow*
ogr2ogr -overwrite -f "PostgreSQL" PG:"host=localhost user=jferrer dbname=gisdata" -unsetFieldWidth -lco SCHEMA=wcmc DataPack-14_001_WCMC010_MangrovesUSGS2011_v1_3/01_Data/14_001_WCMC010_MangroveUSGS2011_v1_3.shp -nln MangroveUSGS2011_v1_3 -nlt PROMOTE_TO_MULTI

```

Now in postgis (`psql -d gisdata`):

```sql
-- have not found a better way to avoid *ERROR:  Geometry type (Polygon) does not match column type (MultiPolygon)*
-- so I am switching grom geom to geog and back again...
ALTER TABLE wcmc.mangroveusgs2011_v1_3 DROP COLUMN geog ;
ALTER TABLE wcmc.mangroveusgs2011_v1_3 ADD COLUMN geog geography(MULTIPOLYGON,4326) DEFAULT NULL;
ALTER TABLE wcmc.mangroveusgs2011_v1_3 DROP COLUMN buffer ;
ALTER TABLE wcmc.mangroveusgs2011_v1_3 ADD COLUMN buffer geometry(MULTIPOLYGON,4326) DEFAULT NULL;

-- the conversion takes some time for larger polygons, or when there are many thousands of them
UPDATE wcmc.mangroveusgs2011_v1_3 set geog=ST_GeogFromWKB(wkb_geometry) where area_km2>100 AND geog IS NULL;
UPDATE wcmc.mangroveusgs2011_v1_3 set geog=ST_GeogFromWKB(wkb_geometry) where area_km2>1 AND geog IS NULL;
UPDATE wcmc.mangroveusgs2011_v1_3 set geog=ST_GeogFromWKB(wkb_geometry) where area_km2<0.00000005 AND geog IS NULL;
UPDATE wcmc.mangroveusgs2011_v1_3 set geog=ST_GeogFromWKB(wkb_geometry) where area_km2<0.00005 AND geog IS NULL;
UPDATE wcmc.mangroveusgs2011_v1_3 set geog=ST_GeogFromWKB(wkb_geometry) where area_km2<0.005 AND geog IS NULL;
UPDATE wcmc.mangroveusgs2011_v1_3 set geog=ST_GeogFromWKB(wkb_geometry) where area_km2<0.05 AND geog IS NULL;
UPDATE wcmc.mangroveusgs2011_v1_3 SET geog=ST_GeogFromWKB(wkb_geometry) WHERE geog IS NULL;

-- this is slow for big polygons
SELECT count (*) from  wcmc.mangroveusgs2011_v1_3 where area_km2>500 ;
UPDATE wcmc.mangroveusgs2011_v1_3 set buffer=ST_Multi(ST_buffer(geog,1000)::geometry) where area_km2>1 AND geog IS NOT NULL AND buffer IS NULL;
-- this is fast for small polygons, but there many of them
SELECT count (*) from  wcmc.mangroveusgs2011_v1_3 where area_km2<0.0000000005 ;
UPDATE wcmc.mangroveusgs2011_v1_3 set buffer=ST_Multi(ST_buffer(geog,1000)::geometry) where area_km2<0.05 AND geog IS NOT NULL AND buffer IS NULL;

SELECT ST_Area(geog), ST_AREA(ST_GeogFromWKB(buffer)) FROM wcmc.mangroveusgs2011_v1_3 where buffer is NOT NULL LIMIT 20;

-- SELECT ST_Area(ST_buffer(geog,1000)), Type(ST_buffer(geog,1000)), ST_Area(geog),ST_Area(wkb_geometry) FROM wcmc.mangroveusgs2011_v1_3 WHERE area_km2>1000 limit 10;


-- CREATE TABLE wcmc.mangrove_buffer AS (
--    SELECT ogc_fid,ST_Buffer(ST_GeogFromWKB(wkb_geometry), 1000)
--    FROM wcmc.mangroveusgs2011_v1_3
-- );

```

#### Alternative in Google earth engine

This dataset is available as [Global Mangrove Forests Distribution, v1 (2000)](https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_MANGROVE_FORESTS).

```js

var dataset = ee.ImageCollection('LANDSAT/MANGROVE_FORESTS');
var mangrovesVis = {
  min: 0,
  max: 1.0,
  palette: ['d40115'],
};
Map.setCenter(-44.5626, -2.0164, 9);
Map.addLayer(dataset, mangrovesVis, 'Mangroves');

```
