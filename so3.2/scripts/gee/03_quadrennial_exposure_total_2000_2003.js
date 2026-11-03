// ============================================================
// PRAIS4 / SO3.2
// PERIOD PROCESSING
//
// ANNUAL OUTPUT:
//   National statistics required for:
//     SO3-2.T1 - Total population
//     SO3-2.T2 - Female population
//     SO3-2.T3 - Male population
//
// QUADRENNIAL OUTPUT:
//   Integrated raster representing population exposure to the
//   greatest drought intensity observed during the period.
//
// Population groups:
//   - Total
//   - Female
//   - Male
//
// IMPORTANT:
//
// Total, Female and Male are independent population products.
// Female + Male is used only for QA and never replaces Total.
//
// Population data are annual through 2020.
// For analytical years 2021-2023, population reuses the
// WorldPop 2020 source.
//
// Drought remains ANNUAL through 2023.
// ============================================================


// ============================================================
// 0. PERIOD CONFIGURATION
// ============================================================
//
// THIS IS THE MAIN BLOCK TO CHANGE BETWEEN QUADRENNIA.
//
// All period labels, output names and metadata are derived
// automatically from these analytical years.
// ============================================================

var YEARS_JS = [
  2016,
  2017,
  2018,
  2019
];

var WORLDPOP_LAST_SOURCE_YEAR = 2020;

// ------------------------------------------------------------
// Protection: exactly four consecutive analytical years
// ------------------------------------------------------------

if (YEARS_JS.length !== 4) {

  throw new Error(
    'Expected exactly 4 analytical years. Received: ' +
    YEARS_JS.length
  );

}


for (
  var i = 1;
  i < YEARS_JS.length;
  i++
) {

  if (
    YEARS_JS[i] !==
    YEARS_JS[i - 1] + 1
  ) {

    throw new Error(
      'Analytical years must be consecutive: ' +
      YEARS_JS.join(', ')
    );

  }

}


// ------------------------------------------------------------
// Derive nominal period automatically
// ------------------------------------------------------------

var YEAR_START =
  Math.min.apply(
    null,
    YEARS_JS
  );


var YEAR_END =
  Math.max.apply(
    null,
    YEARS_JS
  );


var PERIOD =
  YEAR_START +
  '-' +
  YEAR_END;


var PERIOD_ID =
  YEAR_START +
  '_' +
  YEAR_END;


var YEARS_EE =
  ee.List(
    YEARS_JS
  );


// ============================================================
// 1. PROCESSING / EXPORT CONTROLS
// ============================================================
//
// For 2000-2003:
//
// The quadrennial master raster already exists from the
// validated previous execution.
//
// Therefore:
//
//   annual CSV = TRUE
//   quad asset = FALSE
//
// For new quadrennia, normally both will be TRUE.
// ============================================================

var EXPORT_ANNUAL_STATS =
  true;


var EXPORT_QUAD_ASSET =
  true;


// ------------------------------------------------------------
// Avoid synchronous execution of the heavy annual reductions.
//
// Set TRUE only when explicitly needed.
// ------------------------------------------------------------

var PRINT_ANNUAL_TABLE =
  false;


// ------------------------------------------------------------
// Optional visual inspection
// ------------------------------------------------------------

var SHOW_MAP =
  false;


// ============================================================
// 2. ASSETS AND OUTPUT NAMES
// ============================================================

var ASSET_ROOT =
  'projects/cursoqueimadas-503722/assets/';


// ------------------------------------------------------------
// Inputs
// ------------------------------------------------------------

var DROUGHT_ASSET =
  ASSET_ROOT +
  'drought_spei12_dec';


var POP_TOTAL_ASSET =
  ASSET_ROOT +
  'population_total';


var POP_FEMALE_ASSET =
  ASSET_ROOT +
  'population_female';


var POP_MALE_ASSET =
  ASSET_ROOT +
  'population_male';


// ------------------------------------------------------------
// Annual statistics output
//
// Example:
// SO32_annual_statistics_2000_2003.csv
// ------------------------------------------------------------

