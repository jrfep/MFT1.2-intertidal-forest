# Global Distribution of Mangroves USGS, version 1.3

This dataset shows the global distribution of mangrove forests, derived from earth observation satellite imagery. The dataset was created using Global Land Survey (GLS) data and the Landsat archive. Approximately 1,000 Landsat scenes were interpreted using hybrid supervised and unsupervised digital image classification techniques. See Giri et al. (2011) for full details.

This dataset is shown at a coarser resolution for display purposes.

#### Citation

> Giri C, Ochieng E, Tieszen LL, Zhu Z, Singh A, Loveland T, Masek J, Duke N (2011). *Status and distribution of mangrove forests of the world using earth observation satellite data* (version 1.3, updated by UNEP-WCMC). **Global Ecology and Biogeography** 20: 154-159. doi: [10.1111/j.1466-8238.2010.00584.x] .

> Giri, C., E. Ochieng, L.L.Tieszen, Z. Zhu, A. Singh, T. Loveland, J. Masek, and N. Duke. 2013. Global Mangrove Forests Distribution, 2000. Palisades, NY: NASA Socioeconomic Data and Applications Center (SEDAC). https://doi.org/10.7927/H4J67DW8. Accessed DAY MONTH YEAR


#### Data download
 Data URL: http://data.unep-wcmc.org/datasets/4

```sh
mkdir -p $GISDATA/ecosystems/USGS-Mangroves
cd $GISDATA/ecosystems/USGS-Mangroves
mv ~/Downloads/WCMC010_MangrovesUSGS2011_v1_3.zip $GISDATA/ecosystems/USGS-Mangroves

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
