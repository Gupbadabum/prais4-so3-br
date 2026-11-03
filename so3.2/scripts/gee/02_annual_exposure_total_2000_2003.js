// ============================================================
// PRAIS4 / SO3.2
// ANNUAL POPULATION EXPOSURE TO DROUGHT
// Period: 2000-2003
//
// Population groups:
//   - Total
//   - Female
//   - Male
//
// ALIGNED VERSION
//
// Exact WorldPop target grid:
//   54172 x 46814 pixels
//
// Total, Female and Male use the same exposure methodology.
// Each population group remains an independent product.
// ============================================================


// ============================================================
// 0. CONFIGURATION
// ============================================================

var YEARS_JS = [
  2000,
  2001,
  2002,
  2003
];

var YEARS_EE = ee.List(
  YEARS_JS
);


// ------------------------------------------------------------
// QA controls
//
// Annual Total QA has already been validated.
//
// Keep FALSE during production export to avoid unnecessary
// recalculation of large rasters.
// ------------------------------------------------------------

var RUN_QA = true;

var EXPORT_QA_CSV = true;


// ------------------------------------------------------------
// Inputs
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
// Output collections
// ------------------------------------------------------------

var EXPOSURE_TOTAL_OUTPUT =
  'projects/cursoqueimadas-503722/assets/' +
  'exposure_total_annual';


var EXPOSURE_FEMALE_OUTPUT =
  'projects/cursoqueimadas-503722/assets/' +
  'exposure_female_annual';


var EXPOSURE_MALE_OUTPUT =
  'projects/cursoqueimadas-503722/assets/' +
  'exposure_male_annual';


// ============================================================
// 1. EXACT WORLDPOP GRID
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
  POP_WIDTH + 'x' + POP_HEIGHT;


// ============================================================
// 2. INPUT COLLECTIONS
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


// ------------------------------------------------------------
// Population-group configuration
//
// export:
//   false = product already exists / do not recreate
//   true  = create annual export tasks
// ------------------------------------------------------------

var POPULATION_GROUPS = [

  {
    sex:
      'total',

    collection:
      populationTotal,

    output:
      EXPOSURE_TOTAL_OUTPUT,

    export:
      true
  },

  {
    sex:
      'female',

    collection:
      populationFemale,

    output:
      EXPOSURE_FEMALE_OUTPUT,

    export:
      true
  },

  {
    sex:
      'male',

    collection:
      populationMale,

    output:
      EXPOSURE_MALE_OUTPUT,

    export:
      true
  }

];


// ============================================================
// 3. BASIC INPUT CHECKS
// ============================================================

print(
  'Drought images 2000-2003:',
  drought
    .filter(
      ee.Filter.inList(
        'year',
        YEARS_EE
      )
    )
    .size()
);


POPULATION_GROUPS.forEach(
  function(group) {

    print(
      'Population ' +
      group.sex +
      ' images 2000-2003:',

      group.collection
        .filter(
          ee.Filter.inList(
            'year',
            YEARS_EE
          )
        )
        .size()
    );

  }
);


print(
  'Target dimensions:',
  POP_DIMENSIONS
);


print(
  'Target transform:',
  POP_TRANSFORM
);


// ============================================================
// 4. SUPPORT FUNCTIONS
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


