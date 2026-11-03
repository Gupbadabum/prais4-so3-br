// ============================================================
// PRAIS4 / SO3.2
// QUADRENNIAL QA/QC
//
// Purpose:
//
//   Validate the integrated quadrennial master raster.
//
// Checks:
//
//   1. Exact WorldPop grid and expected band structure;
//   2. Categorical-band ranges;
//   3. Internal consistency among Total / Female / Male;
//   4. Female + Male versus independent Total population;
//   5. Regression against the previously validated TOTAL
//      product for 2000-2003.
//
// Output:
//
//   One small QA CSV.
//
// No raster is exported.
// No new EE Asset is created.
// ============================================================


// ============================================================
// 0. PERIOD CONFIGURATION
// ============================================================
//
// This is the main block to change between quadrennia.
// ============================================================

var YEARS_JS = [
  2016,
  2017,
  2018,
  2019
];


// ------------------------------------------------------------
// Exactly four consecutive analytical years
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
// Period identifiers
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


// ============================================================
// 1. QA / EXPORT CONTROLS
// ============================================================

var EXPORT_QA_CSV =
  true;


// Heavy raster reductions should normally run only through
// the batch export Task.
//
// Set TRUE only when explicitly needed for inspection.
var PRINT_QA_FEATURE =
  false;


var SHOW_MAP =
  false;


// ------------------------------------------------------------
// Historical regression reference
//
// The previous validated TOTAL product exists only for the
// first quadrennium.
//
// Therefore this regression activates automatically only for
// 2000-2003.
// ------------------------------------------------------------

var RUN_REFERENCE_REGRESSION =
  YEAR_START === 2000 &&
  YEAR_END === 2003;


// ============================================================
// 2. ASSETS
// ============================================================

var ASSET_ROOT =
  'projects/cursoqueimadas-503722/assets/';


// ------------------------------------------------------------
// New integrated master raster
// ------------------------------------------------------------

var QUAD_ASSET =
  ASSET_ROOT +
  'SO32_exposure_quadrennial_' +
  PERIOD_ID;


// ------------------------------------------------------------
// Historical validated TOTAL reference
//
// This name intentionally retains "_aligned" because it is a
// historical reference Asset.
//
// New canonical outputs do NOT use "_aligned".
// ------------------------------------------------------------

var REFERENCE_ASSET =
  ASSET_ROOT +
  'exposure_quadrennial_2000_2003';


// ------------------------------------------------------------
// QA output
// ------------------------------------------------------------

var QA_NAME =
  'SO32_quadrennial_QA_' +
  PERIOD_ID;


var QA_FOLDER =
  'PRAIS4_SO3';


// ============================================================
// 3. EXPECTED WORLDPOP GRID
// ============================================================

var EXPECTED_WIDTH =
  54172;


var EXPECTED_HEIGHT =
  46814;


var EXPECTED_CRS =
  'EPSG:4326';


var EXPECTED_TRANSFORM = [
   0.0008333333300044304,
   0,
  -73.989583022,
   0,
  -0.0008333333300081173,
   5.264583514
];


var EXPECTED_DIMENSIONS =
  EXPECTED_WIDTH +
  'x' +
  EXPECTED_HEIGHT;


// ============================================================
// 4. EXPECTED MASTER BANDS
// ============================================================

var EXPECTED_BANDS = [

  'worst_drought_class',

  'hazard_valid_years',

  'hazard_missing_flag',

  'population_exposed_total',

  'critical_year_count_total',

  'population_exposed_female',

  'critical_year_count_female',

  'population_exposed_male',

  'critical_year_count_male'

];


// ============================================================
// 5. INPUT MASTER
// ============================================================

var quad =
  ee.Image(
    QUAD_ASSET
  );


// ------------------------------------------------------------
// Historical reference
// ------------------------------------------------------------

var reference =
  RUN_REFERENCE_REGRESSION

    ? ee.Image(
        REFERENCE_ASSET
      )

    : null;


// ============================================================
// 6. CLIENT-SIDE METADATA QA
// ============================================================
//
// getInfo() here reads Asset metadata only.
//
// It does NOT execute the national raster reductions below.
// ============================================================

var quadInfo =
  quad.getInfo();


var firstBandInfo =
  quadInfo.bands[0];


var actualDimensions =
  firstBandInfo.dimensions;


var actualCRS =
  firstBandInfo.crs;


var actualTransform =
  firstBandInfo.crs_transform;


