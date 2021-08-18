#  MEOW : Marine ecoregions of the world

#### CITATION
>  Spalding MD et al. (2008) Marine ecoregions of the world: a bioregionalization of coastal and shelf areas. Bioscience 57: 573–583.

#### data availability

https://www.worldwildlife.org/publications/marine-ecoregions-of-the-world-a-bioregionalization-of-coastal-and-shelf-areas


#### Data download and preparation

```sh
source ~/proyectos/UNSW/cesdata/env/project-env.sh

mkdir -p $GISDATA/ecoregions/global/MEOW/
cd $GISDATA/ecoregions/global/MEOW/

wget --continue 'https://c402277.ssl.cf1.rackcdn.com/publications/351/files/original/MEOW_FINAL.zip?1349120553' --output-document=MEOW_FINAL.zip

```


```sh
qsub -I -l select=1:ncpus=2:mem=120gb,walltime=12:00:00

source ~/proyectos/UNSW/cesdata/env/project-env.sh

module add sqlite/3.31.1 spatialite/5.0.0b0 python/3.8.3 perl/5.28.0 gdal/3.2.1 geos/3.8.1

export WD=$GISDATA/ecoregions/global/MEOW/
cd  $WD
unzip -u $WD/MEOW_FINAL.zip

if [ $(ogrinfo --version | grep "GDAL 3.2" -c) -eq 1 ]
then
     ogr2ogr -f "GPKG" meow_ecos_valid.gpkg $WD/MEOW/meow_ecos.shp meow_ecos -nlt PROMOTE_TO_MULTI -t_srs "+proj=longlat +datum=WGS84" -makevalid
fi

```


```sh
cd $WORKDIR
unzip $GISDATA/biogeografia/MEOW/MEOW_FINAL.zip

psql gisdata -c "CREATE SCHEMA MEOW"
ogr2ogr -overwrite -f "PostgreSQL" PG:"host=localhost user=jferrer dbname=gisdata" -lco SCHEMA=meow MEOW/meow_ecos.shp  -nlt PROMOTE_TO_MULTI


```