var ANNUAL_STATS_NAME =
  'SO32_annual_statistics_' +
  PERIOD_ID;


var ANNUAL_STATS_FOLDER =
  'PRAIS4_SO3';


// ------------------------------------------------------------
// Quadrennial raster output
//
// Example:
// SO32_exposure_quadrennial_2000_2003
// ------------------------------------------------------------

var QUAD_OUTPUT_NAME =
  'SO32_exposure_quadrennial_' +
  PERIOD_ID;


var QUAD_OUTPUT_ASSET =
  ASSET_ROOT +
  QUAD_OUTPUT_NAME;


// ============================================================
// 3. EXACT WORLDPOP TARGET GRID
// ============================================================

var POP_CRS =
  'EPSG:4326';


var POP_TRANSFORM = [
   0.0008333333300044304,
   0,
  -73.989583022,
   0,
  -0.0008333333300081173,
   5.264583514
];


var POP_WIDTH =
  54172;


var POP_HEIGHT =
  46814;


var POP_DIMENSIONS =
  POP_WIDTH +
  'x' +
  POP_HEIGHT;


// ============================================================
// 4. INPUT COLLECTIONS
// ============================================================

var drought =
  ee.ImageCollection(
    DROUGHT_ASSET
  );


var populationTotal =
  ee.ImageCollection(
    POP_TOTAL_ASSET
  );


var populationFemale =
  ee.ImageCollection(
    POP_FEMALE_ASSET
  );


var populationMale =
  ee.ImageCollection(
    POP_MALE_ASSET
  );


// ============================================================
// 5. POPULATION GROUP CONFIGURATION
// ============================================================

var POPULATION_GROUPS = [

  {
    sex:
      'total',

    collection:
      populationTotal
  },

  {
    sex:
      'female',

    collection:
      populationFemale
  },

  {
    sex:
      'male',

    collection:
      populationMale
  }

];


// ============================================================
// 6. SUPPORT FUNCTIONS
// ============================================================

function getDrought(
  year
) {

  return ee.Image(

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
  )
  .toByte();

}


// ------------------------------------------------------------
// Population is ALWAYS selected using analytical year.
//
// Example:
//
// analytical year = 2023
// population year = 2023
// source_year     = 2020
//
// source_year records provenance.
// It is NOT the temporal key used to associate population
// with drought.
// ------------------------------------------------------------

function getPopulation(
  populationCollection,
  year
) {

  year =
    ee.Number(
      year
    );


  // ----------------------------------------------------------
  // PRAIS 4 population-source rule
  //
  // 2000-2020 -> use the corresponding WorldPop year
  // 2021-2023 -> reuse WorldPop 2020
  // ----------------------------------------------------------

  var sourceYear =
    year
      .min(
        WORLDPOP_LAST_SOURCE_YEAR
      )
      .toInt();


  var population =
    ee.Image(

      populationCollection
        .filter(
          ee.Filter.eq(
            'year',
            sourceYear
          )
        )
        .first()

    )
    .select(0)
    .rename(
      'population'
    );


  // ----------------------------------------------------------
  // Preserve both temporal meanings:
  //
  // year        = analytical year
  // source_year = actual WorldPop source
  // ----------------------------------------------------------

  return population
    .set(
      'year',
      year
    )
    .set(
      'source_year',
      sourceYear
    );

}

// ------------------------------------------------------------
// Expected population source year.
//
// Applies ONLY to population.
//
// Drought remains annual through 2023.
// ------------------------------------------------------------

function expectedPopulationSourceYear(
  year
) {

  return Math.min(
    year,
    WORLDPOP_LAST_SOURCE_YEAR
  );

}


// ------------------------------------------------------------
// Safe retrieval from reduceRegion dictionaries
// ------------------------------------------------------------

function statOrZero(
  stats,
  key
) {

  return ee.Number(

    ee.Algorithms.If(

      stats.get(
        key
      ),

      stats.get(
        key
      ),

      0

    )

  );

}


// ============================================================
// 7. LIGHT INPUT QA
// ============================================================
//
// No large raster reductions are executed here.
//
// Checks:
//   - period;
//   - number of images;
//   - analytical years;
//   - population source years.
// ============================================================