var actualBands =
  quadInfo.bands.map(
    function(band) {

      return band.id;

    }
  );


// ------------------------------------------------------------
// Support functions for metadata comparison
// ------------------------------------------------------------

function sameTransform(
  a,
  b
) {

  if (
    a.length !==
    b.length
  ) {

    return false;

  }


  for (
    var i = 0;
    i < a.length;
    i++
  ) {

    if (
      Math.abs(
        a[i] -
        b[i]
      ) >
      1e-12
    ) {

      return false;

    }

  }


  return true;

}


function sameArray(
  a,
  b
) {

  if (
    a.length !==
    b.length
  ) {

    return false;

  }


  for (
    var i = 0;
    i < a.length;
    i++
  ) {

    if (
      a[i] !==
      b[i]
    ) {

      return false;

    }

  }


  return true;

}


// ------------------------------------------------------------
// Metadata QA flags
// ------------------------------------------------------------

var dimensionsOK =
  actualDimensions[0] === EXPECTED_WIDTH &&
  actualDimensions[1] === EXPECTED_HEIGHT;


var crsOK =
  actualCRS ===
  EXPECTED_CRS;


var transformOK =
  sameTransform(
    actualTransform,
    EXPECTED_TRANSFORM
  );


var bandsOK =
  sameArray(
    actualBands,
    EXPECTED_BANDS
  );


var gridOK =
  dimensionsOK &&
  crsOK &&
  transformOK;


// ============================================================
// 7. METADATA REPORT
// ============================================================

print(
  '========================================'
);


print(
  'SO3.2 QUADRENNIAL QA/QC'
);


print(
  'Period:',
  PERIOD
);


print(
  'Master Asset:',
  QUAD_ASSET
);


print(
  '========================================'
);


print(
  'Bands:',
  actualBands
);


print(
  'Expected bands:',
  EXPECTED_BANDS
);


print(
  'Bands OK:',
  bandsOK
);


print(
  'Dimensions:',
  actualDimensions
);


print(
  'Expected dimensions:',
  EXPECTED_DIMENSIONS
);


print(
  'Dimensions OK:',
  dimensionsOK
);


print(
  'CRS:',
  actualCRS
);


print(
  'CRS OK:',
  crsOK
);


print(
  'Transform:',
  actualTransform
);


print(
  'Transform OK:',
  transformOK
);


print(
  'GRID OK:',
  gridOK
);


print(
  'Historical reference regression:',
  RUN_REFERENCE_REGRESSION
);


// ============================================================
// 8. SUPPORT FUNCTIONS FOR RASTER QA
// ============================================================

// ------------------------------------------------------------
// Valid-data mask of one selected band
// ------------------------------------------------------------

function validMask(
  image
) {

  return image
    .mask()
    .unmask(0)
    .gt(0);

}


// ------------------------------------------------------------
// Count pixels whose masks differ
// ------------------------------------------------------------

function maskMismatch(
  imageA,
  imageB,
  outputName
) {

  var maskA =
    validMask(
      imageA
    );


  var maskB =
    validMask(
      imageB
    );


  return maskA
    .neq(
      maskB
    )
    .rename(
      outputName
    )
    .toByte();

}


// ------------------------------------------------------------
// Count pixels whose categorical values differ.
//
// Only pixels valid in BOTH images participate.
//
// Mask differences are measured separately.
// ------------------------------------------------------------

function categoricalMismatch(
  imageA,
  imageB,
  outputName
) {

  var commonMask =
    validMask(
      imageA
    )
    .and(
      validMask(
        imageB
      )
    );


  return imageA
    .neq(
      imageB
    )
    .updateMask(
      commonMask
    )
    .unmask(0)
    .rename(
      outputName
    )
    .toByte();

}


// ------------------------------------------------------------
// Absolute numerical difference.
//
// Only pixels valid in BOTH images participate.
// ------------------------------------------------------------

function absoluteDifference(
  imageA,
  imageB,
  outputName
) {

  var commonMask =
    validMask(
      imageA
    )
    .and(
      validMask(
        imageB
      )
    );


  return imageA
    .subtract(
      imageB
    )
    .abs()
    .updateMask(
      commonMask
    )
    .rename(
      outputName
    )
    .toFloat();

}


// ============================================================
// 9. MASTER BANDS
// ============================================================

var worstDrought =
  quad.select(
    'worst_drought_class'
  );


var hazardValidYears =
  quad.select(
    'hazard_valid_years'
  );


