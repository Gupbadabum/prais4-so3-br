// ============================================================
// PRAIS4 / SO3.2
// INPUT QA - FIRST FOUR-YEAR PERIOD
// Period: 2000-2003
//
// Inputs validated here:
//
//   1. Annual drought classes
//      SPEI-12 December
//      Classes:
//        1 = Extreme
//        2 = Severe
//        3 = Moderate
//        4 = Weak
//        5 = Normal
//        0 = NoData / masked
//
//   2. Annual total population
//      WorldPop ~100 m
//
// PURPOSE:
//
//   Validate the input datasets BEFORE any calculation of
//   population exposure to drought.
//
// IMPORTANT:
//
//   This script does NOT calculate exposure.
//   This script does NOT perform drought resampling.
//   This script does NOT perform municipal aggregation.
// ============================================================


// ============================================================
// 0. GENERAL CONFIGURATION
// ============================================================

var START_YEAR = 2000;
var END_YEAR   = 2003;

var YEARS = ee.List.sequence(
  START_YEAR,
  END_YEAR
);


// ------------------------------------------------------------
// Asset IDs
// ------------------------------------------------------------

var DROUGHT_ASSET =
  'projects/cursoqueimadas-503722/assets/' +
  'drought_spei12_dec';

var POP_TOTAL_ASSET =
  'projects/cursoqueimadas-503722/assets/' +
  'population_total';


// ------------------------------------------------------------
// Native drought grid
//
// Original classified SO3.1 product:
//
//   CRS        = EPSG:4326
//   resolution = 0.1 degree
//   dimensions = 452 x 391
//
// IMPORTANT:
// This grid is NOT modified in this QA script.
// ------------------------------------------------------------

var DROUGHT_CRS = 'EPSG:4326';

var DROUGHT_TRANSFORM = [
   0.1, 0, -74.0,
   0, -0.1, 5.3
];


// ------------------------------------------------------------
// Native WorldPop grid
//
// Grid validated previously from:
//   - WorldPop Total
//   - Female
//   - Male
//
//   dimensions = 54172 x 46814
// ------------------------------------------------------------

var POP_CRS = 'EPSG:4326';

var POP_TRANSFORM = [
   0.0008333333300044304,
   0,
  -73.989583022,
   0,
  -0.0008333333300081173,
   5.264583514
];

var POP_WIDTH  = 54172;
var POP_HEIGHT = 46814;

var POP_TOTAL_PIXELS =
  POP_WIDTH * POP_HEIGHT;


// ============================================================
// 1. DROUGHT INPUT QA - 2000-2003
// ============================================================

print(
  '================================================'
);

print(
  '1. DROUGHT INPUT QA - 2000-2003'
);

print(
  '================================================'
);


// ------------------------------------------------------------
// Load collection
// ------------------------------------------------------------

var drought = ee.ImageCollection(
  DROUGHT_ASSET
)
.filterDate(
  '2000-01-01',
  '2004-01-01'
)
.sort(
  'system:time_start'
);


// ------------------------------------------------------------
// Basic collection checks
// ------------------------------------------------------------

print(
  'Drought - number of images:',
  drought.size()
);

print(
  'Drought - years:',
  drought.aggregate_array('year')
);

print(
  'Drought - system:index:',
  drought.aggregate_array('system:index')
);

print(
  'Drought - time_start:',
  drought.aggregate_array(
    'system:time_start'
  )
);


// ------------------------------------------------------------
// Number of images for each expected year
//
// Expected:
//   [1, 1, 1, 1]
// ------------------------------------------------------------

var droughtImagesPerYear =
  YEARS.map(function(year) {

    year = ee.Number(year);

    return drought
      .filter(
        ee.Filter.eq(
          'year',
          year
        )
      )
      .size();

  });

print(
  'Drought - images per year:',
  droughtImagesPerYear
);


// ------------------------------------------------------------
// Projection check using 2000
// ------------------------------------------------------------

var drought2000 = ee.Image(
  drought
    .filter(
      ee.Filter.eq(
        'year',
        2000
      )
    )
    .first()
)
.select(0)
.rename(
  'drought_class'
);

