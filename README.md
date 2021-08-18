# MFT1.2-intertidal-forest and shrublands - Level 4 units

This repository showcases the data of products of a IUCN workshop on the delimitation of global ecoregional types for the ecosystem functional group _MFT1.2-intertidal-forest and shrublands_. 

The repository has the following structure:

## _env_ folder
Defining the programming environment variables for working in Linux/MacOS

## _inc_ folder
Holds the scripts used for specific tasks. Mostly R and (bash) shell scrips, includes the PBS scripts for scheduling jobs in the HPC nodes. 

## _Rdata_ folder
For `rda` files that contain data used in some R scripts.

## _workflow_ folder
This contains the markdown documents explaining the steps of the workflow from the raw data to the end products. The workflow was developed using different computers (named *terra*, *humboldt* and *roraima*), but most of the spatial analysis has been done in Katana @ UNSW ResTech:
> Katana. Published online 2010. doi:10.26190/669X-A286

## _www_ folder
This folder contains the markdown documents and web app used in the workshop to showcase preliminary results at:
- <https://ecosphere.shinyapps.io/Mangrove-L4-map/>
- <http://ec2-13-236-200-14.ap-southeast-2.compute.amazonaws.com:3838/Mangroves/>
- <http://ec2-13-236-200-14.ap-southeast-2.compute.amazonaws.com:3838/MangrovesData/>
- and <http://ec2-13-236-200-14.ap-southeast-2.compute.amazonaws.com:3838/MangrovesMap/>