var hazardMissingFlag =
  quad.select(
    'hazard_missing_flag'
  );


var exposedTotal =
  quad.select(
    'population_exposed_total'
  );


var exposedFemale =
  quad.select(
    'population_exposed_female'
  );


var exposedMale =
  quad.select(
    'population_exposed_male'
  );


var criticalTotal =
  quad.select(
    'critical_year_count_total'
  );


var criticalFemale =
  quad.select(
    'critical_year_count_female'
  );


var criticalMale =
  quad.select(
    'critical_year_count_male'
  );


// ============================================================
// 10. GENERAL CATEGORICAL RANGE QA
// ============================================================
//
// Useful for every quadrennium, including those without a
// historical reference raster.
// ============================================================

var categoricalRangeImage =
  ee.Image.cat([

    worstDrought,

    hazardValidYears,

    hazardMissingFlag,

    criticalTotal,

    criticalFemale,

    criticalMale

  ]);


var rangeStats =
  categoricalRangeImage
    .reduceRegion({

      reducer:
        ee.Reducer.minMax(),

      geometry:
        worstDrought.geometry(),

      crs:
        EXPECTED_CRS,

      crsTransform:
        EXPECTED_TRANSFORM,

      maxPixels:
        5e10,

      tileScale:
        4

    });


// ============================================================
// 11. INTERNAL CONSISTENCY QA
// ============================================================
//
// Total remains independent.
//
// Female + Male is QA only.
// It NEVER constructs or replaces Total.
// ============================================================

var countBands = [

  // ----------------------------------------------------------
  // Critical-year-count support
  // ----------------------------------------------------------

  maskMismatch(
    criticalTotal,
    criticalFemale,
    'critical_mask_total_female'
  ),

  maskMismatch(
    criticalTotal,
    criticalMale,
    'critical_mask_total_male'
  ),


  // ----------------------------------------------------------
  // Critical-year-count values
  // ----------------------------------------------------------

  categoricalMismatch(
    criticalTotal,
    criticalFemale,
    'critical_value_total_female'
  ),

  categoricalMismatch(
    criticalTotal,
    criticalMale,
    'critical_value_total_male'
  ),


  // ----------------------------------------------------------
  // Exposed-population support
  // ----------------------------------------------------------

  maskMismatch(
    exposedTotal,
    exposedFemale,
    'exposed_mask_total_female'
  ),

  maskMismatch(
    exposedTotal,
    exposedMale,
    'exposed_mask_total_male'
  ),


  // ----------------------------------------------------------
  // Number of pixels with incomplete drought information
  // ----------------------------------------------------------

  hazardMissingFlag
    .rename(
      'hazard_missing_pixels'
    )
    .toByte()

];


// ============================================================
// 12. POPULATION SUM QA
// ============================================================

var populationBands = [

  exposedTotal
    .rename(
      'population_exposed_total'
    ),

  exposedFemale
    .rename(
      'population_exposed_female'
    ),

  exposedMale
    .rename(
      'population_exposed_male'
    )

];


// ============================================================
// 13. HISTORICAL REGRESSION: 2000-2003
// ============================================================
//
// Confirms that generalizing Script 03 from TOTAL-only to the
// integrated Total/Female/Male master did not change the
// previously validated TOTAL result.
// ============================================================

var referenceAbsDifference =
  null;


if (RUN_REFERENCE_REGRESSION) {


  var refWorstDrought =
    reference.select(
      'worst_drought_class'
    );


  var refHazardValidYears =
    reference.select(
      'hazard_valid_years'
    );


  var refHazardMissingFlag =
    reference.select(
      'hazard_missing_flag'
    );


  var refExposedTotal =
    reference.select(
      'population_exposed'
    );


  var refCriticalTotal =
    reference.select(
      'critical_year_count'
    );


  // ----------------------------------------------------------
  // Masks and categorical values
  // ----------------------------------------------------------

  countBands.push(

    maskMismatch(
      worstDrought,
      refWorstDrought,
      'reference_worst_mask'
    )

  );


  countBands.push(

    categoricalMismatch(
      worstDrought,
      refWorstDrought,
      'reference_worst_value'
    )

  );


  countBands.push(

    categoricalMismatch(
      hazardValidYears,
      refHazardValidYears,
      'reference_hazard_valid_value'
    )

  );


  countBands.push(

    categoricalMismatch(
      hazardMissingFlag,
      refHazardMissingFlag,
      'reference_hazard_missing_value'
    )

  );


  countBands.push(

    maskMismatch(
      criticalTotal,
      refCriticalTotal,
      'reference_critical_mask'
    )

  );


  countBands.push(

    categoricalMismatch(
      criticalTotal,
      refCriticalTotal,
      'reference_critical_value'
    )

  );


  countBands.push(

    maskMismatch(
      exposedTotal,
      refExposedTotal,
      'reference_exposed_mask'
    )

  );


  // ----------------------------------------------------------
  // Numerical exposed-population regression
  // ----------------------------------------------------------

  referenceAbsDifference =
    absoluteDifference(
      exposedTotal,
      refExposedTotal,
      'reference_exposed_abs_difference'
    );


  populationBands.push(

    refExposedTotal
      .rename(
        'reference_population_exposed_total'
      )

  );


  populationBands.push(
    referenceAbsDifference
  );

}


