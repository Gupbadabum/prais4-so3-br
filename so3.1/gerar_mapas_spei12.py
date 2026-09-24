from __future__ import annotations

import argparse
from pathlib import Path

import geopandas as gpd
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from pyproj import Transformer
import rasterio
import xarray as xr
from matplotlib.colors import BoundaryNorm, ListedColormap
from rasterio.features import geometry_mask
from rasterio.mask import mask
from rasterio.transform import from_bounds
from rasterio.warp import calculate_default_transform, reproject, Resampling
from shapely.geometry import mapping
from shapely.ops import transform as shapely_transform
from shapely.geometry import shape


YEARS = range(2000, 2024)
INPUT_DIR = Path("/Volumes/KINGSTON/Dados/SPEI")
SHAPEFILE = Path("/Volumes/KINGSTON/Dados/Mapas/BR_UF_2020/BR_UF_2020.shp")
CRS_WGS84 = "EPSG:4326"
CRS_EQUAL_AREA = "EPSG:6933"
NODATA = 0

COLORS = ["#d73027", "#f46d43", "#fdae61", "#ffffbf", "#ffffff"]
LABELS = {
    1: "Seca extrema (<= -2)",
    2: "Seca severa (-1,5 a -1,99)",
    3: "Seca moderada (-1,0 a -1,49)",
    4: "Seca fraca (-0,01 a -0,99)",
    5: "Normal (>= 0)",
}


def classify(values: np.ndarray) -> np.ndarray:
    """Converte SPEI em classes 1-5; zero representa NoData."""
    result = np.zeros(values.shape, dtype=np.uint8)
    valid = np.isfinite(values)
    result[valid & (values <= -2.0)] = 1
    result[valid & (values > -2.0) & (values <= -1.5)] = 2
    result[valid & (values > -1.5) & (values <= -1.0)] = 3
    result[valid & (values > -1.0) & (values < 0.0)] = 4
    result[valid & (values >= 0.0)] = 5
    return result


def brazil_geometry() -> tuple[list[dict], gpd.GeoDataFrame]:
    states = gpd.read_file(SHAPEFILE).to_crs(CRS_WGS84)
    brazil = states.geometry.union_all()
    return [mapping(brazil)], states


