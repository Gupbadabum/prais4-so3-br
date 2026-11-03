// ============================================================
// PRAIS4 / SO3.2
// MUNICIPAL EXPOSURE - IBGE 2025
//
// Cemaden-derived analytical product.
//
// Municipal reference:
//   IBGE/MUNICIPIOS/V2025
//
// Population groups:
//   - Total
//   - Female
//   - Male
//
// Methodological notes:
//
//   - Official PRAIS spatial products remain raster-based.
//
//   - This municipal product is a Cemaden-derived aggregation.
//
//   - Historical exposure rasters are aggregated to the
//     current IBGE 2025 municipal mesh.
//
//   - Total is an independent population product.
//
//   - Female + Male is NOT used to construct Total.
//
//   - Population reference corresponds to the mean population
//     across the year(s) tied for the worst drought class
//     within the quadrennium.
//
//   - Drought classes exposed:
//       1 = Extreme
//       2 = Severe
//       3 = Moderate
//       4 = Weak
//
//   - Class 5 = Normal.
//
//   - Absence of drought coverage is NOT interpreted as:
//       * normal drought;
//       * zero exposure;
//       * zero population.
//
//   - No annual exposure Asset is required.
//
//   - No raster is exported by this script.
//
// Main output:
//
//   One CSV in long format:
//
//     municipality x sex
//
// Expected rows:
//
//   5571 municipalities/equivalent units x 3 groups
//   = 16713 records.
// ============================================================


// ============================================================
// 0. PERIOD CONFIGURATION
// ============================================================

var YEARS_JS = [
  2016,
  2017,
  2018,
  2019
];


// ------------------------------------------------------------
// Require exactly four consecutive analytical years
// ------------------------------------------------------------

if (YEARS_JS.length !== 4) {
  throw new Error(
    'Expected exactly 4 analytical years. Received: ' +
    YEARS_JS.length
  );
}