// ============================================================
// 14. COUNT / MISMATCH REDUCTION
// ============================================================
//
// Byte bands + unweighted SUM.
//
// Result = number of pixels satisfying each QA condition.
// ============================================================

var countImage =
  ee.Image.cat(
    countBands
  );


var countStats =
  countImage
    .reduceRegion({

      reducer:
        ee.Reducer
          .sum()
          .unweighted(),

      geometry:
        worstDrought.geometry(),

      crs:
        EXPECTED_CRS,

      crsTransform:
        EXPECTED_TRANSFORM,

      maxPixels:
        5e10,

      tileScale:
        4

    });


// ============================================================
// 15. POPULATION SUM REDUCTION
// ============================================================

var populationImage =
  ee.Image.cat(
    populationBands
  );


var populationStats =
  populationImage
    .reduceRegion({

      reducer:
        ee.Reducer.sum(),

      geometry:
        worstDrought.geometry(),

      crs:
        EXPECTED_CRS,

      crsTransform:
        EXPECTED_TRANSFORM,

      maxPixels:
        5e10,

      tileScale:
        4

    });


// ============================================================
// 16. MAXIMUM REFERENCE PIXEL DIFFERENCE
// ============================================================

var referenceMaxStats =
  RUN_REFERENCE_REGRESSION

    ? referenceAbsDifference
        .reduceRegion({

          reducer:
            ee.Reducer.max(),

          geometry:
            worstDrought.geometry(),

          crs:
            EXPECTED_CRS,

          crsTransform:
            EXPECTED_TRANSFORM,

          maxPixels:
            5e10,

          tileScale:
            4

        })

    : ee.Dictionary({});


// ============================================================
// 17. BUILD QA FEATURE
// ============================================================

var exposedTotalSum =
  ee.Number(
    populationStats.get(
      'population_exposed_total'
    )
  );


var exposedFemaleSum =
  ee.Number(
    populationStats.get(
      'population_exposed_female'
    )
  );


var exposedMaleSum =
  ee.Number(
    populationStats.get(
      'population_exposed_male'
    )
  );


var exposedFemaleMaleSum =
  exposedFemaleSum
    .add(
      exposedMaleSum
    );


var exposedFemaleMaleDifference =
  exposedFemaleMaleSum
    .subtract(
      exposedTotalSum
    );


var exposedFemaleMaleDifferencePct =
  exposedFemaleMaleDifference
    .divide(
      exposedTotalSum
    )
    .multiply(100);


// ------------------------------------------------------------
// Base QA record
// ------------------------------------------------------------