print(
  'Drought 2000 - projection:',
  drought2000.projection()
);

print(
  'Drought 2000 - nominal scale:',
  drought2000
    .projection()
    .nominalScale()
);


// ------------------------------------------------------------
// Annual drought QA
//
// We calculate:
//
//   - class histogram
//   - number of valid pixels
//
// The native 0.1 degree grid is used explicitly.
// ------------------------------------------------------------

var droughtQA = ee.FeatureCollection(

  YEARS.map(function(year) {

    year = ee.Number(year);

    var img = ee.Image(
      drought
        .filter(
          ee.Filter.eq(
            'year',
            year
          )
        )
        .first()
    )
    .select(0)
    .rename(
      'drought_class'
    );


    var histogram = img.reduceRegion({
      reducer:
        ee.Reducer.frequencyHistogram(),

      geometry:
        img.geometry(),

      crs:
        DROUGHT_CRS,

      crsTransform:
        DROUGHT_TRANSFORM,

      maxPixels:
        1e8
    });


    var count = img.reduceRegion({
      reducer:
        ee.Reducer.count(),

      geometry:
        img.geometry(),

      crs:
        DROUGHT_CRS,

      crsTransform:
        DROUGHT_TRANSFORM,

      maxPixels:
        1e8
    });


    return ee.Feature(
      null,
      {
        year:
          year,

        date:
          ee.Date(
            img.get(
              'system:time_start'
            )
          ).format(
            'YYYY-MM-dd'
          ),

        valid_pixels:
          count.get(
            'drought_class'
          ),

        histogram:
          histogram.get(
            'drought_class'
          )
      }
    );

  })

).sort(
  'year'
);


// ------------------------------------------------------------
// Drought QA output
// ------------------------------------------------------------

print(
  'Drought QA:',
  droughtQA
);

print(
  'Drought QA - years:',
  droughtQA.aggregate_array(
    'year'
  )
);

print(
  'Drought QA - dates:',
  droughtQA.aggregate_array(
    'date'
  )
);

print(
  'Drought QA - valid pixels:',
  droughtQA.aggregate_array(
    'valid_pixels'
  )
);

print(
  'Drought QA - histograms:',
  droughtQA.aggregate_array(
    'histogram'
  )
);


// ============================================================
// 2. POPULATION TOTAL INPUT QA - 2000-2003
// ============================================================

print(
  '================================================'
);

print(
  '2. POPULATION TOTAL INPUT QA - 2000-2003'
);

print(
  '================================================'
);


// ------------------------------------------------------------
// Load collection
// ------------------------------------------------------------

var popTotal = ee.ImageCollection(
  POP_TOTAL_ASSET
)
.filterDate(
  '2000-01-01',
  '2004-01-01'
)
.sort(
  'system:time_start'
);


// ------------------------------------------------------------
// Basic collection checks
// ------------------------------------------------------------

print(
  'Population total - number of images:',
  popTotal.size()
);

print(
  'Population total - years:',
  popTotal.aggregate_array(
    'year'
  )
);

print(
  'Population total - source years:',
  popTotal.aggregate_array(
    'source_year'
  )
);

print(
  'Population total - sex:',
  popTotal.aggregate_array(
    'sex'
  )
);

print(
  'Population total - system:index:',
  popTotal.aggregate_array(
    'system:index'
  )
);


// ------------------------------------------------------------
// Number of images for each expected year
//
// Expected:
//   [1, 1, 1, 1]
// ------------------------------------------------------------

var populationImagesPerYear =
  YEARS.map(function(year) {

    year = ee.Number(year);

    return popTotal
      .filter(
        ee.Filter.eq(
          'year',
          year
        )
      )
      .size();

  });

print(
  'Population total - images per year:',
  populationImagesPerYear
);


// ------------------------------------------------------------
// Projection check using 2000
// ------------------------------------------------------------

var pop2000 = ee.Image(
  popTotal
    .filter(
      ee.Filter.eq(
        'year',
        2000
      )
    )
    .first()
)
.select(0)
.rename(
  'population'
);

print(
  'Population total 2000 - projection:',
  pop2000.projection()
);

