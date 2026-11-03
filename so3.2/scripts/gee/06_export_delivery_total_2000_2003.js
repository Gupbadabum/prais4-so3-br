// ============================================================
// PRAIS4 / SO3.2
// EXPORT QUADRENNIAL MASTER RASTER
//
// Purpose:
//
//   Export the complete validated quadrennial SO3.2 master
//   raster from Earth Engine to Google Drive.
//
// The exported raster contains all information required for
// subsequent local derivation of:
//
//   - PRAIS total population-exposed raster;
//   - drought-class technical raster;
//   - female exposed-population raster;
//   - male exposed-population raster;
//   - QA products;
//   - maps and other derived products.
//
// No analytical reconstruction is performed here.
//
// The validated Earth Engine Asset is the source of truth.
//
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
// 1. EXPORT CONTROL
// ============================================================

var EXPORT_MASTER =
  true;


// ============================================================
// 2. ASSET AND OUTPUT
// ============================================================

var ASSET_ROOT =
  'projects/cursoqueimadas-503722/assets/';


var QUAD_ASSET =
  ASSET_ROOT +
  'SO32_exposure_quadrennial_' +
  PERIOD_ID;


var OUTPUT_NAME =
  'SO32_exposure_quadrennial_' +
  PERIOD_ID;


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


var POP_WIDTH =
  54172;


var POP_HEIGHT =
  46814;


var POP_DIMENSIONS =
  POP_WIDTH +
  'x' +
  POP_HEIGHT;


// ============================================================
// 4. LOAD VALIDATED MASTER
// ============================================================

var quad =
  ee.Image(
    QUAD_ASSET
  );


// ============================================================
// 5. EXPECTED MASTER STRUCTURE
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
// 6. LIGHT STRUCTURAL QA
// ============================================================

print(
  '========================================'
);


print(
  '06 - EXPORT QUADRENNIAL MASTER'
);


print(
  'Period:',
  PERIOD
);


print(
  'Source Asset:',
  QUAD_ASSET
);


print(
  'Master bands:',
  quad.bandNames()
);


print(
  'Expected master bands:',
  EXPECTED_BANDS
);


print(
  'Expected band count:',
  EXPECTED_BANDS.length
);


print(
  'Grid dimensions:',
  POP_DIMENSIONS
);


print(
  'Grid CRS:',
  POP_CRS
);


print(
  'Grid transform:',
  POP_TRANSFORM
);


print(
  '========================================'
);


// ============================================================
// 7. PREPARE MASTER FOR GEOTIFF EXPORT
// ============================================================
//
// GeoTIFF requires compatible band data types.
//
// The master combines categorical/count bands and continuous
// population bands.
//
// For a single multiband GeoTIFF, all nine bands are exported
// as Float32.
//
// This does NOT alter the categorical/count values:
// integers 0-5 are exactly representable in Float32.
//
// Common explicit NoData value:
//
//   -9999
//
// Band order is preserved exactly.
// ============================================================

var masterExport =
  quad

    .select(
      EXPECTED_BANDS
    )

    .toFloat()

    .unmask(
      -9999
    )

    .set({

      product:
        'SO3.2_quadrennial_master',

      period:
        PERIOD,

      year_start:
        YEAR_START,

      year_end:
        YEAR_END,

      population_groups:
        'total,female,male',

      drought_classes_exposed:
        '1-4',

      drought_class_normal:
        5,

      nodata_value:
        -9999,

      grid_reference:
        'WorldPop_100m',

      source_asset:
        QUAD_ASSET

    });


// ============================================================
// 8. EXPORT COMPLETE MASTER
// ============================================================
//
// IMPORTANT:
//
//   - No region.
//
//   - dimensions + CRS + affine transform define exactly the
//     validated WorldPop grid.
//
//   - fileDimensions controls only how the GeoTIFF export is
//     physically divided into files.
//
//   - It does NOT change the analytical grid.
//
// 8192 x 8192 keeps each part at a manageable size.
//
// After download, the pieces can be assembled locally with
// GDAL without reprojection or resampling.
// ============================================================

if (EXPORT_MASTER) {

  Export.image.toDrive({

    image:
      masterExport,

    description:
      OUTPUT_NAME,

    folder:
      OUTPUT_FOLDER,

    fileNamePrefix:
      OUTPUT_NAME,

    dimensions:
      POP_DIMENSIONS,

    crs:
      POP_CRS,

    crsTransform:
      POP_TRANSFORM,

    shardSize:
      256,

    fileDimensions:
      8192,

    maxPixels:
      5e9,

    fileFormat:
      'GeoTIFF',

    formatOptions: {

      cloudOptimized:
        false,

      noData:
        -9999

    }

  });

}


// ============================================================
// 9. OPERATIONAL SUMMARY
// ============================================================

var EXPECTED_TASKS =
  EXPORT_MASTER
    ? 1
    : 0;


print(
  '========================================'
);


print(
  'MASTER EXPORT CONFIGURATION'
);


print(
  'Period:',
  PERIOD
);


print(
  'Output:',
  OUTPUT_NAME
);


print(
  'Bands:',
  EXPECTED_BANDS.length
);


print(
  'Output data type:',
  'Float32'
);


print(
  'NoData:',
  -9999
);


print(
  'Grid dimensions:',
  POP_DIMENSIONS
);


print(
  'GeoTIFF file dimensions:',
  '8192x8192'
);


print(
  'Export master:',
  EXPORT_MASTER
);


print(
  'Expected Tasks:',
  EXPECTED_TASKS
);


print(
  'No region is used.'
);


print(
  'No reprojection or resampling is performed.'
);


print(
  'Local processing will derive delivery products.'
);


print(
  '========================================'
);
