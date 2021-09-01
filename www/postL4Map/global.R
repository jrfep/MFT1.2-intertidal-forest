library(dplyr)
library(magrittr)
require(sf)
options(dplyr.summarise.inform = FALSE)


load("../Rdata/selected-units.rda")
load("../Rdata/mgt-point-data.rda")


post_units %<>%
  st_wrap_dateline(options = c("WRAPDATELINE=YES", "DATELINEOFFSET=0")) 

slc <- c("Mangroves of Hawaii","Mangroves of New Zealand","Mangroves of Central Polynesia",
         "Mangroves of Marshall, Gilbert and Ellis Islands","Mangroves of Tropical Southwestern Pacific",
         "Mangroves of Southeast Polynesia" )


mgt_points <- mgt_points %>% filter(unit_name %in% slc) %>% st_shift_longitude() %>% bind_rows({mgt_points %>% filter(!unit_name %in% slc)})

post_units <- bind_rows({post_units %>% filter(!unit_name %in% slc)},
{post_units %>% filter(unit_name %in% slc) %>% st_shift_longitude()})

# L4u %<>% mutate(id= sprintf("MFT1.2_G%02d",vctrs::vec_group_id(unit_name)))


vars <- c(
   "Area" = "total",
   "Number of polygons" = "npols"
)

known_mgv <- bind_rows(
   tibble(lng=-16.526742,lat=19.459096,message="Nouamghar (Cape Timirist) Park National du Banc d'Arguin"),
   tibble(lng=-65.122,lat=31.280,message='Mangroves are present in Bermuda'),
   tibble(lng=73.34406,lat=3.11347,message='Mangroves are present in the Maldives (Kathiresan & Rajendran 2005)'),
   tibble(lng=159.08342,lat=-31.548905,message='Mangroves are present in Lord Howe Island'),
   tibble(lng=115.6649,lat=-33.3373,message='Mangroves are present in Bunbury (Western Australia)'))