print(
  'Population total 2000 - nominal scale:',
  pop2000
    .projection()
    .nominalScale()
);


// ============================================================
// Population QA reducer
//
// A single reduceRegion obtains:
//
//   count
//   sum
//   minimum
//   maximum
//
// This avoids reading each ~100 m raster repeatedly.
// ============================================================

var populationReducer =
  ee.Reducer.count()

    .combine({
      reducer2:
        ee.Reducer.sum(),

      sharedInputs:
        true
    })

    .combine({
      reducer2:
        ee.Reducer.minMax(),

      sharedInputs:
        true
    });


// ------------------------------------------------------------
// Annual population QA
// ------------------------------------------------------------

var populationQA = ee.FeatureCollection(

  YEARS.map(function(year) {

    year = ee.Number(year);


    var img = ee.Image(
      popTotal
        .filter(
          ee.Filter.eq(
            'year',
            year
          )
        )
        .first()
    )
    .select(0)
    .rename(
      'population'
    );


    var stats = img.reduceRegion({

      reducer:
        populationReducer,

      geometry:
        img.geometry(),

      crs:
        POP_CRS,

      crsTransform:
        POP_TRANSFORM,

      maxPixels:
        3e9,

      tileScale:
        4
    });


    var validPixels =
      ee.Number(
        stats.get(
          'population_count'
        )
      );


    var nodataPixels =
      ee.Number(
        POP_TOTAL_PIXELS
      ).subtract(
        validPixels
      );


    return ee.Feature(
      null,
      {
        year:
          year,

        source_year:
          img.get(
            'source_year'
          ),

        date:
          ee.Date(
            img.get(
              'system:time_start'
            )
          ).format(
            'YYYY-MM-dd'
          ),

        valid_pixels:
          validPixels,

        nodata_pixels:
          nodataPixels,

        population_sum:
          stats.get(
            'population_sum'
          ),

        population_min:
          stats.get(
            'population_min'
          ),

        population_max:
          stats.get(
            'population_max'
          )
      }
    );

  })

).sort(
  'year'
);


// ------------------------------------------------------------
// Population QA output
// ------------------------------------------------------------

print(
  'Population total QA:',
  populationQA
);

print(
  'Population total QA - years:',
  populationQA.aggregate_array(
    'year'
  )
);

print(
  'Population total QA - source years:',
  populationQA.aggregate_array(
    'source_year'
  )
);

print(
  'Population total QA - dates:',
  populationQA.aggregate_array(
    'date'
  )
);

print(
  'Population total QA - valid pixels:',
  populationQA.aggregate_array(
    'valid_pixels'
  )
);

print(
  'Population total QA - NoData pixels:',
  populationQA.aggregate_array(
    'nodata_pixels'
  )
);

print(
  'Population total QA - population sums:',
  populationQA.aggregate_array(
    'population_sum'
  )
);

print(
  'Population total QA - minimum:',
  populationQA.aggregate_array(
    'population_min'
  )
);

print(
  'Population total QA - maximum:',
  populationQA.aggregate_array(
    'population_max'
  )
);


// ============================================================
// 3. VISUAL CHECK - YEAR 2000
//
// This is only a visual aid.
// No analytical product is generated here.
// ============================================================

Map.centerObject(
  drought2000,
  4
);


// ------------------------------------------------------------
// Drought
// ------------------------------------------------------------

Map.addLayer(
  drought2000,
  {
    min: 1,
    max: 5
  },
  'Drought classes 2000',
  true
);


// ------------------------------------------------------------
// Total population
//
// Initially hidden because this is a much larger raster.
// Enable it manually in the Layers panel when needed.
// ------------------------------------------------------------

Map.addLayer(
  pop2000,
  {
    min: 0,
    max: 100
  },
  'Population total 2000',
  false
);


// ============================================================
// END OF INPUT QA
// ============================================================

print(
  '================================================'
);

print(
  'INPUT QA SCRIPT FINISHED'
);

print(
  'Period: 2000-2003'
);

print(
  'Validated inputs: drought + total population'
);

print(
  'No exposure calculation performed.'
);

print(
  '================================================'
);