var qaFeature =
  ee.Feature(
    null,
    {

      period:
        PERIOD,

      year_start:
        YEAR_START,

      year_end:
        YEAR_END,

      master_asset:
        QUAD_ASSET,

      reference_regression_enabled:
        RUN_REFERENCE_REGRESSION,


      // ------------------------------------------------------
      // Static structure / grid QA
      // ------------------------------------------------------

      expected_band_count:
        EXPECTED_BANDS.length,

      actual_band_count:
        actualBands.length,

      bands_ok:
        bandsOK,

      expected_width:
        EXPECTED_WIDTH,

      expected_height:
        EXPECTED_HEIGHT,

      dimensions_ok:
        dimensionsOK,

      crs_ok:
        crsOK,

      transform_ok:
        transformOK,

      grid_ok:
        gridOK,


      // ------------------------------------------------------
      // Categorical ranges
      // ------------------------------------------------------

      worst_drought_class_min:
        rangeStats.get(
          'worst_drought_class_min'
        ),

      worst_drought_class_max:
        rangeStats.get(
          'worst_drought_class_max'
        ),

      hazard_valid_years_min:
        rangeStats.get(
          'hazard_valid_years_min'
        ),

      hazard_valid_years_max:
        rangeStats.get(
          'hazard_valid_years_max'
        ),

      hazard_missing_flag_min:
        rangeStats.get(
          'hazard_missing_flag_min'
        ),

      hazard_missing_flag_max:
        rangeStats.get(
          'hazard_missing_flag_max'
        ),

      critical_year_count_total_min:
        rangeStats.get(
          'critical_year_count_total_min'
        ),

      critical_year_count_total_max:
        rangeStats.get(
          'critical_year_count_total_max'
        ),

      critical_year_count_female_min:
        rangeStats.get(
          'critical_year_count_female_min'
        ),

      critical_year_count_female_max:
        rangeStats.get(
          'critical_year_count_female_max'
        ),

      critical_year_count_male_min:
        rangeStats.get(
          'critical_year_count_male_min'
        ),

      critical_year_count_male_max:
        rangeStats.get(
          'critical_year_count_male_max'
        ),


      // ------------------------------------------------------
      // Drought completeness
      // ------------------------------------------------------

      hazard_missing_pixels:
        countStats.get(
          'hazard_missing_pixels'
        ),


      // ------------------------------------------------------
      // Internal Total / Female / Male QA
      // ------------------------------------------------------

      critical_mask_total_female_mismatch_pixels:
        countStats.get(
          'critical_mask_total_female'
        ),

      critical_mask_total_male_mismatch_pixels:
        countStats.get(
          'critical_mask_total_male'
        ),

      critical_value_total_female_mismatch_pixels:
        countStats.get(
          'critical_value_total_female'
        ),

      critical_value_total_male_mismatch_pixels:
        countStats.get(
          'critical_value_total_male'
        ),

      exposed_mask_total_female_mismatch_pixels:
        countStats.get(
          'exposed_mask_total_female'
        ),

      exposed_mask_total_male_mismatch_pixels:
        countStats.get(
          'exposed_mask_total_male'
        ),


      // ------------------------------------------------------
      // Population sums
      // ------------------------------------------------------

      population_exposed_total:
        exposedTotalSum,

      population_exposed_female:
        exposedFemaleSum,

      population_exposed_male:
        exposedMaleSum,

      population_exposed_female_plus_male:
        exposedFemaleMaleSum,

      population_exposed_female_plus_male_minus_total:
        exposedFemaleMaleDifference,

      population_exposed_female_plus_male_minus_total_pct:
        exposedFemaleMaleDifferencePct

    }
  );


// ============================================================
// 18. ADD HISTORICAL REGRESSION RESULTS
// ============================================================

if (RUN_REFERENCE_REGRESSION) {


  var referenceExposedSum =
    ee.Number(
      populationStats.get(
        'reference_population_exposed_total'
      )
    );


  var referenceDifference =
    exposedTotalSum
      .subtract(
        referenceExposedSum
      );


  var referenceDifferencePct =
    referenceDifference
      .divide(
        referenceExposedSum
      )
      .multiply(100);


  qaFeature =
    qaFeature.set({

      reference_asset:
        REFERENCE_ASSET,


      // ------------------------------------------------------
      // Raster structure/value regression
      // ------------------------------------------------------

      reference_worst_mask_mismatch_pixels:
        countStats.get(
          'reference_worst_mask'
        ),

      reference_worst_value_mismatch_pixels:
        countStats.get(
          'reference_worst_value'
        ),

      reference_hazard_valid_value_mismatch_pixels:
        countStats.get(
          'reference_hazard_valid_value'
        ),

      reference_hazard_missing_value_mismatch_pixels:
        countStats.get(
          'reference_hazard_missing_value'
        ),

      reference_critical_mask_mismatch_pixels:
        countStats.get(
          'reference_critical_mask'
        ),

      reference_critical_value_mismatch_pixels:
        countStats.get(
          'reference_critical_value'
        ),

      reference_exposed_mask_mismatch_pixels:
        countStats.get(
          'reference_exposed_mask'
        ),


      // ------------------------------------------------------
      // Population regression
      // ------------------------------------------------------

      reference_population_exposed_total:
        referenceExposedSum,

      reference_population_exposed_difference:
        referenceDifference,

      reference_population_exposed_difference_pct:
        referenceDifferencePct,

      reference_population_exposed_sum_abs_difference:
        populationStats.get(
          'reference_exposed_abs_difference'
        ),

      reference_population_exposed_max_abs_pixel_difference:
        referenceMaxStats.get(
          'reference_exposed_abs_difference'
        )

    });

}