print(
  '========================================'
);


print(
  'SO3.2 PERIOD PROCESSING'
);


print(
  'Period:',
  PERIOD
);


print(
  'Annual statistics output:',
  ANNUAL_STATS_NAME
);


print(
  'Quadrennial output:',
  QUAD_OUTPUT_NAME
);


print(
  '========================================'
);


// ------------------------------------------------------------
// Drought
// ------------------------------------------------------------

var droughtPeriodInput =
  drought
    .filter(
      ee.Filter.inList(
        'year',
        YEARS_EE
      )
    );


print(
  'Drought images expected:',
  YEARS_JS.length
);


print(
  'Drought images found:',
  droughtPeriodInput.size()
);


print(
  'Drought analytical years:',
  droughtPeriodInput
    .aggregate_array(
      'year'
    )
    .sort()
);


// ------------------------------------------------------------
// Population
// ------------------------------------------------------------

POPULATION_GROUPS.forEach(
  function(group) {

    var subset =
      group.collection
        .filter(
          ee.Filter.inList(
            'year',
            YEARS_EE
          )
        );


    print(
      'Population ' +
      group.sex +
      ' images found:',

      subset.size()
    );


    print(
      'Population ' +
      group.sex +
      ' analytical years:',

      subset
        .aggregate_array(
          'year'
        )
        .sort()
    );


    print(
      'Population ' +
      group.sex +
      ' source years:',

      subset
        .aggregate_array(
          'source_year'
        )
        .sort()
    );

  }
);


// ------------------------------------------------------------
// Expected population source-year policy
// ------------------------------------------------------------

var EXPECTED_SOURCE_YEARS =
  YEARS_JS.map(
    function(year) {

      return expectedPopulationSourceYear(
        year
      );

    }
  );


print(
  'Expected population source years:',
  EXPECTED_SOURCE_YEARS
);


// ============================================================
// 8. ANNUAL NATIONAL STATISTICS
// ============================================================
//
// Source for:
//
//   SO3-2.T1
//   SO3-2.T2
//   SO3-2.T3
//
// No annual exposure raster is persisted.
//
// For each analytical year and population group:
//
//   population is summed according to annual drought class.
//
// Classes:
//
//   1 = Extreme
//   2 = Severe
//   3 = Moderate
//   4 = Weak
//   5 = Normal
//
// Exposed population:
//
//   classes 1 + 2 + 3 + 4
// ============================================================

