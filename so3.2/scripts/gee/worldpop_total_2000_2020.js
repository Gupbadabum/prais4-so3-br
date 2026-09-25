// ============================================================
// PRAIS4 / SO3.2
// WorldPop annual total population - Brazil
// Years: 2000-2020
//
// Source:
//   WorldPop/GP/100m/pop
//
// Purpose:
//   Create one export task per source year, preserving the
//   native WorldPop grid.
//
// Note:
//   WorldPop total population is available here for 2000-2020.
//   For PRAIS analysis years 2021-2023, population source year
//   2020 is reused according to the adopted methodology.
// ============================================================


// ------------------------------------------------------------
// Configuration
// ------------------------------------------------------------

var START_YEAR = 2000;
var END_YEAR   = 2020;

var COUNTRY = 'BRA';

var WORLDPOP_TOTAL = 'WorldPop/GP/100m/pop';

var EXPORT_FOLDER = 'PRAIS4_SO3';

var NODATA = -9999;


// ------------------------------------------------------------
// Reference grid validated for WorldPop Brazil
//
// Same grid observed for:
// - Total 2000 in GEE
// - Female 2000
// - Male 2000
// ------------------------------------------------------------

var NATIVE_CRS = 'EPSG:4326';

var NATIVE_TRANSFORM = [
   0.0008333333300044304,
   0,
  -73.989583022,
   0,
  -0.0008333333300081173,
   5.264583514
];

var EXPECTED_WIDTH  = 54172;
var EXPECTED_HEIGHT = 46814;


// ------------------------------------------------------------
// WorldPop collection
// ------------------------------------------------------------

var collection = ee.ImageCollection(WORLDPOP_TOTAL)
  .filter(ee.Filter.eq('country', COUNTRY));

print(
  'WorldPop collection:',
  WORLDPOP_TOTAL
);


// ------------------------------------------------------------
// Create one export task per year
// ------------------------------------------------------------

for (var year = START_YEAR; year <= END_YEAR; year++) {

  var annualCollection = collection
    .filter(ee.Filter.eq('year', year));

  var count = annualCollection.size().getInfo();

  print(
    'Year ' + year + ' - number of images:',
    count
  );

  if (count !== 1) {

    print(
      'WARNING: year ' + year +
      ' has ' + count +
      ' images. Export not created.'
    );

    continue;
  }


  // ----------------------------------------------------------
  // Annual population image
  // ----------------------------------------------------------

  var population = ee.Image(
    annualCollection.first()
  ).select('population');


  // ----------------------------------------------------------
  // Validate native grid before creating export
  // ----------------------------------------------------------

  var info = population.getInfo();
  var bandInfo = info.bands[0];

  var dimensions = bandInfo.dimensions;
  var transform  = bandInfo.crs_transform;
  var crs        = bandInfo.crs;

  print(
    'Year ' + year +
    ' - dimensions:',
    dimensions
  );

  print(
    'Year ' + year +
    ' - CRS:',
    crs
  );

  print(
    'Year ' + year +
    ' - transform:',
    transform
  );


  // ----------------------------------------------------------
  // Basic grid checks
  // ----------------------------------------------------------

  var dimensionsOK =
    dimensions[0] === EXPECTED_WIDTH &&
    dimensions[1] === EXPECTED_HEIGHT;

  var crsOK =
    crs === NATIVE_CRS;

  print(
    'Year ' + year +
    ' - dimensions OK:',
    dimensionsOK
  );

  print(
    'Year ' + year +
    ' - CRS OK:',
    crsOK
  );


  if (!dimensionsOK || !crsOK) {

    print(
      'WARNING: native grid differs for year ' +
      year +
      '. Export not created.'
    );

    continue;
  }


  // ----------------------------------------------------------
  // National population QA
  // ----------------------------------------------------------

  var totalPopulation = population.reduceRegion({
    reducer: ee.Reducer.sum(),
    geometry: population.geometry(),
    crs: NATIVE_CRS,
    crsTransform: NATIVE_TRANSFORM,
    maxPixels: 1e13,
    tileScale: 4
  });

  print(
    'Total population ' + year + ':',
    totalPopulation
  );


  // ----------------------------------------------------------
  // Explicit NoData for GeoTIFF export
  // ----------------------------------------------------------

  var populationExport = population.unmask({
    value: NODATA,
    sameFootprint: false
  });


  // ----------------------------------------------------------
  // Export task
  // ----------------------------------------------------------

  Export.image.toDrive({
    image: populationExport,

    description:
      'SO32_population_total_' + year,

    folder:
      EXPORT_FOLDER,

    fileNamePrefix:
      'population_total_' + year,

    dimensions:
      '54172x46814',

    crs:
      NATIVE_CRS,

    crsTransform:
      NATIVE_TRANSFORM,

    maxPixels:
      1e13,

    fileFormat:
      'GeoTIFF',

    formatOptions: {
      noData: NODATA
    }
  });
}
