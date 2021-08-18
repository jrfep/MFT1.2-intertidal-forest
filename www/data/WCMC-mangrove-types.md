# Mangrove-Typology-2020
A global biophysical typology of mangroves

## Citation

> Worthington, T.A., zu Ermgassen, P.S.E., Friess, D.A., Krauss, K.W., Lovelock, C.E., Thorley, J., Tingey, R., Woodroffe, C.D., Bunting, P., Cormier, N., Lagomasino, D., Lucas, R., Murray, N.J., Sutherland, W.J., Spalding, M., 2020. A global biophysical typology of mangroves and its relevance for ecosystem structure and deforestation. Sci. Rep. 10, 14652. https://doi.org/10.1038/s41598-020-71194-5

## Data access

Available at WCMC:
https://data.unep-wcmc.org/datasets/48

## Data download and preparation

```sh
source ~/proyectos/UNSW/cesdata/env/project-env.sh


mkdir -p $GISDATA/ecosystems/global/WCMC-mangrove-types
cd $GISDATA/ecosystems/global/WCMC-mangrove-types

wget --continue https://wcmc.io/TNC-006 --output-document=WCMC-mangrove-types.zip

```

Check download
```sh
source ~/proyectos/UNSW/cesdata/env/project-env.sh

cd $GISDATA/ecosystems/global/WCMC-mangrove-types


unzip -u $GISDATA/ecosystems/global/WCMC-mangrove-types/WCMC-mangrove-types.zip
tree TNC-006_BiophysicalTypologyMangroves/


```


```sh
qsub -I -l select=1:ncpus=4:mem=120gb,walltime=8:00:00

source ~/proyectos/UNSW/cesdata/env/project-env.sh

module add sqlite/3.31.1 spatialite/5.0.0b0 python/3.8.3 perl/5.28.0 gdal/3.2.1 geos/3.8.1

cd $GISDATA/ecosystems/global/WCMC-mangrove-types
unzip -u $WD/WCMC-mangrove-types.zip

export WD=$GISDATA/ecosystems/global/WCMC-mangrove-types/TNC-006_BiophysicalTypologyMangroves/01_Data
export OUTPUT=$GISDATA/ecosystems/global/WCMC-mangrove-types/TNC-BioPhys-Mangrove-valid-output
mkdir -p $OUTPUT
cd $OUTPUT
for YEAR in 2016 1996 2010 2007
do
   echo $YEAR
   if [ $(ogrinfo --version | grep "GDAL 3.2" -c) -eq 1 ]
   then
      ogr2ogr -f "GPKG" Mangrove_Typology_v2_2_${YEAR}_valid.gpkg $WD/Mangrove_Typology_v2_2_${YEAR}.shp Mangrove_Typology_v2_2_${YEAR} -nlt PROMOTE_TO_MULTI -makevalid
   else
      echo " ogr version does not support -makevalid flag"
      ##ogr2ogr -f "GPKG" GMW_${YEAR}_valid.gpkg $WD/01_Data/GMW_${YEAR}_v2.shp GMW_${YEAR}_v2 -nlt PROMOTE_TO_MULTI
   fi
    echo $YEAR done! $(date)
done
```