function buildAnnualStatistics(
  year,
  populationCollection,
  sex
) {

  year =
    ee.Number(
      year
    );


  var droughtYear =
    getDrought(
      year
    );


  var populationYear =
    getPopulation(
      populationCollection,
      year
    );


  // ----------------------------------------------------------
  // Complete population support
  // ----------------------------------------------------------

  var populationAll =
    populationYear
      .rename(
        'population_total'
      );


  // ----------------------------------------------------------
  // Population where drought information is valid
  // ----------------------------------------------------------

  var populationDroughtValid =
    populationYear
      .updateMask(
        droughtYear.mask()
      )
      .rename(
        'population_drought_valid'
      );


  // ----------------------------------------------------------
  // Population by annual drought class
  // ----------------------------------------------------------

  var class1 =
    populationYear
      .updateMask(
        droughtYear.eq(1)
      )
      .rename(
        'class_1'
      );


  var class2 =
    populationYear
      .updateMask(
        droughtYear.eq(2)
      )
      .rename(
        'class_2'
      );


  var class3 =
    populationYear
      .updateMask(
        droughtYear.eq(3)
      )
      .rename(
        'class_3'
      );


  var class4 =
    populationYear
      .updateMask(
        droughtYear.eq(4)
      )
      .rename(
        'class_4'
      );


  var class5 =
    populationYear
      .updateMask(
        droughtYear.eq(5)
      )
      .rename(
        'class_5'
      );


  // ----------------------------------------------------------
  // One reduction for this analytical year / population group
  // ----------------------------------------------------------

  var annualImage =
    ee.Image.cat([

      populationAll,

      populationDroughtValid,

      class1,
      class2,
      class3,
      class4,
      class5

    ]);


  var stats =
    annualImage.reduceRegion({

      reducer:
        ee.Reducer.sum(),

      geometry:
        populationYear.geometry(),

      crs:
        POP_CRS,

      crsTransform:
        POP_TRANSFORM,

      maxPixels:
        3e10,

      tileScale:
        4

    });


  // ----------------------------------------------------------
  // Absolute values
  // ----------------------------------------------------------

  var total =
    statOrZero(
      stats,
      'population_total'
    );


  var valid =
    statOrZero(
      stats,
      'population_drought_valid'
    );


  var c1 =
    statOrZero(
      stats,
      'class_1'
    );


  var c2 =
    statOrZero(
      stats,
      'class_2'
    );


  var c3 =
    statOrZero(
      stats,
      'class_3'
    );


  var c4 =
    statOrZero(
      stats,
      'class_4'
    );


  var c5 =
    statOrZero(
      stats,
      'class_5'
    );


  var exposed =
    c1
      .add(c2)
      .add(c3)
      .add(c4);


  var classSum =
    exposed
      .add(c5);


  // ----------------------------------------------------------
  // Output row
  // ----------------------------------------------------------

  return ee.Feature(
    null,
    {

      period:
        PERIOD,

      year:
        year,

      sex:
        sex,

      source_year:
        populationYear.get(
          'source_year'
        ),


      // ------------------------------------------------------
      // Absolute population values
      // ------------------------------------------------------

      population_total:
        total,

      population_drought_valid:
        valid,

      population_drought_missing:
        total.subtract(
          valid
        ),

      population_class_1:
        c1,

      population_class_2:
        c2,

      population_class_3:
        c3,

      population_class_4:
        c4,

      population_class_5:
        c5,

      population_exposed:
        exposed,


      // ------------------------------------------------------
      // Percentages using complete population as denominator
      //
      // These are retained for the PRAIS reporting pathway.
      // ------------------------------------------------------

      pct_class_1_total:
        c1
          .divide(total)
          .multiply(100),

      pct_class_2_total:
        c2
          .divide(total)
          .multiply(100),

      pct_class_3_total:
        c3
          .divide(total)
          .multiply(100),

      pct_class_4_total:
        c4
          .divide(total)
          .multiply(100),

      pct_class_5_total:
        c5
          .divide(total)
          .multiply(100),

      exposed_pct_total:
        exposed
          .divide(total)
          .multiply(100),


      // ------------------------------------------------------
      // Percentages using drought-valid population
      //
      // Retained for QA / audit.
      // ------------------------------------------------------

      pct_class_1_drought_valid:
        c1
          .divide(valid)
          .multiply(100),

      pct_class_2_drought_valid:
        c2
          .divide(valid)
          .multiply(100),

      pct_class_3_drought_valid:
        c3
          .divide(valid)
          .multiply(100),

      pct_class_4_drought_valid:
        c4
          .divide(valid)
          .multiply(100),

      pct_class_5_drought_valid:
        c5
          .divide(valid)
          .multiply(100),

      exposed_pct_drought_valid:
        exposed
          .divide(valid)
          .multiply(100),


      // ------------------------------------------------------
      // QA
      // ------------------------------------------------------

      drought_coverage_pct:
        valid
          .divide(total)
          .multiply(100),

      class_balance:
        valid.subtract(
          classSum
        )

    }
  );

}


// ============================================================
// 9. BUILD ANNUAL STATISTICS TABLE
// ============================================================
//
// Expected for one quadrennium:
//
//   4 analytical years x 3 population groups
//   = 12 records
// ============================================================

var annualFeatures =
  [];


YEARS_JS.forEach(
  function(year) {

    POPULATION_GROUPS.forEach(
      function(group) {

        annualFeatures.push(

          buildAnnualStatistics(
            year,
            group.collection,
            group.sex
          )

        );

      }
    );

  }
);


var annualStatistics =
  ee.FeatureCollection(
    annualFeatures
  );


