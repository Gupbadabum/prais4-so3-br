// ============================================================
// PRAIS4 / SO3.2
// INPUT QA - QUADRENNIAL PERIOD
// Analytical period is derived from YEAR_START
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
//   2. Annual population
//      WorldPop ~100 m
//      - Total
//      - Female
//      - Male
//
// PURPOSE:
//
//   Validate all input datasets BEFORE any calculation of
//   population exposure to drought.
//
// IMPORTANT:
//
//   This script does NOT calculate exposure.
//   This script does NOT perform drought resampling.
//   This script does NOT perform municipal aggregation.
//
//   Total population is an independent WorldPop product.
//   Female + Male is used only as a consistency check and
//   never replaces Total.
// ============================================================


// ============================================================
// 0. GENERAL CONFIGURATION
// ============================================================

// ------------------------------------------------------------
// Analytical period
//
// Change ONLY YEAR_START when reusing this script for another
// quadrennium. YEAR_END, YEARS and period labels are derived
// automatically.
// ------------------------------------------------------------

var YEAR_START = 2016;
var PERIOD_LENGTH = 4;

var YEAR_END =
  YEAR_START + PERIOD_LENGTH - 1;

var YEARS = ee.List.sequence(
  YEAR_START,
  YEAR_END
);

var PERIOD =
  YEAR_START +
  '-' +
  YEAR_END;

var PERIOD_ID =
  YEAR_START +
  '_' +
  YEAR_END;


// ------------------------------------------------------------
// Fixed reference years
//
// GRID_REFERENCE_YEAR is intentionally independent from the
// analytical period. The validated 2000 grids remain the
// projection/grid reference for every quadrennium.
//
// WORLDPOP_LAST_SOURCE_YEAR controls population provenance.
// For analytical years 2021-2023, year remains 2021-2023 while
// source_year is expected to remain 2020.
// ------------------------------------------------------------

var GRID_REFERENCE_YEAR = 2000;
var WORLDPOP_LAST_SOURCE_YEAR = 2020;