// ============================================================
// 19. QA FEATURE COLLECTION
// ============================================================

var qaTable =
  ee.FeatureCollection([
    qaFeature
  ]);


// ------------------------------------------------------------
// Avoid synchronous heavy raster execution by default.
// ------------------------------------------------------------

if (PRINT_QA_FEATURE) {

  print(
    'QA result:',
    qaFeature
  );

}


// ============================================================
// 20. EXPORT QA CSV
// ============================================================

var QA_SELECTORS = [

  'period',
  'year_start',
  'year_end',

  'master_asset',
  'reference_regression_enabled',

  'expected_band_count',
  'actual_band_count',
  'bands_ok',

  'expected_width',
  'expected_height',

  'dimensions_ok',
  'crs_ok',
  'transform_ok',
  'grid_ok',

  'worst_drought_class_min',
  'worst_drought_class_max',

  'hazard_valid_years_min',
  'hazard_valid_years_max',

  'hazard_missing_flag_min',
  'hazard_missing_flag_max',

  'critical_year_count_total_min',
  'critical_year_count_total_max',

  'critical_year_count_female_min',
  'critical_year_count_female_max',

  'critical_year_count_male_min',
  'critical_year_count_male_max',

  'hazard_missing_pixels',

  'critical_mask_total_female_mismatch_pixels',
  'critical_mask_total_male_mismatch_pixels',

  'critical_value_total_female_mismatch_pixels',
  'critical_value_total_male_mismatch_pixels',

  'exposed_mask_total_female_mismatch_pixels',
  'exposed_mask_total_male_mismatch_pixels',

  'population_exposed_total',
  'population_exposed_female',
  'population_exposed_male',

  'population_exposed_female_plus_male',

  'population_exposed_female_plus_male_minus_total',

  'population_exposed_female_plus_male_minus_total_pct'

];


// ------------------------------------------------------------
// Reference-only fields.
//
// These are added only for 2000-2003.
// ------------------------------------------------------------

if (RUN_REFERENCE_REGRESSION) {

  QA_SELECTORS =
    QA_SELECTORS.concat([

      'reference_asset',

      'reference_worst_mask_mismatch_pixels',
      'reference_worst_value_mismatch_pixels',

      'reference_hazard_valid_value_mismatch_pixels',
      'reference_hazard_missing_value_mismatch_pixels',

      'reference_critical_mask_mismatch_pixels',
      'reference_critical_value_mismatch_pixels',

      'reference_exposed_mask_mismatch_pixels',

      'reference_population_exposed_total',

      'reference_population_exposed_difference',
      'reference_population_exposed_difference_pct',

      'reference_population_exposed_sum_abs_difference',

      'reference_population_exposed_max_abs_pixel_difference'

    ]);

}


if (EXPORT_QA_CSV) {

  Export.table.toDrive({

    collection:
      qaTable,

    description:
      QA_NAME,

    folder:
      QA_FOLDER,

    fileNamePrefix:
      QA_NAME,

    fileFormat:
      'CSV',

    selectors:
      QA_SELECTORS

  });

}


// ============================================================
// 21. OPTIONAL VISUAL CHECK
// ============================================================

if (SHOW_MAP) {

  Map.centerObject(
    quad,
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

    exposedTotal,

    {
      min: 0,
      max: 100
    },

    'Population exposed TOTAL ' +
    PERIOD,

    false

  );

}


// ============================================================
// 22. FINAL SUMMARY
// ============================================================

print(
  '========================================'
);


print(
  'QA CONFIGURATION'
);


print(
  'Period:',
  PERIOD
);


print(
  'Master Asset:',
  QUAD_ASSET
);


print(
  'Reference regression:',
  RUN_REFERENCE_REGRESSION
);


if (RUN_REFERENCE_REGRESSION) {

  print(
    'Reference Asset:',
    REFERENCE_ASSET
  );

}


print(
  'QA CSV:',
  QA_NAME
);


print(
  'QA CSV export:',
  EXPORT_QA_CSV
);


print(
  'Expected Tasks:',
  EXPORT_QA_CSV ? 1 : 0
);


print(
  'No raster export is created by Script 04.'
);


print(
  '========================================'
);