print(
  'Annual statistics expected records:',
  YEARS_JS.length *
  POPULATION_GROUPS.length
);


if (PRINT_ANNUAL_TABLE) {

  print(
    'Annual statistics table:',
    annualStatistics
  );

}


// ============================================================
// 10. EXPORT ANNUAL STATISTICS
// ============================================================
//
// This CSV is small.
//
// It becomes the local source for:
//
//   T1 = sex == total
//   T2 = sex == female
//   T3 = sex == male
//
// No annual exposure raster is stored.
// ============================================================

if (EXPORT_ANNUAL_STATS) {

  Export.table.toDrive({

    collection:
      annualStatistics,

    description:
      ANNUAL_STATS_NAME,

    folder:
      ANNUAL_STATS_FOLDER,

    fileNamePrefix:
      ANNUAL_STATS_NAME,

    fileFormat:
      'CSV',

    selectors: [

      'period',
      'year',
      'sex',
      'source_year',

      'population_total',
      'population_drought_valid',
      'population_drought_missing',

      'population_class_1',
      'population_class_2',
      'population_class_3',
      'population_class_4',
      'population_class_5',

      'population_exposed',

      'pct_class_1_total',
      'pct_class_2_total',
      'pct_class_3_total',
      'pct_class_4_total',
      'pct_class_5_total',

      'exposed_pct_total',

      'pct_class_1_drought_valid',
      'pct_class_2_drought_valid',
      'pct_class_3_drought_valid',
      'pct_class_4_drought_valid',
      'pct_class_5_drought_valid',

      'exposed_pct_drought_valid',

      'drought_coverage_pct',
      'class_balance'

    ]

  });

}


// ============================================================
// 11. DROUGHT DURING THE QUADRENNIUM
// ============================================================

var droughtPeriod =
  ee.ImageCollection.fromImages(

    YEARS_EE.map(
      function(year) {

        return getDrought(
          year
        );

      }
    )

  );


// ------------------------------------------------------------
// Lowest class number = greatest drought intensity.
//
// 1 = Extreme
// 2 = Severe
// 3 = Moderate
// 4 = Weak
// 5 = Normal
//
// NoData remains masked.
// ------------------------------------------------------------

var worstDrought =
  droughtPeriod
    .min()
    .rename(
      'worst_drought_class'
    )
    .toByte();


// ============================================================
// 12. HAZARD QA
// ============================================================

// ------------------------------------------------------------
// Number of analytical years containing valid drought data
// ------------------------------------------------------------

var hazardValidYears =
  droughtPeriod
    .count()
    .rename(
      'hazard_valid_years'
    )
    .toByte();


// ------------------------------------------------------------
// 1 = at least one drought year missing
// 0 = all four drought years available
// ------------------------------------------------------------

var hazardMissingFlag =
  hazardValidYears
    .lt(
      YEARS_JS.length
    )
    .rename(
      'hazard_missing_flag'
    )
    .toByte();


// ============================================================
// 13. BUILD QUADRENNIAL POPULATION COMPONENT
// ============================================================
//
// For each population group:
//
//   1. identify the year(s) in which drought equals the
//      greatest drought intensity observed in the period;
//
//   2. retain population only for those critical year(s);
//
//   3. if several years tie, calculate mean population;
//
//   4. count the number of critical years;
//
//   5. retain exposed population only for drought classes 1-4.
//
// The same drought field is used for Total, Female and Male.
//
// The three population products remain independent.
// ============================================================