def write_global(data: np.ndarray, transform, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with rasterio.open(
        path,
        "w",
        driver="GTiff",
        height=data.shape[0],
        width=data.shape[1],
        count=1,
        dtype="uint8",
        crs=CRS_WGS84,
        transform=transform,
        nodata=NODATA,
        compress="deflate",
        predictor=2,
    ) as dst:
        dst.write(data, 1)
        dst.update_tags(
            classification="1 extreme, 2 severe, 3 moderate, 4 weak, 5 normal",
            source="SPEI-12 December",
        )


def clip_brazil(global_path: Path, geometries: list[dict], output_path: Path) -> tuple[np.ndarray, object]:
    with rasterio.open(global_path) as src:
        clipped, transform = mask(src, geometries, crop=True, filled=True, nodata=NODATA)
        profile = src.profile.copy()
        profile.update(height=clipped.shape[1], width=clipped.shape[2], transform=transform)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with rasterio.open(output_path, "w", **profile) as dst:
            dst.write(clipped)
            dst.update_tags(country="Brazil", source="SPEI-12 December")
    return clipped[0], transform


def equal_area_statistics(data: np.ndarray, transform, geometries: list[dict]) -> tuple[dict[int, float], dict[str, float]]:
    height, width = data.shape
    destination_transform, destination_width, destination_height = calculate_default_transform(
        CRS_WGS84,
        CRS_EQUAL_AREA,
        width,
        height,
        *rasterio.transform.array_bounds(height, width, transform),
        resolution=10000,
    )
    projected = np.zeros((destination_height, destination_width), dtype=np.uint8)
    reproject(
        data,
        projected,
        src_transform=transform,
        src_crs=CRS_WGS84,
        dst_transform=destination_transform,
        dst_crs=CRS_EQUAL_AREA,
        src_nodata=NODATA,
        dst_nodata=NODATA,
        resampling=Resampling.nearest,
    )
    # Remove projected pixels outside the dissolved national boundary.
    to_equal_area = Transformer.from_crs(CRS_WGS84, CRS_EQUAL_AREA, always_xy=True).transform
    projected_geometries = [mapping(shapely_transform(to_equal_area, shape(geometry))) for geometry in geometries]
    projected_mask = geometry_mask(
        projected_geometries,
        out_shape=projected.shape,
        transform=destination_transform,
        invert=True,
    )
    projected[~projected_mask] = NODATA
    pixel_area_km2 = abs(destination_transform.a * destination_transform.e) / 1_000_000
    areas = {class_value: float(np.count_nonzero(projected == class_value) * pixel_area_km2) for class_value in range(1, 6)}
    total_area = float(np.count_nonzero(projected > 0) * pixel_area_km2)
    drought_area = float(np.count_nonzero((projected >= 1) & (projected <= 4)) * pixel_area_km2)
    return areas, {"total_land_area_km2": total_area, "drought_area_km2": drought_area}


def write_png(data: np.ndarray, transform, states: gpd.GeoDataFrame, year: int, path: Path) -> None:
    masked = np.ma.masked_where(data == NODATA, data)
    cmap = ListedColormap(COLORS)
    norm = BoundaryNorm([0.5, 1.5, 2.5, 3.5, 4.5, 5.5], cmap.N)
    bounds = rasterio.transform.array_bounds(data.shape[0], data.shape[1], transform)
    fig, ax = plt.subplots(figsize=(9, 8), dpi=180)
    ax.imshow(masked, cmap=cmap, norm=norm, extent=(bounds[0], bounds[2], bounds[1], bounds[3]), interpolation="none")
    states.boundary.plot(ax=ax, color="#555555", linewidth=0.25)
    ax.set_xlim(-74.5, -28.0)
    ax.set_ylim(-34.5, 6.0)
    ax.set_xlabel("Longitude")
    ax.set_ylabel("Latitude")
    ax.set_title(f"SPEI-12 em dezembro de {year}")
    handles = [plt.Rectangle((0, 0), 1, 1, color=COLORS[value - 1]) for value in range(1, 6)]
    ax.legend(handles, [LABELS[value] for value in range(1, 6)], title="Classe", loc="lower left", fontsize=8)
    ax.set_aspect("equal")
    fig.tight_layout()
    path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(path, bbox_inches="tight")
    plt.close(fig)


def process_year(year: int, geometries: list[dict], states: gpd.GeoDataFrame, output_dir: Path) -> tuple[dict, dict]:
    source = INPUT_DIR / f"ref_mon_spei_12_{year}.nc"
    if not source.exists():
        raise FileNotFoundError(f"NetCDF ausente: {source}")
    with xr.open_dataset(source) as dataset:
        december = dataset["spei"].sel(time=dataset.time.dt.month == 12).squeeze(drop=True)
        values = december.values.astype(np.float32)
        lon = dataset.lon.values
        lat = dataset.lat.values
    classified = classify(values)[::-1, :]
    transform = from_bounds(float(lon.min() - 0.05), float(lat.min() - 0.05), float(lon.max() + 0.05), float(lat.max() + 0.05), classified.shape[1], classified.shape[0])
    global_path = output_dir / "geotiff_global" / f"spei12_dezembro_{year}_global.tif"
    brazil_path = output_dir / "geotiff_brasil" / f"spei12_dezembro_{year}_brasil.tif"
    write_global(classified, transform, global_path)
    brazil_data, brazil_transform = clip_brazil(global_path, geometries, brazil_path)
    write_png(brazil_data, brazil_transform, states, year, output_dir / "png" / f"spei12_dezembro_{year}_brasil.png")
    areas, summary = equal_area_statistics(brazil_data, brazil_transform, geometries)
    valid_cells = int(np.count_nonzero(brazil_data > 0))
    drought_cells = int(np.count_nonzero((brazil_data >= 1) & (brazil_data <= 4)))
    summary.update(year=year, cellCount=drought_cells, total_land_cell_count=valid_cells)
    summary["drought_land_percentage"] = 100 * summary["drought_area_km2"] / summary["total_land_area_km2"]
    t1 = {"year": year, **{f"class_{value}_area_km2": areas[value] for value in range(1, 6)}}
    return t1, summary


def main() -> None:
    parser = argparse.ArgumentParser(description="Gera mapas e tabelas anuais de SPEI-12 em dezembro.")
    parser.add_argument("--output-dir", type=Path, default=Path("resultados_spei12"))
    args = parser.parse_args()
    geometries, states = brazil_geometry()
    t1_rows, t2_rows = [], []
    for year in YEARS:
        print(f"Processando {year}...", flush=True)
        t1, t2 = process_year(year, geometries, states, args.output_dir)
        t1_rows.append(t1)
        t2_rows.append(t2)
    pd.DataFrame(t1_rows).to_csv(args.output_dir / "T1_area_por_classe_km2.csv", index=False, encoding="utf-8-sig")
    pd.DataFrame(t2_rows).to_csv(args.output_dir / "T2_percentual_terra_em_seca.csv", index=False, encoding="utf-8-sig")
    print(f"Concluído. Resultados em: {args.output_dir.resolve()}")


if __name__ == "__main__":
    main()