// ============================================================
// PRAIS4 / SO3.2
// MUNICIPAL EXPOSURE
// Period: 2000-2003
// Population: TOTAL
//
// Municipal reference:
//   IBGE/MUNICIPIOS/V2025
//
// Purpose:
//   Materialize the municipal exposure product.
//
// IMPORTANT:
//
//   - PRAIS official map remains raster-based.
//   - Municipal product is Cemaden-derived.
//   - Municipal thematic map will be produced AFTER this
//     FeatureCollection is materialized (Script 06).
// ============================================================


// ============================================================
// 0. CONFIGURATION
// ============================================================

var YEARS = [
  2000,
  2001,
  2002,
  2003
];

var PERIOD = '2000-2003';
var SEX = 'total';

var PROJECT =
  'projects/cursoqueimadas-503722/assets/';


// ------------------------------------------------------------
// Exact aligned inputs
// ------------------------------------------------------------

var ANNUAL_EXPOSURE_BASE =
  PROJECT + 'exposure_total_annual/';

var POPULATION_BASE =
  PROJECT + 'population_total/';

var QUAD_ASSET =
  PROJECT +
  'exposure_total_quadrennial_2000_2003_aligned';


// ------------------------------------------------------------
// Municipal mesh
// ------------------------------------------------------------

var MUNICIPAL_ASSET =
  'IBGE/MUNICIPIOS/V2025';


// ------------------------------------------------------------
// Output
// ------------------------------------------------------------

var MUNICIPAL_OUTPUT_ASSET =
  PROJECT +
  'municipal_exposure_total_2000_2003_ibge2025';


// ============================================================
// 1. WORLDPOP GRID
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
// 2. EXACT ANNUAL ALIGNED DROUGHT PRODUCTS
// ============================================================

var droughtAligned = {};

YEARS.forEach(
  function(year) {

    droughtAligned[year] =
      ee.Image(
        ANNUAL_EXPOSURE_BASE +
        'exposure_total_' +
        year +
        '_aligned'
      )
      .select(
        'drought_class'
      )
      .rename(
        'drought_class'
      )
      .toByte();

  }
);


// ============================================================
// 3. EXACT ANNUAL POPULATION PRODUCTS
// ============================================================

var populationAnnual = {};

YEARS.forEach(
  function(year) {

    populationAnnual[year] =
      ee.Image(
        POPULATION_BASE +
        'population_total_' +
        year
      )
      .select(0)
      .rename(
        'population'
      );

  }
);


// ============================================================
// 4. QUADRENNIAL ALIGNED PRODUCT
// ============================================================

var quad =
  ee.Image(
    QUAD_ASSET
  );


var worstDrought =
  quad
    .select(
      'worst_drought_class'
    )
    .rename(
      'worst_drought_class'
    );


var populationExposed =
  quad
    .select(
      'population_exposed'
    )
    .rename(
      'population_exposed'
    );


// ============================================================
// 5. IBGE MUNICIPAL MESH 2025
// ============================================================

var municipalUnitsAll =
  ee.FeatureCollection(
    MUNICIPAL_ASSET
  );


// ------------------------------------------------------------
// Operational water-body codes:
//
//   4300001 = Lagoa Mirim
//   4300002 = Lagoa dos Patos
//
// Exclusion by CODE is intentional.
// Do not exclude by NM_MUN.
// ------------------------------------------------------------