function buildQuadrennialPopulation(
  populationCollection,
  sex
) {


  // ----------------------------------------------------------
  // Population corresponding to critical drought year(s)
  // ----------------------------------------------------------

  var criticalPopulationCollection =
    ee.ImageCollection.fromImages(

      YEARS_EE.map(
        function(year) {


          var droughtYear =
            getDrought(
              year
            );


          var populationYear =
            getPopulation(
              populationCollection,
              year
            );


          var critical =
            droughtYear.eq(
              worstDrought
            );


          return populationYear
            .updateMask(
              critical
            )
            .rename(
              'critical_population'
            );

        }
      )

    );


  // ----------------------------------------------------------
  // Mean population when the worst drought class is tied
  // between two or more analytical years
  // ----------------------------------------------------------

  var criticalPopulationMean =
    criticalPopulationCollection
      .mean()
      .rename(
        'critical_population_mean'
      );


  // ----------------------------------------------------------
  // Count critical years while preserving population support
  // ----------------------------------------------------------

  var criticalCountCollection =
    ee.ImageCollection.fromImages(

      YEARS_EE.map(
        function(year) {


          var droughtYear =
            getDrought(
              year
            );


          var populationYear =
            getPopulation(
              populationCollection,
              year
            );


          var critical =
            droughtYear.eq(
              worstDrought
            );


          return populationYear
            .multiply(0)
            .add(1)
            .updateMask(
              critical
            )
            .rename(
              'critical_year'
            );

        }
      )

    );


  var criticalYearCount =
    criticalCountCollection
      .sum()
      .rename(
        'critical_year_count_' +
        sex
      )
      .toByte();


  // ----------------------------------------------------------
  // Classes 1-4 = exposed
  // Class 5     = not exposed
  //
  // As in the validated original Script 03, class 5 remains
  // masked in this analytical population-exposed band.
  //
  // Delivery semantics are handled downstream:
  //
  //   class 5        -> 0
  //   true NoData    -> NoData
  // ----------------------------------------------------------

  var exposedMask =
    worstDrought
      .gte(1)
      .and(
        worstDrought.lte(4)
      );


  var populationExposed =
    criticalPopulationMean
      .updateMask(
        exposedMask
      )
      .rename(
        'population_exposed_' +
        sex
      );


  return ee.Image.cat([

    populationExposed,

    criticalYearCount

  ]);

}


// ============================================================
// 14. BUILD THE THREE QUADRENNIAL POPULATION COMPONENTS
// ============================================================

var quadTotal =
  buildQuadrennialPopulation(
    populationTotal,
    'total'
  );


var quadFemale =
  buildQuadrennialPopulation(
    populationFemale,
    'female'
  );


var quadMale =
  buildQuadrennialPopulation(
    populationMale,
    'male'
  );


// ============================================================
// 15. SOURCE-YEAR METADATA
// ============================================================
//
// Examples:
//
// 2000-2003:
//
//   [2000, 2001, 2002, 2003]
//
// 2020-2023:
//
//   [2020, 2020, 2020, 2020]
// ============================================================

var POPULATION_SOURCE_YEARS =
  EXPECTED_SOURCE_YEARS.join(',');


var POPULATION_SOURCE_POLICY =

  YEAR_END <= 2020

    ? 'annual WorldPop matching analytical year'

    : 'WorldPop 2020 reused for analytical years 2021-2023';


// ============================================================
// 16. FINAL INTEGRATED QUADRENNIAL PRODUCT
// ============================================================
//
// Band order:
//
//   1  worst_drought_class
//   2  hazard_valid_years
//   3  hazard_missing_flag
//
//   4  population_exposed_total
//   5  critical_year_count_total
//
//   6  population_exposed_female
//   7  critical_year_count_female
//
//   8  population_exposed_male
//   9  critical_year_count_male
// ============================================================

var quadrennialProduct =
  ee.Image.cat([

    worstDrought,

    hazardValidYears,

    hazardMissingFlag,

    quadTotal,

    quadFemale,

    quadMale

  ])

  .set({

    period:
      PERIOD,

    year_start:
      YEAR_START,

    year_end:
      YEAR_END,

    analytical_years:
      YEARS_JS.join(','),

    variable:
      'population_exposure',

    population_groups:
      'total,female,male',

    drought_classes_exposed:
      '1-4',

    drought_normal_class:
      5,

    drought_period_rule:
      'minimum_valid_class',

    population_tie_rule:
      'mean_of_critical_years',

    population_year_key:
      'year',

    population_source_year_property:
      'source_year',

    population_source_years_expected:
      POPULATION_SOURCE_YEARS,

    population_source_policy:
      POPULATION_SOURCE_POLICY,

    drought_source_policy:
      'annual drought matching analytical year',

    drought_resampling:
      'nearest_neighbor',

    target_grid:
      'WorldPop_native',

    grid_width:
      POP_WIDTH,

    grid_height:
      POP_HEIGHT,

    grid_definition:
      'dimensions_crs_crsTransform'

  });


