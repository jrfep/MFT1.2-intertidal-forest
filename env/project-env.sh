export MIHOST=$(hostname -s)

export PROJECT=MFT1.2-intertidal-forest
export SCRIPTDIR=$HOME/proyectos/IUCN-GET/$PROJECTNAME

case $MIHOST in
terra)
  export GISDATA=/opt/gisdata
  export GISDB=/opt/gisdb/ecosphere
  export WORKDIR=$HOME/tmp/$PROJECTNAME
  export REFDIR=$HOME/Cloudstor/Shared/EFTglobalmaps/
  ;;
roraima)
  export GISDATA=$HOME/gisdata
  export GISDB=$HOME/gisdb/ecosphere
  export WORKDIR=$HOME/tmp/$PROJECTNAME
  export REFDIR=$HOME/Cloudstor/Shared/EFTglobalmaps/
  ;;
  *)
   if [ -e /srv/scratch/cesdata ]
   then
      export SHAREDSCRATCH=/srv/scratch/cesdata
      export PRIVATESCRATCH=/srv/scratch/$USER

      export GISDATA=$SHAREDSCRATCH/gisdata
      export GISDB=$PRIVATESCRATCH/gisdb
      source $HOME/.secrets
      export WORKDIR=$PRIVATESCRATCH/tmp/$PROJECTNAME
      export REFDIR=$PRIVATESCRATCH/DKeith-data/
   else
      echo "I DON'T KNOW WHERE I AM, please customize project-env.sh file"
   fi
  ;;
esac

export LOCATION=earth

mkdir -p $WORKDIR