var waterUnits =
  municipalUnitsAll

    .filter(
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


// ============================================================
// 6. LIGHTWEIGHT INPUT QA
// ============================================================

print(
  '========================================'
);

print(
  '05 - MUNICIPAL EXPOSURE'
);

print(
  '========================================'
);


print(
  'IBGE 2025 - all units:',
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
  'Water unit names:',
  waterUnits.aggregate_array(
    'NM_MUN'
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
  'Boa Esperanca do Norte:',
  municipalities
    .filter(
      ee.Filter.eq(
        'NM_MUN',
        'Boa Esperança do Norte'
      )
    )
    .size()
);


print(
  'Quadrennial bands:',
  quad.bandNames()
);


// ============================================================
// 7. RECONSTRUCT CRITICAL-YEAR POPULATION
// ============================================================
//
// Same rule as Script 03:
//
//   worst drought class during 2000-2003
//   +
//   population from year(s) reaching that class
//
// If tied:
//   mean population across critical years.
// ============================================================

var criticalPopulationImages =
  YEARS.map(
    function(year) {


      var droughtYear =
        droughtAligned[year];


      var populationYear =
        populationAnnual[year];


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
        )

        .set(
          'year',
          year
        );

    }
  );


var criticalPopulationCollection =
  ee.ImageCollection.fromImages(
    criticalPopulationImages
  );


var populationReference =
  criticalPopulationCollection

    .mean()

    .rename(
      'population_reference'
    );


// ============================================================
// 8. POPULATION BY DROUGHT CLASS
// ============================================================

var class1 =
  populationReference

    .updateMask(
      worstDrought.eq(1)
    )

    .rename(
      'population_class_1'
    );


var class2 =
  populationReference

    .updateMask(
      worstDrought.eq(2)
    )

    .rename(
      'population_class_2'
    );


var class3 =
  populationReference

    .updateMask(
      worstDrought.eq(3)
    )

    .rename(
      'population_class_3'
    );


var class4 =
  populationReference

    .updateMask(
      worstDrought.eq(4)
    )

    .rename(
      'population_class_4'
    );


var class5 =
  populationReference

    .updateMask(
      worstDrought.eq(5)
    )

    .rename(
      'population_class_5'
    );


// ============================================================
// 9. MUNICIPAL REDUCTION STACK
// ============================================================
//
// unmask(0) is used only for zonal sums.
//
// Earth Engine retains the original image footprint by
// default when unmask() is used.
// ============================================================

var municipalStack =
  ee.Image.cat([

    populationReference
      .unmask(0),

    populationExposed
      .unmask(0),

    class1
      .unmask(0),

    class2
      .unmask(0),

    class3
      .unmask(0),

    class4
      .unmask(0),

    class5
      .unmask(0)

  ]);


// ============================================================
// 10. SUPPORT FUNCTION
// ============================================================

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
// 11. ADD MUNICIPAL INDICATORS
// ============================================================

function addMunicipalIndicators(
  feature
) {


  var total =
    featureNumberOrZero(
      feature,
      'population_reference'
    );


  var exposed =
    featureNumberOrZero(
      feature,
      'population_exposed'
    );


  var c1 =
    featureNumberOrZero(
      feature,
      'population_class_1'
    );


  var c2 =
    featureNumberOrZero(
      feature,
      'population_class_2'
    );


  var c3 =
    featureNumberOrZero(
      feature,
      'population_class_3'
    );


  var c4 =
    featureNumberOrZero(
      feature,
      'population_class_4'
    );


  var c5 =
    featureNumberOrZero(
      feature,
      'population_class_5'
    );


  var hasPopulation =
    total.gt(0);


  function percentage(value) {

    return ee.Number(

      ee.Algorithms.If(

        hasPopulation,

        value
          .divide(total)
          .multiply(100),

        0

      )

    );

  }


  var classBalance =
    total.subtract(

      c1
        .add(c2)
        .add(c3)
        .add(c4)
        .add(c5)

    );


  var exposureBalance =
    exposed.subtract(

      c1
        .add(c2)
        .add(c3)
        .add(c4)

    );


  return feature.set({

    period:
      PERIOD,

    sex:
      SEX,

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

    population_reference_positive:
      ee.Number(
        ee.Algorithms.If(
          hasPopulation,
          1,
          0
        )
      ),


    // --------------------------------------------------------
    // Exposure
    // --------------------------------------------------------

    exposed_pct_reference:
      percentage(
        exposed
      ),


    // --------------------------------------------------------
    // Drought classes
    // --------------------------------------------------------

    pct_class_1_extreme:
      percentage(
        c1
      ),

    pct_class_2_severe:
      percentage(
        c2
      ),

    pct_class_3_moderate:
      percentage(
        c3
      ),

    pct_class_4_weak:
      percentage(
        c4
      ),

    pct_class_5_normal:
      percentage(
        c5
      ),


    // --------------------------------------------------------
    // QA
    // --------------------------------------------------------

    class_balance:
      classBalance,

    class_balance_abs:
      classBalance.abs(),

    exposure_balance:
      exposureBalance,

    exposure_balance_abs:
      exposureBalance.abs()

  });

}


// ============================================================
// 12. PILOT MUNICIPAL QA
//
// Evaluate only São Paulo interactively.
//
// This verifies the complete raster -> municipality chain
// without forcing all 5,571 polygons through the Console.
// ============================================================

var pilotMunicipality =
  municipalities.filter(
    ee.Filter.eq(
      'NM_MUN',
      'São Paulo'
    )
  );


var pilotRaw =
  municipalStack.reduceRegions({

    collection:
      pilotMunicipality,

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


var pilotExposure =
  pilotRaw.map(
    addMunicipalIndicators
  );


print(
  '========================================'
);

print(
  'PILOT - SAO PAULO'
);

print(
  '========================================'
);


print(
  'Pilot municipal result:',
  pilotExposure.first()
);


// ============================================================
// 13. FULL MUNICIPAL PRODUCT
//
// IMPORTANT:
//
// This object is NOT printed interactively.
//
// The complete national computation will be performed as
// a batch export.
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


var municipalExposure =
  municipalRaw.map(
    addMunicipalIndicators
  );


// ============================================================
// 14. EXPORT FEATURECOLLECTION TO EE ASSET
// ============================================================

Export.table.toAsset({

  collection:
    municipalExposure,

  description:
    'SO32_municipal_exposure_total_2000_2003_ibge2025',

  assetId:
    MUNICIPAL_OUTPUT_ASSET

});


// ============================================================
// 15. CSV FIELDS
// ============================================================

var CSV_FIELDS = [

  // Territorial identification

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


  // Product metadata

  'period',
  'sex',

  'municipal_mesh',
  'municipal_mesh_year',

  'territorial_interpretation',

  'population_reference_rule',

  'percentage_denominator',

  'drought_classes_exposed',


  // Population

  'population_reference',
  'population_reference_positive',


  // Class 1

  'population_class_1',
  'pct_class_1_extreme',


  // Class 2

  'population_class_2',
  'pct_class_2_severe',


  // Class 3

  'population_class_3',
  'pct_class_3_moderate',


  // Class 4

  'population_class_4',
  'pct_class_4_weak',


  // Class 5

  'population_class_5',
  'pct_class_5_normal',


  // Exposure

  'population_exposed',
  'exposed_pct_reference',


  // QA

  'class_balance',
  'class_balance_abs',

  'exposure_balance',
  'exposure_balance_abs'

];


// ============================================================
// 16. CSV WITHOUT GEOMETRY
//
// FeatureCollection.select() can explicitly remove geometry.
// No setGeometry() chain is needed.
// ============================================================

var municipalCSV =
  municipalExposure.select({

    propertySelectors:
      CSV_FIELDS,

    retainGeometry:
      false

  });


// ============================================================
// 17. EXPORT CSV
// ============================================================

Export.table.toDrive({

  collection:
    municipalCSV,

  description:
    'SO32_municipal_exposure_total_2000_2003_ibge2025',

  folder:
    'PRAIS4_SO3',

  fileNamePrefix:
    'SO32_municipal_exposure_total_2000_2003_ibge2025',

  fileFormat:
    'CSV'

});


// ============================================================
// 18. MAP
//
// For now display only:
//   - quadrennial raster
//   - official IBGE 2025 boundaries
//
// The municipal thematic map will be generated in Script 06
// AFTER the municipal FeatureCollection is materialized.
// ============================================================

Map.setCenter(
  -51.9253,
  -14.235,
  4
);


Map.addLayer(

  populationExposed,

  {
    min:
      0,

    max:
      100
  },

  'Quadrennial exposed population - 2000-2003',

  false

);


// ------------------------------------------------------------
// Efficient IBGE boundary visualization
// ------------------------------------------------------------

var municipalBoundaries =
  ui.Map.FeatureViewLayer(
    'IBGE/MUNICIPIOS/V2025_FeatureView'
  );


municipalBoundaries.setVisParams({

  color:
    '666666',

  fillColor:
    '00000000',

  width:
    0.5

});


municipalBoundaries.setName(
  'IBGE Municipal Mesh 2025'
);


Map.add(
  municipalBoundaries
);


// ============================================================
// END
// ============================================================

print(
  '========================================'
);

print(
  'MUNICIPAL BATCH TASKS CREATED'
);

print(
  'Expected output rows:',
  5571
);

print(
  '1. EE FeatureCollection Asset'
);

print(
  '2. CSV without geometry'
);

print(
  'Municipal thematic map deferred to Script 06.'
);

print(
  '========================================'
);
