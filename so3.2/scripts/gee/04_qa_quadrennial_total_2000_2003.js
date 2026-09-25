// ============================================================
// PRAIS4 / SO3.2
// QA - QUADRENNIAL EXPOSURE
// Period: 2000-2003
// Population: TOTAL
// ============================================================


// ------------------------------------------------------------
// Asset
// ------------------------------------------------------------

var quad = ee.Image(
  'projects/cursoqueimadas-503722/assets/' +
  'exposure_total_quadrennial_2000_2003'
);


// ------------------------------------------------------------
// WorldPop grid
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


// ============================================================
// 1. BASIC CHECKS
// ============================================================

print(
  'Quadrennial image:',
  quad
);

print(
  'Bands:',
  quad.bandNames()
);

print(
  'Projection:',
  quad
    .select('worst_drought_class')
    .projection()
);

print(
  'Nominal scale:',
  quad
    .select('worst_drought_class')
    .projection()
    .nominalScale()
);


// ============================================================
// 2. MIN / MAX CHECK
// ============================================================

var minMax = quad.reduceRegion({

  reducer:
    ee.Reducer.minMax(),

  geometry:
    quad.geometry(),

  crs:
    POP_CRS,

  crsTransform:
    POP_TRANSFORM,

  maxPixels:
    2e10,

  tileScale:
    4

});

print(
  'Quadrennial min/max:',
  minMax
);


// ============================================================
// 3. EXPOSED POPULATION SUM
// ============================================================

var exposedSum =
  quad
    .select(
      'population_exposed'
    )
    .reduceRegion({

      reducer:
        ee.Reducer.sum(),

      geometry:
        quad.geometry(),

      crs:
        POP_CRS,

      crsTransform:
        POP_TRANSFORM,

      maxPixels:
        3e9,

      tileScale:
        4

    });

print(
  'Quadrennial exposed population:',
  exposedSum
);


// ============================================================
// 4. WORST DROUGHT CLASS HISTOGRAM
// ============================================================

var droughtHistogram =
  quad
    .select(
      'worst_drought_class'
    )
    .reduceRegion({

      reducer:
        ee.Reducer.frequencyHistogram(),

      geometry:
        quad.geometry(),

      crs:
        POP_CRS,

      crsTransform:
        POP_TRANSFORM,

      maxPixels:
        3e9,

      tileScale:
        4

    });

print(
  'Worst drought class histogram:',
  droughtHistogram
);


// ============================================================
// 5. VISUAL CHECK
// ============================================================

Map.centerObject(
  quad,
  4
);

Map.addLayer(
  quad.select(
    'worst_drought_class'
  ),
  {
    min: 1,
    max: 5
  },
  'Worst drought class 2000-2003',
  true
);

Map.addLayer(
  quad.select(
    'population_exposed'
  ),
  {
    min: 0,
    max: 100
  },
  'Population exposed 2000-2003',
  false
);
