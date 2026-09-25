// ============================================================
// PRAIS4 / SO3.2
// DELIVERY EXPORT
// Period: 2000-2003
// Population: TOTAL
//
// Exports final aligned rasters to Google Drive.
// ============================================================


// ============================================================
// 0. CONFIGURATION
// ============================================================

var QUAD_ASSET =
  'projects/cursoqueimadas-503722/assets/' +
  'exposure_total_quadrennial_2000_2003_aligned';


// Earth Engine Export.image.toDrive uses a FOLDER NAME,
// not a Google Drive folder ID.
var EXPORT_FOLDER =
  'PRAIS4_SO3';


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


var POP_DIMENSIONS =
  '54172x46814';


// ============================================================
// 1. LOAD FINAL QUADRENNIAL ASSET
// ============================================================

var quad =
  ee.Image(
    QUAD_ASSET
  );


var worstDrought =
  quad
    .select(
      'worst_drought_class'
    );


var populationExposed =
  quad
    .select(
      'population_exposed'
    );

var populationSupport =
  quad
    .select(
      'critical_year_count'
    )
    .mask();

// ============================================================
// 2. FINAL DROUGHT-CLASS RASTER
//
// 1 = Extreme
// 2 = Severe
// 3 = Moderate
// 4 = Weak
// 5 = Normal
// 0 = NoData
// ============================================================

var droughtExport =
  worstDrought
    .unmask(0)
    .toByte();


// ============================================================
// 3. FINAL EXPOSED-POPULATION RASTER
//
// Exposure classes 1-4:
//   population value
//
// Class 5 (Normal):
//   0
//
// Missing drought:
//   -9999
//
// This gives the delivery raster an explicit distinction
// between valid non-exposure (= 0) and true NoData (= -9999).
// ============================================================

var droughtValid =
  worstDrought.mask();


var exposedValidGrid =
  ee.Image
    .constant(0)
    .toFloat()

    .where(
      populationExposed.mask(),
      populationExposed
    )

    .updateMask(
      droughtValid
    )

    .updateMask(
      populationSupport
    );


var exposedExport =
  exposedValidGrid
    .unmask(-9999)
    .toFloat();


// ============================================================
// 4. CHECKS
// ============================================================

print(
  '========================================'
);

print(
  'SO3.2 DELIVERY EXPORT - 2000-2003'
);

print(
  '========================================'
);


print(
  'Source asset:',
  quad
);


print(
  'Source bands:',
  quad.bandNames()
);


print(
  'Output dimensions:',
  POP_DIMENSIONS
);


print(
  'Output transform:',
  POP_TRANSFORM
);


// ============================================================
// 5. EXPORT WORST DROUGHT CLASS
// ============================================================

Export.image.toDrive({

  image:
    droughtExport,

  description:
    'SO32_drought_class_2000_2003_total',

  folder:
    EXPORT_FOLDER,

  fileNamePrefix:
    'SO32_drought_class_2000_2003',

  dimensions:
    POP_DIMENSIONS,

  crs:
    POP_CRS,

  crsTransform:
    POP_TRANSFORM,

  maxPixels:
    1e13,

  fileFormat:
    'GeoTIFF',

  formatOptions: {

    cloudOptimized:
      true,

    noData:
      0

  }

});


// ============================================================
// 6. EXPORT EXPOSED POPULATION
// ============================================================

Export.image.toDrive({

  image:
    exposedExport,

  description:
    'SO32_population_exposed_total_2000_2003',

  folder:
    EXPORT_FOLDER,

  fileNamePrefix:
    'SO32_population_exposed_total_2000_2003',

  dimensions:
    POP_DIMENSIONS,

  crs:
    POP_CRS,

  crsTransform:
    POP_TRANSFORM,

  maxPixels:
    1e13,

  fileFormat:
    'GeoTIFF',

  formatOptions: {

    cloudOptimized:
      true,

    noData:
      -9999

  }

});


// ============================================================
// END
// ============================================================

print(
  'Two final raster export tasks created.'
);

print(
  '1. Worst drought class raster'
);

print(
  '2. Exposed population raster'
);

print(
  '========================================'
);