function getPopulation(
  populationCollection,
  year
) {

  return ee.Image(
    populationCollection
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


function statOrZero(
  stats,
  key
) {

  return ee.Number(
    ee.Algorithms.If(
      stats.get(key),
      stats.get(key),
      0
    )
  );

}


// ============================================================
// 5. BUILD ANNUAL EXPOSURE
// ============================================================

function buildAnnualExposure(
  year,
  populationCollection,
  sex
) {

  year = ee.Number(
    year
  );


  var pop =
    getPopulation(
      populationCollection,
      year
    );


  var droughtClass =
    getDrought(
      year
    );


  // ----------------------------------------------------------
  // Classes 1-4 = exposed
  // Class 5     = normal
  //
  // Drought NoData remains masked.
  //
  // Nearest-neighbour is the default Earth Engine
  // reprojection method and is appropriate for categorical
  // drought classes.
  // ----------------------------------------------------------

  var exposedMask =
    droughtClass
      .gte(1)
      .and(
        droughtClass.lte(4)
      );


  var populationExposed =
    pop
      .updateMask(
        exposedMask
      )
      .rename(
        'population_exposed'
      );


  var annualProduct =
    droughtClass
      .rename(
        'drought_class'
      )
      .addBands(
        populationExposed
      );


  return annualProduct

    .set({

      year:
        year,

      population_source_year:
        pop.get(
          'source_year'
        ),

      sex:
        sex,

      variable:
        'population_exposure',

      drought_classes_exposed:
        '1-4',

      drought_normal_class:
        5,

      drought_resampling:
        'nearest_neighbor',

      target_grid:
        'WorldPop_native',

      grid_width:
        POP_WIDTH,

      grid_height:
        POP_HEIGHT,

      grid_definition:
        'dimensions_crs_crsTransform',

      aligned_version:
        true

    })

    .set(
      'system:time_start',

      ee.Date
        .fromYMD(
          year,
          12,
          1
        )
        .millis()
    );

}


// ============================================================
// 6. OPTIONAL ANNUAL QA
// ============================================================

function annualStats(
  year,
  populationCollection,
  sex
) {

  year = ee.Number(
    year
  );


  var pop =
    getPopulation(
      populationCollection,
      year
    );


  var droughtClass =
    getDrought(
      year
    );


  var populationDroughtValid =
    pop
      .updateMask(
        droughtClass.mask()
      )
      .rename(
        'population_drought_valid'
      );


  var populationExposed =
    pop
      .updateMask(
        droughtClass
          .gte(1)
          .and(
            droughtClass.lte(4)
          )
      )
      .rename(
        'population_exposed'
      );


  var class1 =
    pop
      .updateMask(
        droughtClass.eq(1)
      )
      .rename(
        'class_1'
      );


  var class2 =
    pop
      .updateMask(
        droughtClass.eq(2)
      )
      .rename(
        'class_2'
      );


  var class3 =
    pop
      .updateMask(
        droughtClass.eq(3)
      )
      .rename(
        'class_3'
      );


  var class4 =
    pop
      .updateMask(
        droughtClass.eq(4)
      )
      .rename(
        'class_4'
      );


  var class5 =
    pop
      .updateMask(
        droughtClass.eq(5)
      )
      .rename(
        'class_5'
      );


  var qaImage =
    ee.Image.cat([

      pop.rename(
        'population_total'
      ),

      populationDroughtValid,

      populationExposed,

      class1,
      class2,
      class3,
      class4,
      class5

    ]);


  var stats =
    qaImage.reduceRegion({

      reducer:
        ee.Reducer.sum(),

      geometry:
        pop.geometry(),

      crs:
        POP_CRS,

      crsTransform:
        POP_TRANSFORM,

      maxPixels:
        3e10,

      tileScale:
        4

    });


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


  var exposed =
    statOrZero(
      stats,
      'population_exposed'
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


  var classSum =
    c1
      .add(c2)
      .add(c3)
      .add(c4)
      .add(c5);


  var exposureClassSum =
    c1
      .add(c2)
      .add(c3)
      .add(c4);


  return ee.Feature(
    null,
    {

      year:
        year,

      sex:
        sex,

      population_total:
        total,

      population_drought_valid:
        valid,

      population_drought_missing:
        total.subtract(
          valid
        ),

      drought_coverage_pct:
        valid
          .divide(total)
          .multiply(100),

      population_class_1:
        c1,

      pct_class_1_extreme:
        c1
          .divide(total)
          .multiply(100),

      population_class_2:
        c2,

      pct_class_2_severe:
        c2
          .divide(total)
          .multiply(100),

      population_class_3:
        c3,

      pct_class_3_moderate:
        c3
          .divide(total)
          .multiply(100),

      population_class_4:
        c4,

      pct_class_4_weak:
        c4
          .divide(total)
          .multiply(100),

      population_class_5:
        c5,

      pct_class_5_normal:
        c5
          .divide(total)
          .multiply(100),

      population_exposed:
        exposed,

      exposed_pct_total:
        exposed
          .divide(total)
          .multiply(100),

      exposed_pct_drought_valid:
        exposed
          .divide(valid)
          .multiply(100),

      class_balance:
        valid.subtract(
          classSum
        ),

      exposure_balance:
        exposed.subtract(
          exposureClassSum
        )

    }
  );

}


// ============================================================
// 7. OPTIONAL QA EXECUTION
// ============================================================

if (RUN_QA) {

  var qaFeatures = [];


  POPULATION_GROUPS.forEach(
    function(group) {

      YEARS_JS.forEach(
        function(year) {

          qaFeatures.push(
            annualStats(
              year,
              group.collection,
              group.sex
            )
          );

        }
      );

    }
  );


  var annualQA =
    ee.FeatureCollection(
      qaFeatures
    )
    .sort(
      'year'
    );


  print(
    'Exposure QA 2000-2003:',
    annualQA
  );


  if (EXPORT_QA_CSV) {

    Export.table.toDrive({

      collection:
        annualQA,

      description:
        'SO32_exposure_QA_2000_2003',

      folder:
        'PRAIS4_SO3',

      fileNamePrefix:
        'SO32_exposure_QA_2000_2003',

      fileFormat:
        'CSV'

    });

  }

}


// ============================================================
// 8. EXPORT ALIGNED ANNUAL RASTERS
// ============================================================
//
// IMPORTANT:
//
// No "region" is used.
//
// Exact raster dimensions + CRS + affine transform define
// the complete target grid.
//
// Current production configuration:
//
//   Total   = FALSE
//   Female  = TRUE
//   Male    = TRUE
//
// Therefore, expected Tasks = 8.
// ============================================================

POPULATION_GROUPS.forEach(
  function(group) {


    if (!group.export) {

      print(
        'Export skipped:',
        group.sex
      );

      return;
    }


    YEARS_JS.forEach(
      function(year) {


        var product =
          buildAnnualExposure(
            year,
            group.collection,
            group.sex
          );


        Export.image.toAsset({

          image:
            product,

          description:
            'SO32_exposure_' +
            group.sex +
            '_' +
            year +
            '_aligned',

          assetId:
            group.output +
            '/exposure_' +
            group.sex +
            '_' +
            year +
            '_aligned',

          dimensions:
            POP_DIMENSIONS,

          crs:
            POP_CRS,

          crsTransform:
            POP_TRANSFORM,

          maxPixels:
            1e13,

          pyramidingPolicy: {

            drought_class:
              'mode',

            population_exposed:
              'mean'

          }

        });

      }
    );

  }
);


// ============================================================
// 9. VISUAL CHECK - 2000
// ============================================================

var annualTotal2000 =
  buildAnnualExposure(
    2000,
    populationTotal,
    'total'
  );


var annualFemale2000 =
  buildAnnualExposure(
    2000,
    populationFemale,
    'female'
  );


var annualMale2000 =
  buildAnnualExposure(
    2000,
    populationMale,
    'male'
  );


Map.centerObject(
  getPopulation(
    populationTotal,
    2000
  ),
  4
);


Map.addLayer(

  annualTotal2000.select(
    'drought_class'
  ),

  {
    min: 1,
    max: 5
  },

  'Drought class 2000',

  false

);


Map.addLayer(

  annualTotal2000.select(
    'population_exposed'
  ),

  {
    min: 0,
    max: 100
  },

  'Population exposed TOTAL 2000',

  false

);


Map.addLayer(

  annualFemale2000.select(
    'population_exposed'
  ),

  {
    min: 0,
    max: 50
  },

  'Population exposed FEMALE 2000',

  false

);


Map.addLayer(

  annualMale2000.select(
    'population_exposed'
  ),

  {
    min: 0,
    max: 50
  },

  'Population exposed MALE 2000',

  false

);


// ============================================================
// END
// ============================================================

print(
  '========================================'
);

print(
  'ALIGNED ANNUAL EXPORT TASKS CREATED'
);

print(
  'Expected grid:',
  POP_DIMENSIONS
);

print(
  'QA recalculation:',
  RUN_QA
);

print(
  'Total export:',
  POPULATION_GROUPS[0].export
);

print(
  'Female export:',
  POPULATION_GROUPS[1].export
);

print(
  'Male export:',
  POPULATION_GROUPS[2].export
);

print(
  'Expected current export tasks: 8'
);

print(
  '========================================'
);
