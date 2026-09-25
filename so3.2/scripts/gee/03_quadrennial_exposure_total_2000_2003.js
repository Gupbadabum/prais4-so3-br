// ============================================================
// PRAIS4 / SO3.2
// QUADRENNIAL EXPOSURE
// Period: 2000-2003
// Population: TOTAL
//
// ALIGNED VERSION
//
// Exact WorldPop target grid:
//   54172 x 46814 pixels
//
// Core PRAIS spatial concept:
//   greatest drought intensity observed during the period.
//
// Cemaden-derived treatment:
//   if the worst drought class occurs in more than one year,
//   population is averaged across the tied critical years.
// ============================================================


// ============================================================
// 0. CONFIGURATION
// ============================================================

var YEARS =
  ee.List([
    2000,
    2001,
    2002,
    2003
  ]);


var PERIOD =
  '2000-2003';


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
// Corrected output
//
// Existing old Asset is preserved.
// ------------------------------------------------------------

var OUTPUT_ASSET =
  'projects/cursoqueimadas-503722/assets/' +
  'exposure_total_quadrennial_2000_2003_aligned';


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


var population =
  ee.ImageCollection(
    POP_TOTAL_ASSET
  );


print(
  'Period:',
  PERIOD
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
// 3. SUPPORT FUNCTIONS
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


function getPopulation(year) {

  return ee.Image(
    population
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


// ============================================================
// 4. DROUGHT DURING THE FOUR-YEAR PERIOD
// ============================================================

var droughtPeriod =
  ee.ImageCollection.fromImages(

    YEARS.map(
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
// ------------------------------------------------------------

var worstDrought =
  droughtPeriod
    .min()
    .rename(
      'worst_drought_class'
    )
    .toByte();


// ============================================================
// 5. HAZARD QA
// ============================================================

// ------------------------------------------------------------
// Number of years with valid drought information
// ------------------------------------------------------------

var hazardValidYears =
  droughtPeriod
    .count()
    .rename(
      'hazard_valid_years'
    )
    .toByte();


// ------------------------------------------------------------
// Flag cells with at least one missing drought year
// ------------------------------------------------------------

var hazardMissingFlag =
  hazardValidYears
    .lt(4)
    .rename(
      'hazard_missing_flag'
    )
    .toByte();


// ============================================================
// 6. POPULATION OF CRITICAL YEAR(S)
// ============================================================
//
// For each year:
//
// retain population only where that year's drought class is
// equal to the worst drought class observed during 2000-2003.
//
// If two or more years are tied, their populations are averaged.
// ============================================================

var criticalPopulationCollection =
  ee.ImageCollection.fromImages(

    YEARS.map(
      function(year) {


        var droughtYear =
          getDrought(
            year
          );


        var popYear =
          getPopulation(
            year
          );


        var critical =
          droughtYear.eq(
            worstDrought
          );


        return popYear
          .updateMask(
            critical
          )
          .rename(
            'critical_population'
          );

      }
    )

  );


// ------------------------------------------------------------
// Mean population among tied critical years
// ------------------------------------------------------------

var criticalPopulationMean =
  criticalPopulationCollection
    .mean()
    .rename(
      'critical_population_mean'
    );


// ============================================================
// 7. NUMBER OF CRITICAL YEARS
// ============================================================

var criticalCountCollection =
  ee.ImageCollection.fromImages(

    YEARS.map(
      function(year) {


        var droughtYear =
          getDrought(
            year
          );


        var popYear =
          getPopulation(
            year
          );


        var critical =
          droughtYear.eq(
            worstDrought
          );


        return popYear
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
      'critical_year_count'
    )
    .toByte();


// ============================================================
// 8. QUADRENNIAL EXPOSED POPULATION
// ============================================================

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
      'population_exposed'
    );


// ============================================================
// 9. FINAL QUADRENNIAL PRODUCT
// ============================================================

var quadrennialProduct =
  ee.Image.cat([

    worstDrought,

    populationExposed,

    criticalYearCount,

    hazardValidYears,

    hazardMissingFlag

  ])

  .set({

    period:
      PERIOD,

    sex:
      'total',

    variable:
      'population_exposure',

    drought_classes_exposed:
      '1-4',

    population_tie_rule:
      'mean_of_critical_years',

    target_grid:
      'WorldPop_native',

    drought_resampling:
      'nearest_neighbor',

    grid_width:
      POP_WIDTH,

    grid_height:
      POP_HEIGHT,

    grid_definition:
      'dimensions_crs_crsTransform',

    aligned_version:
      true

  });


// ============================================================
// 10. PRE-EXPORT CHECK
// ============================================================

print(
  'Quadrennial product bands:',
  quadrennialProduct.bandNames()
);


print(
  'Expected dimensions:',
  POP_DIMENSIONS
);


print(
  'Expected transform:',
  POP_TRANSFORM
);


// ============================================================
// 11. EXPORT ALIGNED QUADRENNIAL PRODUCT
// ============================================================
//
// IMPORTANT:
//
// No "region" is used.
//
// Exact dimensions + CRS + affine transform define the raster.
// ============================================================

Export.image.toAsset({

  image:
    quadrennialProduct,

  description:
    'SO32_exposure_total_quadrennial_2000_2003_aligned',

  assetId:
    OUTPUT_ASSET,

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

    population_exposed:
      'mean',

    critical_year_count:
      'mode',

    hazard_valid_years:
      'mode',

    hazard_missing_flag:
      'mode'

  }

});


// ============================================================
// 12. VISUAL CHECK
// ============================================================

Map.centerObject(
  getPopulation(
    2000
  ),
  4
);


Map.addLayer(

  worstDrought,

  {
    min: 1,
    max: 5
  },

  'Worst drought class 2000-2003',

  true

);


Map.addLayer(

  populationExposed,

  {
    min: 0,
    max: 100
  },

  'Population exposed 2000-2003',

  false

);


// ============================================================
// END
// ============================================================

print(
  '========================================'
);

print(
  'ALIGNED QUADRENNIAL EXPORT TASK CREATED'
);

print(
  'Period: 2000-2003'
);

print(
  'Expected grid: 54172 x 46814'
);

print(
  '========================================'
);
