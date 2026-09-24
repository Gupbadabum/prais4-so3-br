from __future__ import annotations

import argparse
from pathlib import Path

import geopandas as gpd
import matplotlib.pyplot as plt
import numpy as np
import rasterio
from matplotlib.colors import BoundaryNorm, ListedColormap
from matplotlib.patches import Rectangle
from rasterio.mask import mask
from rasterio.transform import array_bounds
from shapely.geometry import mapping


PERIODS = ((2000, 2003), (2004, 2007), (2008, 2011), (2012, 2015), (2016, 2019), (2020, 2023))
CRS_WGS84 = "EPSG:4326"
NODATA = 0
COLORS = ["#d73027", "#f46d43", "#fdae61", "#ffffbf", "#ffffff"]
LABELS = {
    1: "Seca extrema (<= -2)",
    2: "Seca severa (-1,5 a -1,99)",
    3: "Seca moderada (-1,0 a -1,49)",
    4: "Seca fraca (-0,01 a -0,99)",
    5: "Normal (>= 0)",
}


def brazil_geometry(shapefile: Path) -> tuple[list[dict], gpd.GeoDataFrame]:
    states = gpd.read_file(shapefile).to_crs(CRS_WGS84)
    brazil = states.geometry.union_all()
    return [mapping(brazil)], states


def annual_path(input_dir: Path, year: int) -> Path:
    return input_dir / f"spei12_dezembro_{year}_global.tif"


def period_minimum(input_dir: Path, start_year: int, end_year: int) -> tuple[np.ndarray, dict]:
    paths = [annual_path(input_dir, year) for year in range(start_year, end_year + 1)]
    missing = [path for path in paths if not path.exists()]
    if missing:
        raise FileNotFoundError(f"GeoTIFF(s) anual(is) ausente(s): {', '.join(map(str, missing))}")

    with rasterio.open(paths[0]) as source:
        first_data = source.read(1)
        minimum = np.full(first_data.shape, 6, dtype=np.uint8)
        profile = source.profile.copy()
        reference_transform = source.transform
        reference_crs = source.crs
        valid = first_data != NODATA
        minimum[valid] = first_data[valid]

    for path in paths[1:]:
        with rasterio.open(path) as source:
            data = source.read(1)
            if data.shape != minimum.shape or source.transform != reference_transform or source.crs != reference_crs:
                raise ValueError(f"Grade incompatível no arquivo: {path}")
            valid = data != NODATA
            minimum[valid] = np.minimum(minimum[valid], data[valid])

    minimum[minimum == 6] = NODATA
    return minimum, profile


def write_geotiff(data: np.ndarray, profile: dict, path: Path, start_year: int, end_year: int) -> None:
    output_profile = profile.copy()
    output_profile.update(
        driver="GTiff",
        count=1,
        dtype="uint8",
        nodata=NODATA,
        compress="deflate",
        predictor=2,
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    with rasterio.open(path, "w", **output_profile) as destination:
        destination.write(data, 1)
        destination.update_tags(
            classification="1 extreme, 2 severe, 3 moderate, 4 weak, 5 normal",
            aggregation="minimum class per pixel",
            period=f"{start_year}-{end_year}",
            source="SPEI-12 December annual classified GeoTIFFs",
        )


def clip_brazil(global_path: Path, geometries: list[dict], output_path: Path) -> tuple[np.ndarray, object, dict]:
    with rasterio.open(global_path) as source:
        clipped, transform = mask(source, geometries, crop=True, filled=True, nodata=NODATA)
        profile = source.profile.copy()
        profile.update(height=clipped.shape[1], width=clipped.shape[2], transform=transform)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with rasterio.open(output_path, "w", **profile) as destination:
        destination.write(clipped)
        destination.update_tags(country="Brazil")
    return clipped[0], transform, profile


def write_png(
    data: np.ndarray,
    transform,
    states: gpd.GeoDataFrame,
    title: str,
    path: Path,
    brazil_only: bool,
) -> None:
    masked = np.ma.masked_where(data == NODATA, data)
    cmap = ListedColormap(COLORS)
    norm = BoundaryNorm([0.5, 1.5, 2.5, 3.5, 4.5, 5.5], cmap.N)
    bounds = array_bounds(data.shape[0], data.shape[1], transform)
    fig, ax = plt.subplots(figsize=(9, 8), dpi=180)
    ax.imshow(
        masked,
        cmap=cmap,
        norm=norm,
        extent=(bounds[0], bounds[2], bounds[1], bounds[3]),
        interpolation="none",
    )
    if brazil_only:
        states.boundary.plot(ax=ax, color="#555555", linewidth=0.25)
        ax.set_xlim(-74.5, -28.0)
        ax.set_ylim(-34.5, 6.0)
    else:
        ax.set_xlim(-180, 180)
        ax.set_ylim(-90, 90)
    ax.set_xlabel("Longitude")
    ax.set_ylabel("Latitude")
    ax.set_title(title)
    handles = [Rectangle((0, 0), 1, 1, color=COLORS[value - 1]) for value in range(1, 6)]
    ax.legend(handles, [LABELS[value] for value in range(1, 6)], title="Classe", loc="lower left", fontsize=8)
    ax.set_aspect("equal")
    fig.tight_layout()
    path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(path, bbox_inches="tight")
    plt.close(fig)


def process_period(
    input_dir: Path,
    output_dir: Path,
    geometries: list[dict],
    states: gpd.GeoDataFrame,
    start_year: int,
    end_year: int,
) -> None:
    period = f"{start_year}_{end_year}"
    print(f"Processando {start_year}-{end_year}...", flush=True)
    data, profile = period_minimum(input_dir, start_year, end_year)
    global_path = output_dir / "geotiff_global" / f"spei12_maximo_{period}_global.tif"
    brazil_path = output_dir / "geotiff_brasil" / f"spei12_maximo_{period}_brasil.tif"
    write_geotiff(data, profile, global_path, start_year, end_year)
    brazil_data, brazil_transform, _ = clip_brazil(global_path, geometries, brazil_path)
    title = f"SPEI-12: máxima intensidade de seca ({start_year}-{end_year})"
    write_png(data, profile["transform"], states, title, output_dir / "png_global" / f"spei12_maximo_{period}_global.png", False)
    write_png(brazil_data, brazil_transform, states, title, output_dir / "png_brasil" / f"spei12_maximo_{period}_brasil.png", True)


def main() -> None:
    parser = argparse.ArgumentParser(description="Gera mapas de máxima intensidade de seca em períodos de quatro anos.")
    parser.add_argument("--input-dir", type=Path, default=Path("resultados_spei12/geotiff_global"))
    parser.add_argument("--output-dir", type=Path, default=Path("resultados_spei12_maximos_4anos"))
    parser.add_argument(
        "--shapefile",
        type=Path,
        default=Path("/Volumes/KINGSTON/Dados/Mapas/BR_UF_2020/BR_UF_2020.shp"),
    )
    args = parser.parse_args()
    geometries, states = brazil_geometry(args.shapefile)
    for start_year, end_year in PERIODS:
        process_period(args.input_dir, args.output_dir, geometries, states, start_year, end_year)
    print(f"Concluído. Resultados em: {args.output_dir.resolve()}")


if __name__ == "__main__":
    main()
