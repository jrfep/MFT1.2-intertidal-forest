#!R --vanilla
projectname <- "MFT1.2-intertidal-forest"
projectdir <- "proyectos/IUCN-GET"
if (Sys.getenv("GISDATA") != "") {
   gis.data <- Sys.getenv("GISDATA")
   work.dir <- Sys.getenv("WORKDIR")
   script.dir <- Sys.getenv("SCRIPTDIR")
} else {
   out <- Sys.info()
   username <- out[["user"]]
   hostname <- out[["nodename"]]
   script.dir <- sprintf("%s/%s/%s",Sys.getenv("HOME"), projectdir, projectname)
   switch(hostname,
      terra={
         gis.data <- sprintf("/opt/gisdata/")
         work.dir <- sprintf("%s/tmp/%s",Sys.getenv("HOME"),projectname)
      },
      roraima.local={
         gis.data <- sprintf("%s/gisdata/",Sys.getenv("HOME"))
         work.dir <- sprintf("%s/tmp/%s",Sys.getenv("HOME"),projectname)
      },
      {
         if (file.exists("/srv/scratch/cesdata")) {
            gis.data <- sprintf("/srv/scratch/cesdata/gisdata/")
            work.dir <- sprintf("/srv/scratch/%s/tmp/%s/",username,projectname)
         } else {
            stop("Can't figure out where I am, please customize `project-env.R` script\n")
         }
      })
      if (file.exists("~/.database.ini")) {
          tmp <-     system("grep -A4 psqlaws $HOME/.database.ini",intern=TRUE)[-1]
          dbinfo <- gsub("[a-z]+=","",tmp)
          names(dbinfo) <- gsub("([a-z]+)=.*","\\1",tmp)
          rm(tmp)
      }
}
