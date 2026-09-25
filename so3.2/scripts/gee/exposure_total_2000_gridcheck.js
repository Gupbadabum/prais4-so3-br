// ============================================================
// PRAIS4 / SO3.2
// GRID CHECK - ANNUAL EXPOSURE 2000
//
// Purpose:
//
//   Test an export of the annual 2000 exposure product using
//   the EXACT validated WorldPop grid:
//
//     width  = 54172 pixels
//     height = 46814 pixels
//
//   This script does NOT replace the current annual Asset.
//   It creates a temporary validation Asset:
//
//     exposure_total_2000_gridcheck
//
// Expected final grid:
//
//   dimensions:
//     54172 x 46814
//
//   transform:
//     [0.0008333333300044304, 0, -73.989583022,
//      0, -0.0008333333300081173, 5.264583514]
// ============================================================


// ============================================================
// 0. CONFIGURATION
// ============================================================

var YEAR = 2000;


// ------------------------------------------------------------
// Inputs
// ------------------------------------------------------------

var DROUGHT_ASSET =
  'projects/cursoqueimadas-503722/assets/' +
  'drought_spei12_dec';

var POP_TOTAL_ASSET =
  'projects/cursoqueimadas-503722/assets/' +
  'population_total';


// ------------------------------------------------------------
// Temporary output
// ------------------------------------------------------------

var OUTPUT_ASSET =
  'projects/cursoqueimadas-503722/assets/' +
  'exposure_total_annual/' +
  'exposure_total_2000_gridcheck';


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


// ------------------------------------------------------------
// Exact grid bounds calculated from:
// origin + dimensions x pixel size
// ------------------------------------------------------------

var POP_XMIN =
  -73.989583022;

var POP_XMAX =
  -28.846249869000005;

var POP_YMIN =
  -33.747082997;

var POP_YMAX =
   5.264583514;


// ------------------------------------------------------------
// Exact export region
// ------------------------------------------------------------

var POP_REGION =
  ee.Geometry.Rectangle(
    [
      POP_XMIN,
      POP_YMIN,
      POP_XMAX,
      POP_YMAX
    ],
    POP_CRS,
    false
  );


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


// ============================================================
// 3. YEAR 2000 INPUTS
// ============================================================

var drought2000 =
  ee.Image(
    drought
      .filter(
        ee.Filter.eq(
          'year',
          YEAR
        )
      )
      .first()
  )
  .select(0)
  .rename(
    'drought_class'
  )
  .toByte();


var population2000 =
  ee.Image(
    populationTotal
      .filter(
        ee.Filter.eq(
          'year',
          YEAR
        )
      )
      .first()
  )
  .select(0)
  .rename(
    'population'
  );


// ============================================================
// 4. EXPOSURE - SAME LOGIC AS SCRIPT 02
// ============================================================
//
// Classes 1-4 = exposed
// Class 5     = normal
//
// Drought NoData remains masked.
//
// Nearest-neighbour is the default reprojection method
// for this categorical raster.
// ============================================================

var exposedMask =
  drought2000
    .gte(1)
    .and(
      drought2000.lte(4)
    );


var populationExposed =
  population2000
    .updateMask(
      exposedMask
    )
    .rename(
      'population_exposed'
    );


// ------------------------------------------------------------
// Two-band annual product
// ------------------------------------------------------------

var annualProduct =
  drought2000
    .rename(
      'drought_class'
    )
    .addBands(
      populationExposed
    )
    .set({

      year:
        YEAR,

      population_source_year:
        2000,

      sex:
        'total',

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

      gridcheck:
        true

    })
    .set(
      'system:time_start',

      ee.Date
        .fromYMD(
          YEAR,
          12,
          1
        )
        .millis()
    );


// ============================================================
// 5. PRE-EXPORT CHECKS
// ============================================================

print(
  '========================================'
);

print(
  'GRID CHECK - EXPOSURE TOTAL 2000'
);

print(
  '========================================'
);


print(
  'Population reference image:',
  population2000
);


print(
  'Population reference projection:',
  population2000.projection()
);


print(
  'Expected width:',
  POP_WIDTH
);


print(
  'Expected height:',
  POP_HEIGHT
);


print(
  'Expected transform:',
  POP_TRANSFORM
);


print(
  'Export region:',
  POP_REGION
);


print(
  'Expected bounds:',
  ee.Dictionary({

    xmin:
      POP_XMIN,

    xmax:
      POP_XMAX,

    ymin:
      POP_YMIN,

    ymax:
      POP_YMAX

  })
);


// ============================================================
// 6. EXPORT GRIDCHECK ASSET
// ============================================================
//
// IMPORTANT:
//
// Unlike script 02, the region here is NOT:
//
//   population2000.geometry()
//
// It is the exact rectangle corresponding to the validated
// WorldPop dimensions and affine transform.
// ============================================================

Export.image.toAsset({

  image:
    annualProduct,

  description:
    'SO32_exposure_total_2000_gridcheck_v2',

  assetId:
    'projects/cursoqueimadas-503722/assets/' +
    'exposure_total_annual/' +
    'exposure_total_2000_gridcheck_v2',

  dimensions:
    '54172x46814',

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


// ============================================================
// 7. OPTIONAL VISUAL CHECK
// ============================================================

Map.centerObject(
  POP_REGION,
  4
);


Map.addLayer(

  annualProduct.select(
    'drought_class'
  ),

  {
    min: 1,
    max: 5
  },

  'Drought class 2000 - gridcheck',

  false

);


Map.addLayer(

  annualProduct.select(
    'population_exposed'
  ),

  {
    min: 0,
    max: 100
  },

  'Population exposed 2000 - gridcheck',

  false

);


// ============================================================
// END
// ============================================================

print(
  'Gridcheck export task created.'
);

var test = ee.Image(
  'projects/cursoqueimadas-503722/assets/' +
  'exposure_total_annual/' +
  'exposure_total_2000_gridcheck'
);

print('GRIDCHECK IMAGE:', test);

print(
  'GRIDCHECK PROJECTION:',
  test.select('drought_class').projection()
);

var test = ee.Image(
  'projects/cursoqueimadas-503722/assets/' +
  'exposure_total_annual/' +
  'exposure_total_2000_gridcheck_v2'
);

print('GRIDCHECK V2:', test);

print(
  'GRIDCHECK V2 PROJECTION:',
  test.select('drought_class').projection()
);
