export MIHOST=$(hostname -s)

case $MIHOST in
terra)
  export GISDATA=/opt/gisdata
  export GISDB=/opt/gisdb
  export GISOUT=/opt/gisout
  export SCRIPTDIR=/home/jferrer/proyectos/
  export WORKDIR=$HOME/tmp/
  ;;
roraima)
  export GISDATA=$HOME/Cloudstor/Shared/
  export GISDB=$HOME/gisdb
  export GISOUT=$HOME/gisout
  export SCRIPTDIR=$HOME/proyectos/
  export WORKDIR=$HOME/tmp/
  ;;
esac
export PROJECT=MFT1.2-intertidal-forest
export SCRIPTDIR=$SCRIPTDIR/UNSW/$PROJECT
export WORKDIR=$WORKDIR/$PROJECT
mkdir -p $WORKDIR
