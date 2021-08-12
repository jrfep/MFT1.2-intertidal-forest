# MFT1.2-intertidal-forest
MFT1.2 Intertidal forests and shrublands


In terra:
```sh
source .profile
rsync -gloptrunv --delete $HOME/Cloudstor/Shared/EFTglobalmaps/* $zID@kdm.restech.unsw.edu.au:/srv/scratch/$zID/DKeith-data/
```

```sh
ssh $zID@katana.restech.unsw.edu.au
source ~/proyectos/IUCN-GET/MFT1.2-intertidal-forest/env/project-env.sh

cd $WORKDIR

#qsub $SCRIPTDIR/inc/pbs/xcross-mangrove-ecoregions.pbs
qsub $SCRIPTDIR/inc/pbs/xcross-mangrove-marine-provinces.pbs

qsub -I -l select=1:ncpus=12:mem=120gb,walltime=24:00:00

source ~/proyectos/IUCN-GET/MFT1.2-intertidal-forest/env/project-env.sh
cd $WORKDIR

module add sqlite/3.31.1 spatialite/5.0.0b0 python/3.8.3 perl/5.28.0 gdal/3.2.1 geos/3.8.1

```

```sh
ssh $zID@katana.restech.unsw.edu.au
source ~/proyectos/IUCN-GET/MFT1.2-intertidal-forest/env/project-env.sh

cd $WORKDIR

qsub -I -l select=1:ncpus=12:cpuflags=skylake-avx512:mem=120gb -l walltime=24:00:00

source ~/proyectos/IUCN-GET/MFT1.2-intertidal-forest/env/project-env.sh
cd $WORKDIR


module add sqlite/3.31.1 spatialite/5.0.0b0 python/2.7.15 perl/5.28.0 gdal/2.3.2 geos/3.8.1

module add grass/7.6.1
#module add python/2.7.15 perl/5.28.0 gdal/3.2.1 geos/3.8.1 grass/7.6.1

[ -e $GISDB/$LOCATION ] &&  echo "GRASS GIS Location ready" || grass76 -c EPSG:4326 $GISDB/$LOCATION --exec g.region n=90 s=-90 w=-180 e=180 res=00:01:00


## RUN:##
grass76 --text $GISDB/$LOCATION/PERMANENT
bash $SCRIPTDIR/workflow/00-set-up-permanent-location/permanent-datasets.sh
grass76 --text $GISDB/$LOCATION/MFT1
bash $SCRIPTDIR/workflow/02-indicative-maps/MFTX/MFT1_2.sh

```