// ============================================================
// 17. PRE-EXPORT CHECK
// ============================================================

print(
  '========================================'
);


print(
  'PRE-EXPORT CHECK'
);


print(
  '========================================'
);


print(
  'Quadrennial product bands:',
  quadrennialProduct.bandNames()
);


print(
  'Expected number of bands:',
  9
);


print(
  'Expected dimensions:',
  POP_DIMENSIONS
);


print(
  'Expected CRS:',
  POP_CRS
);


print(
  'Expected transform:',
  POP_TRANSFORM
);


print(
  'Quadrennial output Asset:',
  QUAD_OUTPUT_ASSET
);


// ============================================================
// 18. EXPORT QUADRENNIAL PRODUCT
// ============================================================
//
// No "region" is used.
//
// Exact dimensions + CRS + affine transform define the
// complete WorldPop target raster.
//
// ONE quadrennium = ONE integrated raster Asset.
//
// For 2000-2003 this is currently disabled because the Asset
// produced yesterday already exists.
// ============================================================

if (EXPORT_QUAD_ASSET) {

  Export.image.toAsset({

    image:
      quadrennialProduct,

    description:
      QUAD_OUTPUT_NAME,

    assetId:
      QUAD_OUTPUT_ASSET,

    dimensions:
      POP_DIMENSIONS,

    crs:
      POP_CRS,

    crsTransform:
      POP_TRANSFORM,

    maxPixels:
      1e13,

    pyramidingPolicy: {

      worst_drought_class:
        'mode',

      hazard_valid_years:
        'mode',

      hazard_missing_flag:
        'mode',

      population_exposed_total:
        'mean',

      critical_year_count_total:
        'mode',

      population_exposed_female:
        'mean',

      critical_year_count_female:
        'mode',

      population_exposed_male:
        'mean',

      critical_year_count_male:
        'mode'

    }

  });

}


// ============================================================
// 19. OPTIONAL VISUAL CHECK
// ============================================================

if (SHOW_MAP) {

  Map.centerObject(

    getPopulation(
      populationTotal,
      YEAR_START
    ),

    4

  );


  Map.addLayer(

    worstDrought,

    {
      min: 1,
      max: 5
    },

    'Worst drought class ' +
    PERIOD,

    true

  );


  Map.addLayer(

    quadTotal.select(
      'population_exposed_total'
    ),

    {
      min: 0,
      max: 100
    },

    'Population exposed TOTAL ' +
    PERIOD,

    false

  );


  Map.addLayer(

    quadFemale.select(
      'population_exposed_female'
    ),

    {
      min: 0,
      max: 50
    },

    'Population exposed FEMALE ' +
    PERIOD,

    false

  );


  Map.addLayer(

    quadMale.select(
      'population_exposed_male'
    ),

    {
      min: 0,
      max: 50
    },

    'Population exposed MALE ' +
    PERIOD,

    false

  );

}


// ============================================================
// 20. FINAL EXECUTION SUMMARY
// ============================================================

var EXPECTED_TASKS =
  (EXPORT_ANNUAL_STATS ? 1 : 0) +
  (EXPORT_QUAD_ASSET ? 1 : 0);


print(
  '========================================'
);


print(
  'PROCESSING CONFIGURATION'
);


print(
  'Period:',
  PERIOD
);


print(
  'Annual CSV export:',
  EXPORT_ANNUAL_STATS
);


print(
  'Annual CSV:',
  ANNUAL_STATS_NAME
);


print(
  'Quadrennial Asset export:',
  EXPORT_QUAD_ASSET
);


print(
  'Quadrennial Asset:',
  QUAD_OUTPUT_NAME
);


print(
  'Expected Tasks:',
  EXPECTED_TASKS
);


print(
  'Expected grid:',
  POP_DIMENSIONS
);


print(
  '========================================'
);
