from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterator

import numpy as np
import rasterio
from rasterio.windows import Window


@dataclass(frozen=True)
class RasterGrid:
    width: int
    height: int
    crs: str | None
    transform: tuple[float, ...]
    bounds: tuple[float, float, float, float]


def grid_from_dataset(src: rasterio.io.DatasetReader) -> RasterGrid:
    return RasterGrid(
        width=src.width,
        height=src.height,
        crs=src.crs.to_string() if src.crs else None,
        transform=tuple(src.transform),
        bounds=(
            src.bounds.left,
            src.bounds.bottom,
            src.bounds.right,
            src.bounds.top,
        ),
    )


def assert_same_grid(
    reference: rasterio.io.DatasetReader,
    candidate: rasterio.io.DatasetReader,
) -> None:
    """Fail if two rasters do not share exactly the same working grid."""
    problems = []

    if reference.width != candidate.width:
        problems.append(
            f"width: {reference.width} != {candidate.width}"
        )

    if reference.height != candidate.height:
        problems.append(
            f"height: {reference.height} != {candidate.height}"
        )

    if reference.crs != candidate.crs:
        problems.append(
            f"crs: {reference.crs} != {candidate.crs}"
        )

    if not reference.transform.almost_equals(candidate.transform):
        problems.append(
            f"transform: {reference.transform} != {candidate.transform}"
        )

    if problems:
        raise ValueError(
            "Rasters are not on the same grid: "
            + "; ".join(problems)
        )


def row_windows(
    width: int,
    height: int,
    chunk_rows: int = 128,
) -> Iterator[Window]:
    """Yield full-width row windows to limit RAM usage."""
    if chunk_rows <= 0:
        raise ValueError("chunk_rows must be > 0")

    for row_off in range(0, height, chunk_rows):
        rows = min(chunk_rows, height - row_off)
        yield Window(
            col_off=0,
            row_off=row_off,
            width=width,
            height=rows,
        )


def population_output_profile(
    source: rasterio.io.DatasetReader,
    nodata: float = -9999.0,
) -> dict:
    """Standard profile for persistent annual population rasters."""
    profile = source.profile.copy()

    profile.update(
        driver="GTiff",
        count=1,
        dtype="float32",
        nodata=float(nodata),
        compress="DEFLATE",
        predictor=3,
        tiled=True,
        blockxsize=512,
        blockysize=512,
        BIGTIFF="YES",
        interleave="band",
    )

    return profile


def raster_stats(
    path: str | Path,
    chunk_rows: int = 128,
) -> dict:
    """Compute basic statistics without loading the full raster into RAM."""
    path = Path(path)

    valid_pixels = 0
    nodata_pixels = 0
    total_population = 0.0
    min_value = None
    max_value = None

    with rasterio.open(path) as src:
        for window in row_windows(
            src.width,
            src.height,
            chunk_rows=chunk_rows,
        ):
            arr = src.read(
                1,
                window=window,
                masked=True,
            )

            valid = arr.compressed()
            valid_pixels += int(valid.size)
            nodata_pixels += int(arr.size - valid.size)

            if valid.size:
                valid64 = valid.astype(
                    np.float64,
                    copy=False,
                )

                total_population += float(
                    valid64.sum(dtype=np.float64)
                )

                block_min = float(valid64.min())
                block_max = float(valid64.max())

                min_value = (
                    block_min
                    if min_value is None
                    else min(min_value, block_min)
                )

                max_value = (
                    block_max
                    if max_value is None
                    else max(max_value, block_max)
                )

        return {
            "path": str(path),
            "driver": src.driver,
            "width": src.width,
            "height": src.height,
            "bands": src.count,
            "dtype": src.dtypes[0],
            "crs": src.crs.to_string() if src.crs else None,
            "transform": str(src.transform),
            "nodata": src.nodata,
            "valid_pixels": valid_pixels,
            "nodata_pixels": nodata_pixels,
            "population_sum": total_population,
            "min": min_value,
            "max": max_value,
            "size_gb": path.stat().st_size / (1024 ** 3),
        }