for (var i = 1; i < YEARS_JS.length; i++) {

  if (YEARS_JS[i] !== YEARS_JS[i - 1] + 1) {

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


var YEARS_EE =
  ee.List(
    YEARS_JS
  );


// ============================================================
// 1. EXPORT CONTROLS
// ============================================================

// Main permanent output.
var EXPORT_MUNICIPAL_CSV =
  true;


// Optional Earth Engine FeatureCollection Asset.
//
// Disabled by default because the permanent municipal
// deliverable is the CSV.
var EXPORT_MUNICIPAL_ASSET =
  true;


// ============================================================
// 2. ASSETS AND OUTPUT NAMES
// ============================================================

var ASSET_ROOT =
  'projects/cursoqueimadas-503722/assets/';


// ------------------------------------------------------------
// Drought
// ------------------------------------------------------------

var DROUGHT_ASSET =
  ASSET_ROOT +
  'drought_spei12_dec';


// ------------------------------------------------------------
// Population
// ------------------------------------------------------------

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
// Validated integrated quadrennial master
// ------------------------------------------------------------

var QUAD_ASSET =
  ASSET_ROOT +
  'SO32_exposure_quadrennial_' +
  PERIOD_ID;


// ------------------------------------------------------------
// Municipal reference mesh
// ------------------------------------------------------------

var MUNICIPAL_ASSET =
  'IBGE/MUNICIPIOS/V2025';


// ------------------------------------------------------------
// Output
// ------------------------------------------------------------

var MUNICIPAL_OUTPUT_NAME =
  'SO32_municipal_exposure_' +
  PERIOD_ID +
  '_ibge2025';


var MUNICIPAL_OUTPUT_ASSET =
  ASSET_ROOT +
  MUNICIPAL_OUTPUT_NAME;


var OUTPUT_FOLDER =
  'PRAIS4_SO3';


// ============================================================
// 3. EXACT WORLDPOP GRID
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


var quad =
  ee.Image(
    QUAD_ASSET
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

function getDrought(year) {

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
// Population is selected by ANALYTICAL YEAR.
//
// For 2021-2023:
//
//   analytical year = 2021 / 2022 / 2023
//   source_year     = 2020
// ------------------------------------------------------------

function getPopulation(
  populationCollection,
  year
) {

  year =
    ee.Number(
      year
    );


  var sourceYear =
    year
      .min(2020)
      .toInt();


  return ee.Image(

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
  )
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
// Expected WorldPop provenance
// ------------------------------------------------------------

function expectedPopulationSourceYear(year) {

  return year <= 2020
    ? year
    : 2020;

}


// ------------------------------------------------------------
// Null-safe numeric property from reduceRegions()
//
// Zero is used only as an intermediate computational value.
//
// Final analytical semantics distinguish valid zero from
// absence of drought coverage using hazard_support.
// ------------------------------------------------------------

function featureNumberOrZero(
  feature,
  property
) {

  var value =
    feature.get(
      property
    );


  return ee.Number(

    ee.Algorithms.If(

      ee.Algorithms.IsEqual(
        value,
        null
      ),

      0,

      value

    )

  );

}


// ============================================================
// 7. LIGHT INPUT QA
// ============================================================

print(
  '========================================'
);


print(
  '05 - MUNICIPAL EXPOSURE - IBGE 2025'
);


print(
  'Period:',
  PERIOD
);


print(
  'Quadrennial master:',
  QUAD_ASSET
);


print(
  'Output:',
  MUNICIPAL_OUTPUT_NAME
);


print(
  '========================================'
);


// ------------------------------------------------------------
// Quadrennial master
// ------------------------------------------------------------

print(
  'Quadrennial master bands:',
  quad.bandNames()
);


// ------------------------------------------------------------
// Drought
// ------------------------------------------------------------

var droughtPeriodInput =
  drought.filter(
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
      group.collection.filter(
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
// 8. QUADRENNIAL DROUGHT AND SUPPORT
// ============================================================

var worstDrought =
  quad.select(
    'worst_drought_class'
  );


// ------------------------------------------------------------
// Drought spatial support
//
// 1 = valid worst-drought information
// 0 = no valid drought information
//
// Used to distinguish:
//
//   valid zero
//
// from
//
//   absence of drought coverage.
// ------------------------------------------------------------

var hazardSupport =
  worstDrought
    .mask()
    .rename(
      'hazard_support'
    )
    .unmask(0)
    .toByte();


// ============================================================
// 9. IBGE MUNICIPAL MESH 2025
// ============================================================

var municipalUnitsAll =
  ee.FeatureCollection(
    MUNICIPAL_ASSET
  );


// ------------------------------------------------------------
// Operational water-body units excluded from municipal output:
//
//   4300001 = Área Operacional "Lagoa Mirim"
//   4300002 = Área Operacional "Lagoa dos Patos"
// ------------------------------------------------------------

var waterUnits =
  municipalUnitsAll.filter(
    ee.Filter.inList(
      'CD_MUN',
      [
        '4300001',
        '4300002'
      ]
    )
  );


var municipalities =
  municipalUnitsAll

    .filter(
      ee.Filter.neq(
        'CD_MUN',
        '4300001'
      )
    )

    .filter(
      ee.Filter.neq(
        'CD_MUN',
        '4300002'
      )
    );


// ------------------------------------------------------------
// Municipal mesh QA
// ------------------------------------------------------------

print(
  'IBGE 2025 - all spatial units:',
  municipalUnitsAll.size()
);


print(
  'Operational water units:',
  waterUnits.size()
);


print(
  'Water unit codes:',
  waterUnits.aggregate_array(
    'CD_MUN'
  )
);


print(
  'Municipal/equivalent units retained:',
  municipalities.size()
);


print(
  'Expected retained units:',
  5571
);


print(
  'Boa Esperança do Norte units:',
  municipalities
    .filter(
      ee.Filter.eq(
        'NM_MUN',
        'Boa Esperança do Norte'
      )
    )
    .size()
);


// ============================================================
// 10. RECONSTRUCT QUADRENNIAL POPULATION REFERENCE
// ============================================================
//
// Temporal rule:
//
//   1. Determine the worst valid drought class in the period.
//
//   2. For each analytical year, retain population where that
//      year's drought class equals the worst class.
//
//   3. If several years tie for the worst drought class,
//      calculate the mean population across those critical
//      years.
//
// Reconstructed independently for:
//
//   - Total
//   - Female
//   - Male
// ============================================================

function buildPopulationReference(
  populationCollection,
  sex
) {

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


          // worstDrought is intentionally the first operand.
          //
          // This keeps the comparison anchored to the
          // WorldPop target grid used by the master product.
          var critical =
            worstDrought.eq(
              droughtYear
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


  return criticalPopulationCollection

    .mean()

    .rename(
      'population_reference_' +
      sex
    );

}


// ------------------------------------------------------------
// Independent population-reference surfaces
// ------------------------------------------------------------

var populationReferenceTotal =
  buildPopulationReference(
    populationTotal,
    'total'
  );


var populationReferenceFemale =
  buildPopulationReference(
    populationFemale,
    'female'
  );


var populationReferenceMale =
  buildPopulationReference(
    populationMale,
    'male'
  );


// ============================================================
// 11. BUILD MUNICIPAL BANDS FOR ONE POPULATION GROUP
// ============================================================
//
// Seven bands per population group:
//
//   population_reference
//   population_exposed
//   population_class_1
//   population_class_2
//   population_class_3
//   population_class_4
//   population_class_5
//
// population_exposed is taken directly from the validated
// quadrennial master.
//
// Class-specific population is reconstructed using the common
// population-reference surface and worst drought class.
// ============================================================

function buildMunicipalBands(
  populationReference,
  sex
) {

  var populationExposed =
    quad
      .select(
        'population_exposed_' +
        sex
      )
      .rename(
        'population_exposed_' +
        sex
      );


  var class1 =
    populationReference
      .updateMask(
        worstDrought.eq(1)
      )
      .rename(
        'population_class_1_' +
        sex
      );


  var class2 =
    populationReference
      .updateMask(
        worstDrought.eq(2)
      )
      .rename(
        'population_class_2_' +
        sex
      );


  var class3 =
    populationReference
      .updateMask(
        worstDrought.eq(3)
      )
      .rename(
        'population_class_3_' +
        sex
      );


  var class4 =
    populationReference
      .updateMask(
        worstDrought.eq(4)
      )
      .rename(
        'population_class_4_' +
        sex
      );


  var class5 =
    populationReference
      .updateMask(
        worstDrought.eq(5)
      )
      .rename(
        'population_class_5_' +
        sex
      );


  return ee.Image.cat([

    populationReference,

    populationExposed,

    class1,
    class2,
    class3,
    class4,
    class5

  ]);

}


// ============================================================
// 12. INTEGRATED MUNICIPAL REDUCTION STACK
// ============================================================
//
// 7 bands x 3 population groups
// +
// 1 drought-support band
//
// = 22 bands.
//
// unmask(0) is used ONLY for zonal reduction.
//
// Final analytical semantics are restored after reduction using
// hazard_support.
// ============================================================

var municipalBandsTotal =
  buildMunicipalBands(
    populationReferenceTotal,
    'total'
  );


var municipalBandsFemale =
  buildMunicipalBands(
    populationReferenceFemale,
    'female'
  );


var municipalBandsMale =
  buildMunicipalBands(
    populationReferenceMale,
    'male'
  );


var municipalStack =
  ee.Image.cat([

    municipalBandsTotal,

    municipalBandsFemale,

    municipalBandsMale,

    hazardSupport

  ])
  .unmask(0);


// ------------------------------------------------------------
// Structural QA
// ------------------------------------------------------------

print(
  'Municipal reduction bands:',
  municipalStack.bandNames()
);


print(
  'Expected municipal reduction bands:',
  22
);


// ============================================================
// 13. ADD MUNICIPAL INDICATORS FOR ONE POPULATION GROUP
// ============================================================
//
// IMPORTANT:
//
// Preserve the original Feature produced by reduceRegions().
//
// New attributes are added with feature.set({...}).
// ============================================================

function addMunicipalIndicators(
  feature,
  sex
) {

  var total =
    featureNumberOrZero(
      feature,
      'population_reference_' +
      sex
    );


  var exposed =
    featureNumberOrZero(
      feature,
      'population_exposed_' +
      sex
    );


  var c1 =
    featureNumberOrZero(
      feature,
      'population_class_1_' +
      sex
    );


  var c2 =
    featureNumberOrZero(
      feature,
      'population_class_2_' +
      sex
    );


  var c3 =
    featureNumberOrZero(
      feature,
      'population_class_3_' +
      sex
    );


  var c4 =
    featureNumberOrZero(
      feature,
      'population_class_4_' +
      sex
    );


  var c5 =
    featureNumberOrZero(
      feature,
      'population_class_5_' +
      sex
    );


  // ----------------------------------------------------------
  // Drought support
  //
  // hazard_support is binary at pixel level and reduced by SUM.
  //
  // > 0 = at least one valid drought pixel
  // = 0 = no valid drought coverage
  // ----------------------------------------------------------

  var hazardSupportValue =
    featureNumberOrZero(
      feature,
      'hazard_support'
    );


  var hasHazardSupport =
    hazardSupportValue.gt(0);


  var hasPopulation =
    total.gt(0);


  var validPercentage =
    hasHazardSupport
      .and(
        hasPopulation
      );


  // ----------------------------------------------------------
  // Percentage helper
  //
  // No drought support or no positive denominator -> null.
  // ----------------------------------------------------------

  function percentage(value) {

    return ee.Algorithms.If(

      validPercentage,

      value
        .divide(
          total
        )
        .multiply(100),

      null

    );

  }


  // ----------------------------------------------------------
  // Analytical-value helper
  //
  // No drought coverage -> null.
  // ----------------------------------------------------------

  function valueOrNull(value) {

    return ee.Algorithms.If(

      hasHazardSupport,

      value,

      null

    );

  }


  // ----------------------------------------------------------
  // QA balances
  // ----------------------------------------------------------

  var classSum =
    c1
      .add(c2)
      .add(c3)
      .add(c4)
      .add(c5);


  var exposedClassSum =
    c1
      .add(c2)
      .add(c3)
      .add(c4);


  var classBalance =
    total.subtract(
      classSum
    );


  var exposureBalance =
    exposed.subtract(
      exposedClassSum
    );


  // ----------------------------------------------------------
  // Preserve original reduceRegions Feature
  // ----------------------------------------------------------

  return feature.set({

    // --------------------------------------------------------
    // Product metadata
    // --------------------------------------------------------

    period:
      PERIOD,

    year_start:
      YEAR_START,

    year_end:
      YEAR_END,

    sex:
      sex,

    municipal_mesh:
      MUNICIPAL_ASSET,

    municipal_mesh_year:
      2025,

    territorial_interpretation:
      'historical_raster_aggregated_to_2025_mesh',

    population_reference_rule:
      'mean_of_critical_years',

    percentage_denominator:
      'population_reference',

    drought_classes_exposed:
      '1-4',


    // --------------------------------------------------------
    // Analysis support
    // --------------------------------------------------------

    hazard_support_available:
      ee.Number(
        ee.Algorithms.If(
          hasHazardSupport,
          1,
          0
        )
      ),

    analysis_status:
      ee.String(
        ee.Algorithms.If(
          hasHazardSupport,
          'valid',
          'no_drought_coverage'
        )
      ),


    // --------------------------------------------------------
    // Population reference
    // --------------------------------------------------------

    population_reference:
      valueOrNull(
        total
      ),

    population_reference_positive:
      ee.Algorithms.If(

        hasHazardSupport,

        ee.Number(
          ee.Algorithms.If(
            hasPopulation,
            1,
            0
          )
        ),

        null

      ),


    // --------------------------------------------------------
    // Drought class 1 - Extreme
    // --------------------------------------------------------

    population_class_1:
      valueOrNull(
        c1
      ),

    pct_class_1_extreme:
      percentage(
        c1
      ),


    // --------------------------------------------------------
    // Drought class 2 - Severe
    // --------------------------------------------------------

    population_class_2:
      valueOrNull(
        c2
      ),

    pct_class_2_severe:
      percentage(
        c2
      ),


    // --------------------------------------------------------
    // Drought class 3 - Moderate
    // --------------------------------------------------------

    population_class_3:
      valueOrNull(
        c3
      ),

    pct_class_3_moderate:
      percentage(
        c3
      ),


    // --------------------------------------------------------
    // Drought class 4 - Weak
    // --------------------------------------------------------

    population_class_4:
      valueOrNull(
        c4
      ),

    pct_class_4_weak:
      percentage(
        c4
      ),


    // --------------------------------------------------------
    // Drought class 5 - Normal
    // --------------------------------------------------------

    population_class_5:
      valueOrNull(
        c5
      ),

    pct_class_5_normal:
      percentage(
        c5
      ),


    // --------------------------------------------------------
    // Exposure
    // --------------------------------------------------------

    population_exposed:
      valueOrNull(
        exposed
      ),

    exposed_pct_reference:
      percentage(
        exposed
      ),


    // --------------------------------------------------------
    // QA
    // --------------------------------------------------------

    class_balance:
      valueOrNull(
        classBalance
      ),

    class_balance_abs:
      valueOrNull(
        classBalance.abs()
      ),

    exposure_balance:
      valueOrNull(
        exposureBalance
      ),

    exposure_balance_abs:
      valueOrNull(
        exposureBalance.abs()
      )

  });

}


// ============================================================
// 14. NATIONAL MUNICIPAL REDUCTION
// ============================================================
//
// This object is intentionally not evaluated with print().
//
// The full national computation is executed through the export
// Task rather than through the interactive Console.
// ============================================================

var municipalRaw =
  municipalStack.reduceRegions({

    collection:
      municipalities,

    reducer:
      ee.Reducer.sum(),

    crs:
      POP_CRS,

    crsTransform:
      POP_TRANSFORM,

    tileScale:
      4,

    maxPixelsPerRegion:
      1e9

  });


// ============================================================
// 15. CONVERT TO LONG FORMAT
// ============================================================

var municipalTotal =
  municipalRaw.map(
    function(feature) {

      return addMunicipalIndicators(
        feature,
        'total'
      );

    }
  );


var municipalFemale =
  municipalRaw.map(
    function(feature) {

      return addMunicipalIndicators(
        feature,
        'female'
      );

    }
  );


var municipalMale =
  municipalRaw.map(
    function(feature) {

      return addMunicipalIndicators(
        feature,
        'male'
      );

    }
  );


var municipalExposure =
  municipalTotal
    .merge(
      municipalFemale
    )
    .merge(
      municipalMale
    );


// ============================================================
// 16. CSV FIELDS
// ============================================================

var CSV_FIELDS = [

  // ----------------------------------------------------------
  // Territorial identification
  // ----------------------------------------------------------

  'CD_MUN',
  'NM_MUN',

  'CD_UF',
  'NM_UF',
  'SIGLA_UF',

  'CD_REGIAO',
  'NM_REGIAO',
  'SIGLA_RG',

  'CD_RGI',
  'NM_RGI',

  'CD_RGINT',
  'NM_RGINT',

  'AREA_KM2',


  // ----------------------------------------------------------
  // Product metadata
  // ----------------------------------------------------------

  'period',
  'year_start',
  'year_end',

  'sex',

  'municipal_mesh',
  'municipal_mesh_year',

  'territorial_interpretation',

  'population_reference_rule',

  'percentage_denominator',

  'drought_classes_exposed',


  // ----------------------------------------------------------
  // Analysis support
  // ----------------------------------------------------------

  'analysis_status',
  'hazard_support_available',


  // ----------------------------------------------------------
  // Population reference
  // ----------------------------------------------------------

  'population_reference',
  'population_reference_positive',


  // ----------------------------------------------------------
  // Class 1
  // ----------------------------------------------------------

  'population_class_1',
  'pct_class_1_extreme',


  // ----------------------------------------------------------
  // Class 2
  // ----------------------------------------------------------

  'population_class_2',
  'pct_class_2_severe',


  // ----------------------------------------------------------
  // Class 3
  // ----------------------------------------------------------

  'population_class_3',
  'pct_class_3_moderate',


  // ----------------------------------------------------------
  // Class 4
  // ----------------------------------------------------------

  'population_class_4',
  'pct_class_4_weak',


  // ----------------------------------------------------------
  // Class 5
  // ----------------------------------------------------------

  'population_class_5',
  'pct_class_5_normal',


  // ----------------------------------------------------------
  // Exposure
  // ----------------------------------------------------------

  'population_exposed',
  'exposed_pct_reference',


  // ----------------------------------------------------------
  // QA
  // ----------------------------------------------------------

  'class_balance',
  'class_balance_abs',

  'exposure_balance',
  'exposure_balance_abs'

];


// ============================================================
// 17. CSV WITHOUT GEOMETRY
// ============================================================
//
// Do not evaluate municipalCSV.size() interactively.
//
// Final row-count and consistency checks are performed on the
// exported CSV.
// ============================================================

var municipalCSV =
  municipalExposure.select({

    propertySelectors:
      CSV_FIELDS,

    retainGeometry:
      false

  });


// ============================================================
// 18. EXPORT CSV
// ============================================================

if (EXPORT_MUNICIPAL_CSV) {

  Export.table.toDrive({

    collection:
      municipalCSV,

    description:
      MUNICIPAL_OUTPUT_NAME,

    folder:
      OUTPUT_FOLDER,

    fileNamePrefix:
      MUNICIPAL_OUTPUT_NAME,

    fileFormat:
      'CSV',

    selectors:
      CSV_FIELDS

  });

}


// ============================================================
// 19. OPTIONAL FEATURECOLLECTION ASSET
// ============================================================

if (EXPORT_MUNICIPAL_ASSET) {

  Export.table.toAsset({

    collection:
      municipalExposure,

    description:
      MUNICIPAL_OUTPUT_NAME,

    assetId:
      MUNICIPAL_OUTPUT_ASSET

  });

}


// ============================================================
// 20. OPERATIONAL SUMMARY
// ============================================================
//
// These values are configuration-derived and do not force the
// national reduceRegions() to execute in the Console.
// ============================================================

var EXPECTED_MUNICIPALITIES =
  5571;


var EXPECTED_ROWS =
  EXPECTED_MUNICIPALITIES *
  POPULATION_GROUPS.length;


var EXPECTED_TASKS =
  (EXPORT_MUNICIPAL_CSV ? 1 : 0) +
  (EXPORT_MUNICIPAL_ASSET ? 1 : 0);


print(
  '========================================'
);


print(
  'MUNICIPAL PROCESSING CONFIGURATION'
);


print(
  'Period:',
  PERIOD
);


print(
  'Municipal mesh:',
  MUNICIPAL_ASSET
);


print(
  'Expected municipalities/equivalent units:',
  EXPECTED_MUNICIPALITIES
);


print(
  'Population groups:',
  POPULATION_GROUPS.length
);


print(
  'Expected CSV rows:',
  EXPECTED_ROWS
);


print(
  'CSV fields:',
  CSV_FIELDS.length
);


print(
  'CSV output:',
  MUNICIPAL_OUTPUT_NAME
);


print(
  'CSV export:',
  EXPORT_MUNICIPAL_CSV
);


print(
  'FeatureCollection Asset export:',
  EXPORT_MUNICIPAL_ASSET
);


print(
  'Expected Tasks:',
  EXPECTED_TASKS
);


print(
  'No raster export is created by Script 05.'
);


print(
  '========================================'
);
