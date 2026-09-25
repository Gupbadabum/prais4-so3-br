// ============================================================
// PRAIS4 / SO3.2
// QA - ALIGNED OUTPUTS
// Period: 2000-2003
//
// Purpose:
//   Confirm that all corrected annual and quadrennial rasters
//   use exactly the validated WorldPop grid.
//
// No exposure calculation is performed here.
// ============================================================


// ============================================================
// 0. EXPECTED WORLDPOP GRID
// ============================================================

var EXPECTED_WIDTH  = 54172;
var EXPECTED_HEIGHT = 46814;

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


// ============================================================
// 1. ASSETS TO CHECK
// ============================================================

var assets = [

  {
    label:
      'Annual 2000',

    id:
      'projects/cursoqueimadas-503722/assets/' +
      'exposure_total_annual/' +
      'exposure_total_2000_aligned'
  },

  {
    label:
      'Annual 2001',

    id:
      'projects/cursoqueimadas-503722/assets/' +
      'exposure_total_annual/' +
      'exposure_total_2001_aligned'
  },

  {
    label:
      'Annual 2002',

    id:
      'projects/cursoqueimadas-503722/assets/' +
      'exposure_total_annual/' +
      'exposure_total_2002_aligned'
  },

  {
    label:
      'Annual 2003',

    id:
      'projects/cursoqueimadas-503722/assets/' +
      'exposure_total_annual/' +
      'exposure_total_2003_aligned'
  },

  {
    label:
      'Quadrennial 2000-2003',

    id:
      'projects/cursoqueimadas-503722/assets/' +
      'exposure_total_quadrennial_2000_2003_aligned'
  }

];


// ============================================================
// 2. CLIENT-SIDE METADATA CHECK
// ============================================================

function sameTransform(a, b) {

  if (a.length !== b.length) {
    return false;
  }

  for (var i = 0; i < a.length; i++) {

    if (Math.abs(a[i] - b[i]) > 1e-12) {
      return false;
    }

  }

  return true;
}


assets.forEach(
  function(item) {

    var image =
      ee.Image(
        item.id
      );

    // Metadata only.
    var info =
      image.getInfo();

    var band =
      info.bands[0];

    var dimensions =
      band.dimensions;

    var transform =
      band.crs_transform;

    var crs =
      band.crs;


    var dimensionsOK =
      dimensions[0] === EXPECTED_WIDTH &&
      dimensions[1] === EXPECTED_HEIGHT;


    var crsOK =
      crs === EXPECTED_CRS;


    var transformOK =
      sameTransform(
        transform,
        EXPECTED_TRANSFORM
      );


    print(
      '========================================'
    );

    print(
      item.label
    );

    print(
      'Asset:',
      item.id
    );

    print(
      'Dimensions:',
      dimensions
    );

    print(
      'CRS:',
      crs
    );

    print(
      'Transform:',
      transform
    );

    print(
      'Dimensions OK:',
      dimensionsOK
    );

    print(
      'CRS OK:',
      crsOK
    );

    print(
      'Transform OK:',
      transformOK
    );

    print(
      'GRID OK:',
      dimensionsOK &&
      crsOK &&
      transformOK
    );

  }
);


// ============================================================
// END
// ============================================================

print(
  '========================================'
);

print(
  'Expected dimensions:',
  EXPECTED_WIDTH + 'x' + EXPECTED_HEIGHT
);

print(
  'Expected CRS:',
  EXPECTED_CRS
);

print(
  'Expected transform:',
  EXPECTED_TRANSFORM
);

print(
  '========================================'
);