var EXPECTED_SOURCE_YEARS =
  YEARS.map(
    function(year) {

      year = ee.Number(
        year
      );

      return ee.Number(
        ee.Algorithms.If(
          year.lte(
            WORLDPOP_LAST_SOURCE_YEAR
          ),
          year,
          WORLDPOP_LAST_SOURCE_YEAR
        )
      );

    }
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

var POP_FEMALE_ASSET =
  'projects/cursoqueimadas-503722/assets/' +
  'population_female';

var POP_MALE_ASSET =
  'projects/cursoqueimadas-503722/assets/' +
  'population_male';


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
// dimensions = 54172 x 46814
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
// 1. DROUGHT INPUT QA
// ============================================================

print(
  '================================================'
);

print(
  '1. DROUGHT INPUT QA - ' + PERIOD
);

print(
  '================================================'
);


// ------------------------------------------------------------
// Load collection
// ------------------------------------------------------------

var droughtAll = ee.ImageCollection(
  DROUGHT_ASSET
);

var drought = droughtAll
  .filter(
    ee.Filter.gte(
      'year',
      YEAR_START
    )
  )
  .filter(
    ee.Filter.lte(
      'year',
      YEAR_END
    )
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
  drought.aggregate_array(
    'year'
  )
);

print(
  'Drought - system:index:',
  drought.aggregate_array(
    'system:index'
  )
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
  YEARS.map(
    function(year) {

      year = ee.Number(
        year
      );

      return drought
        .filter(
          ee.Filter.eq(
            'year',
            year
          )
        )
        .size();

    }
  );

print(
  'Drought - images per year:',
  droughtImagesPerYear
);


// ------------------------------------------------------------
// Projection check using the fixed grid-reference year
// ------------------------------------------------------------

var droughtGridReference = ee.Image(
  droughtAll
    .filter(
      ee.Filter.eq(
        'year',
        GRID_REFERENCE_YEAR
      )
    )
    .first()
)
.select(0)
.rename(
  'drought_class'
);

print(
  'Drought grid reference year:',
  GRID_REFERENCE_YEAR
);

print(
  'Drought grid reference - projection:',
  droughtGridReference.projection()
);

print(
  'Drought grid reference - nominal scale:',
  droughtGridReference
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

  YEARS.map(
    function(year) {

      year = ee.Number(
        year
      );


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


      var histogram =
        img.reduceRegion({

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


      var count =
        img.reduceRegion({

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
            )
            .format(
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

    }
  )

)
.sort(
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
// 2. POPULATION INPUTS
// ============================================================

print(
  '================================================'
);

print(
  '2. POPULATION INPUT QA - ' + PERIOD
);

print(
  '================================================'
);


// ------------------------------------------------------------
// Load collections
// ------------------------------------------------------------

var popTotalAll = ee.ImageCollection(
  POP_TOTAL_ASSET
);

var popFemaleAll = ee.ImageCollection(
  POP_FEMALE_ASSET
);

var popMaleAll = ee.ImageCollection(
  POP_MALE_ASSET
);


var popTotal = popTotalAll
  .filter(
    ee.Filter.gte(
      'year',
      YEAR_START
    )
  )
  .filter(
    ee.Filter.lte(
      'year',
      YEAR_END
    )
  )
  .sort(
    'system:time_start'
  );


var popFemale = popFemaleAll
  .filter(
    ee.Filter.gte(
      'year',
      YEAR_START
    )
  )
  .filter(
    ee.Filter.lte(
      'year',
      YEAR_END
    )
  )
  .sort(
    'system:time_start'
  );


var popMale = popMaleAll
  .filter(
    ee.Filter.gte(
      'year',
      YEAR_START
    )
  )
  .filter(
    ee.Filter.lte(
      'year',
      YEAR_END
    )
  )
  .sort(
    'system:time_start'
  );


// ============================================================
// 3. POPULATION QA SUPPORT FUNCTIONS
// ============================================================


// ------------------------------------------------------------
// Get one annual population image
// ------------------------------------------------------------

function getPopulationImage(
  collection,
  year
) {

  return ee.Image(
    collection
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

}


// ------------------------------------------------------------
// Population reducer
//
// One reduceRegion obtains:
//
//   count
//   sum
//   minimum
//   maximum
// ------------------------------------------------------------

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
// Print basic collection metadata
// ------------------------------------------------------------

function printPopulationMetadata(
  collection,
  label
) {

  print(
    label + ' - number of images:',
    collection.size()
  );

  print(
    label + ' - years:',
    collection.aggregate_array(
      'year'
    )
  );

  print(
    label + ' - source years:',
    collection.aggregate_array(
      'source_year'
    )
  );

  print(
    label + ' - sex:',
    collection.aggregate_array(
      'sex'
    )
  );

  print(
    label + ' - system:index:',
    collection.aggregate_array(
      'system:index'
    )
  );

  print(
    label + ' - time_start:',
    collection.aggregate_array(
      'system:time_start'
    )
  );


  var imagesPerYear =
    YEARS.map(
      function(year) {

        year = ee.Number(
          year
        );

        return collection
          .filter(
            ee.Filter.eq(
              'year',
              year
            )
          )
          .size();

      }
    );


  print(
    label + ' - images per year:',
    imagesPerYear
  );

}


// ------------------------------------------------------------
// Build annual QA FeatureCollection
// ------------------------------------------------------------

function buildPopulationQA(
  collection,
  label
) {

  return ee.FeatureCollection(

    YEARS.map(
      function(year) {

        year = ee.Number(
          year
        );


        var img =
          getPopulationImage(
            collection,
            year
          );


        var stats =
          img.reduceRegion({

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
          )
          .subtract(
            validPixels
          );


        return ee.Feature(
          null,
          {

            population_group:
              label,

            year:
              year,

            source_year:
              img.get(
                'source_year'
              ),

            sex:
              img.get(
                'sex'
              ),

            date:
              ee.Date(
                img.get(
                  'system:time_start'
                )
              )
              .format(
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

      }
    )

  )
  .sort(
    'year'
  );

}


// ------------------------------------------------------------
// Print QA summary
// ------------------------------------------------------------

function printPopulationQA(
  qa,
  label
) {

  print(
    label + ' QA:',
    qa
  );

  print(
    label + ' QA - years:',
    qa.aggregate_array(
      'year'
    )
  );

  print(
    label + ' QA - source years:',
    qa.aggregate_array(
      'source_year'
    )
  );

  print(
    label + ' QA - sex:',
    qa.aggregate_array(
      'sex'
    )
  );

  print(
    label + ' QA - dates:',
    qa.aggregate_array(
      'date'
    )
  );

  print(
    label + ' QA - valid pixels:',
    qa.aggregate_array(
      'valid_pixels'
    )
  );

  print(
    label + ' QA - NoData pixels:',
    qa.aggregate_array(
      'nodata_pixels'
    )
  );

  print(
    label + ' QA - population sums:',
    qa.aggregate_array(
      'population_sum'
    )
  );

  print(
    label + ' QA - minimum:',
    qa.aggregate_array(
      'population_min'
    )
  );

  print(
    label + ' QA - maximum:',
    qa.aggregate_array(
      'population_max'
    )
  );

}


// ============================================================
// 4. POPULATION COLLECTION METADATA QA
// ============================================================

printPopulationMetadata(
  popTotal,
  'Population TOTAL'
);

printPopulationMetadata(
  popFemale,
  'Population FEMALE'
);

printPopulationMetadata(
  popMale,
  'Population MALE'
);

print(
  'Expected population source years:',
  EXPECTED_SOURCE_YEARS
);


// ============================================================
// 5. POPULATION PROJECTION QA
// ============================================================

var popTotalGridReference =
  getPopulationImage(
    popTotalAll,
    GRID_REFERENCE_YEAR
  );

var popFemaleGridReference =
  getPopulationImage(
    popFemaleAll,
    GRID_REFERENCE_YEAR
  );

var popMaleGridReference =
  getPopulationImage(
    popMaleAll,
    GRID_REFERENCE_YEAR
  );


print(
  'Population grid reference year:',
  GRID_REFERENCE_YEAR
);

print(
  'Population TOTAL grid reference - projection:',
  popTotalGridReference.projection()
);

print(
  'Population FEMALE grid reference - projection:',
  popFemaleGridReference.projection()
);

print(
  'Population MALE grid reference - projection:',
  popMaleGridReference.projection()
);


print(
  'Population TOTAL grid reference - nominal scale:',
  popTotalGridReference
    .projection()
    .nominalScale()
);

print(
  'Population FEMALE grid reference - nominal scale:',
  popFemaleGridReference
    .projection()
    .nominalScale()
);

print(
  'Population MALE grid reference - nominal scale:',
  popMaleGridReference
    .projection()
    .nominalScale()
);


// ============================================================
// 6. POPULATION ANNUAL QA
// ============================================================

var populationTotalQA =
  buildPopulationQA(
    popTotal,
    'total'
  );

var populationFemaleQA =
  buildPopulationQA(
    popFemale,
    'female'
  );

var populationMaleQA =
  buildPopulationQA(
    popMale,
    'male'
  );


printPopulationQA(
  populationTotalQA,
  'Population TOTAL'
);

printPopulationQA(
  populationFemaleQA,
  'Population FEMALE'
);

printPopulationQA(
  populationMaleQA,
  'Population MALE'
);


// ============================================================
// 7. CROSS-POPULATION QA
//
// Two complementary checks:
//
//   A. Population totals
//      Reuses the annual QA results already calculated above.
//      No additional raster reduction is required.
//
//   B. Mask consistency
//      Uses one encoded mask image instead of three separate
//      mismatch rasters.
//
// IMPORTANT:
//
// Total is an independent WorldPop product.
//
// Female + Male is used ONLY as QA and must not replace Total.
// ============================================================


// ============================================================
// 7A. POPULATION TOTALS QA
// ============================================================

var populationCrossTotalsQA =
  ee.FeatureCollection(

    YEARS.map(
      function(year) {

        year = ee.Number(
          year
        );


        var totalFeature =
          ee.Feature(
            populationTotalQA
              .filter(
                ee.Filter.eq(
                  'year',
                  year
                )
              )
              .first()
          );


        var femaleFeature =
          ee.Feature(
            populationFemaleQA
              .filter(
                ee.Filter.eq(
                  'year',
                  year
                )
              )
              .first()
          );


        var maleFeature =
          ee.Feature(
            populationMaleQA
              .filter(
                ee.Filter.eq(
                  'year',
                  year
                )
              )
              .first()
          );


        var totalSum =
          ee.Number(
            totalFeature.get(
              'population_sum'
            )
          );


        var femaleSum =
          ee.Number(
            femaleFeature.get(
              'population_sum'
            )
          );


        var maleSum =
          ee.Number(
            maleFeature.get(
              'population_sum'
            )
          );


        var femalePlusMale =
          femaleSum.add(
            maleSum
          );


        var difference =
          femalePlusMale.subtract(
            totalSum
          );


        var relativeDifference =
          difference
            .divide(
              totalSum
            )
            .multiply(
              100
            );


        return ee.Feature(
          null,
          {

            year:
              year,

            total_sum:
              totalSum,

            female_sum:
              femaleSum,

            male_sum:
              maleSum,

            female_plus_male_sum:
              femalePlusMale,

            female_plus_male_minus_total:
              difference,

            female_plus_male_minus_total_pct:
              relativeDifference

          }
        );

      }
    )

  )
  .sort(
    'year'
  );


print(
  '================================================'
);

print(
  '7A. POPULATION TOTALS QA'
);

print(
  '================================================'
);


print(
  'Female + Male versus Total:',
  populationCrossTotalsQA
);


// ============================================================
// 7B. POPULATION MASK QA
//
// Each pixel receives one code according to the valid masks:
//
//   Total  = 1
//   Female = 2
//   Male   = 4
//
// Therefore:
//
//   0 = none valid
//   1 = Total only
//   2 = Female only
//   3 = Total + Female
//   4 = Male only
//   5 = Total + Male
//   6 = Female + Male
//   7 = Total + Female + Male
//
// A single histogram therefore describes all mask relations.
// ============================================================

var populationMaskQA =
  ee.FeatureCollection(

    YEARS.map(
      function(year) {

        year = ee.Number(
          year
        );


        var total =
          getPopulationImage(
            popTotal,
            year
          );


        var female =
          getPopulationImage(
            popFemale,
            year
          );


        var male =
          getPopulationImage(
            popMale,
            year
          );


        // ----------------------------------------------------
        // Valid-data masks
        // ----------------------------------------------------

        var totalValid =
          total
            .mask()
            .gt(0)
            .unmask(0)
            .toByte();


        var femaleValid =
          female
            .mask()
            .gt(0)
            .unmask(0)
            .toByte();


        var maleValid =
          male
            .mask()
            .gt(0)
            .unmask(0)
            .toByte();


        // ----------------------------------------------------
        // Encode the three masks into one Byte image
        // ----------------------------------------------------

        var maskCode =
          totalValid

            .add(
              femaleValid.multiply(
                2
              )
            )

            .add(
              maleValid.multiply(
                4
              )
            )

            .rename(
              'mask_code'
            )

            .toByte();


        // ----------------------------------------------------
        // One raster reduction only
        // ----------------------------------------------------

        var histogramResult =
          maskCode.reduceRegion({

            reducer:
              ee.Reducer
                .frequencyHistogram()
                .unweighted(),

            geometry:
              total.geometry(),

            crs:
              POP_CRS,

            crsTransform:
              POP_TRANSFORM,

            maxPixels:
              3e9,

            tileScale:
              4

          });


        var histogram =
          ee.Dictionary(
            histogramResult.get(
              'mask_code'
            )
          );


        // ----------------------------------------------------
        // Counts for each mask combination
        // ----------------------------------------------------

        var n0 =
          ee.Number(
            histogram.get(
              '0',
              0
            )
          );

        var n1 =
          ee.Number(
            histogram.get(
              '1',
              0
            )
          );

        var n2 =
          ee.Number(
            histogram.get(
              '2',
              0
            )
          );

        var n3 =
          ee.Number(
            histogram.get(
              '3',
              0
            )
          );

        var n4 =
          ee.Number(
            histogram.get(
              '4',
              0
            )
          );

        var n5 =
          ee.Number(
            histogram.get(
              '5',
              0
            )
          );

        var n6 =
          ee.Number(
            histogram.get(
              '6',
              0
            )
          );

        var n7 =
          ee.Number(
            histogram.get(
              '7',
              0
            )
          );


        // ----------------------------------------------------
        // Exact mismatch counts
        //
        // Female != Male:
        //   codes 2, 3, 4, 5
        //
        // Female != Total:
        //   codes 1, 2, 5, 6
        //
        // Male != Total:
        //   codes 1, 3, 4, 6
        // ----------------------------------------------------

        var femaleMaleMismatch =
          n2
            .add(n3)
            .add(n4)
            .add(n5);


        var femaleTotalMismatch =
          n1
            .add(n2)
            .add(n5)
            .add(n6);


        var maleTotalMismatch =
          n1
            .add(n3)
            .add(n4)
            .add(n6);


        return ee.Feature(
          null,
          {

            year:
              year,

            mask_none_valid:
              n0,

            mask_total_only:
              n1,

            mask_female_only:
              n2,

            mask_total_female:
              n3,

            mask_male_only:
              n4,

            mask_total_male:
              n5,

            mask_female_male:
              n6,

            mask_all_three:
              n7,

            female_male_mask_mismatch_pixels:
              femaleMaleMismatch,

            female_total_mask_mismatch_pixels:
              femaleTotalMismatch,

            male_total_mask_mismatch_pixels:
              maleTotalMismatch

          }
        );

      }
    )

  )
  .sort(
    'year'
  );


print(
  '================================================'
);

print(
  '7B. POPULATION MASK QA'
);

print(
  '================================================'
);


// IMPORTANT:
//
// Keep only ONE print of this computationally expensive
// FeatureCollection. Do not issue multiple aggregate_array()
// calls, because each print may trigger another server request.

print(
  'Population mask QA:',
  populationMaskQA
);


// ============================================================
// 8. VISUAL CHECK - FIRST ANALYTICAL YEAR
//
// Visual aid only.
// No analytical product is generated here.
// ============================================================

var droughtVisual = ee.Image(
  drought
    .filter(
      ee.Filter.eq(
        'year',
        YEAR_START
      )
    )
    .first()
)
.select(0)
.rename(
  'drought_class'
);

var popTotalVisual =
  getPopulationImage(
    popTotal,
    YEAR_START
  );

var popFemaleVisual =
  getPopulationImage(
    popFemale,
    YEAR_START
  );

var popMaleVisual =
  getPopulationImage(
    popMale,
    YEAR_START
  );


Map.centerObject(
  droughtVisual,
  4
);


// ------------------------------------------------------------
// Drought
// ------------------------------------------------------------

Map.addLayer(
  droughtVisual,
  {
    min: 1,
    max: 5
  },
  'Drought classes ' + YEAR_START,
  true
);


// ------------------------------------------------------------
// Total population
// ------------------------------------------------------------

Map.addLayer(
  popTotalVisual,
  {
    min: 0,
    max: 100
  },
  'Population TOTAL ' + YEAR_START,
  false
);


// ------------------------------------------------------------
// Female population
// ------------------------------------------------------------

Map.addLayer(
  popFemaleVisual,
  {
    min: 0,
    max: 50
  },
  'Population FEMALE ' + YEAR_START,
  false
);


// ------------------------------------------------------------
// Male population
// ------------------------------------------------------------

Map.addLayer(
  popMaleVisual,
  {
    min: 0,
    max: 50
  },
  'Population MALE ' + YEAR_START,
  false
);


// ============================================================
// END
// ============================================================

print(
  '================================================'
);

print(
  'INPUT QA SCRIPT COMPLETED'
);

print(
  'Period:',
  PERIOD
);

print(
  'Expected population groups: total, female, male'
);

print(
  'Expected analytical years:',
  YEARS
);

print(
  '================================================'
);
