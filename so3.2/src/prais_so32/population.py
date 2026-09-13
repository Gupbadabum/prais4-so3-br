from __future__ import annotations

import os
import re
import shutil
import time
from pathlib import Path

import numpy as np
import pandas as pd
import rasterio
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from .raster import (
    assert_same_grid,
    population_output_profile,
    raster_stats,
    row_windows,
)


AGE_CLASSES = [
    0, 1, 5, 10, 15, 20, 25, 30, 35,
    40, 45, 50, 55, 60, 65, 70, 75, 80,
]

SEX_LABELS = {
    "f": "female",
    "m": "male",
}


def requests_session() -> requests.Session:
    retry = Retry(
        total=5,
        connect=5,
        read=5,
        status=5,
        backoff_factor=2.0,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=frozenset(["GET", "HEAD"]),
        raise_on_status=False,
    )

    adapter = HTTPAdapter(
        max_retries=retry,
        pool_connections=4,
        pool_maxsize=4,
    )

    session = requests.Session()
    session.headers.update({
        "User-Agent": (
            "PRAIS4-SO3.2-Brazil/1.0 "
            "(annual population construction)"
        )
    })
    session.mount("https://", adapter)
    session.mount("http://", adapter)

    return session


def _remote_size(
    session: requests.Session,
    url: str,
    timeout: int = 60,
) -> int | None:
    response = session.head(
        url,
        allow_redirects=True,
        timeout=timeout,
    )

    if response.status_code >= 400:
        return None

    length = response.headers.get("Content-Length")
    return int(length) if length is not None else None


def download_with_resume(
    url: str,
    destination: str | Path,
    expected_size: int | None = None,
    chunk_size: int = 16 * 1024 * 1024,
    timeout: int = 120,
    max_attempts: int = 8,
    retry_wait_seconds: int = 30,
) -> dict:
    """
    Download one source raster at a time.

    Interrupted downloads are retried automatically.

    If the remote server supports HTTP Range (206), an existing .part
    file is resumed. If the server ignores Range and returns 200, the
    incomplete file is discarded and the download restarts safely from
    byte zero.

    This behavior is necessary for WorldPop endpoints that advertise
    Accept-Ranges but do not actually honor Range requests.
    """
    destination = Path(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)

    partial = destination.with_suffix(
        destination.suffix + ".part"
    )

    session = requests_session()

    if expected_size is None:
        expected_size = _remote_size(
            session,
            url,
            timeout=timeout,
        )

    if destination.exists():
        local_size = destination.stat().st_size

        if (
            expected_size is None
            or local_size == expected_size
        ):
            return {
                "path": str(destination),
                "bytes": local_size,
                "seconds": 0.0,
                "resumed": False,
                "reused": True,
                "attempts": 0,
            }

        destination.unlink()

    total_start = time.perf_counter()
    last_error = None

    for attempt in range(1, max_attempts + 1):

        existing = (
            partial.stat().st_size
            if partial.exists()
            else 0
        )

        headers = {}

        if existing > 0:
            headers["Range"] = f"bytes={existing}-"

        print(
            f"    download attempt "
            f"{attempt}/{max_attempts}"
        )

        if existing > 0:
            print(
                f"    partial file detected: "
                f"{existing / (1024 ** 2):.1f} MB"
            )

        try:

            with session.get(
                url,
                headers=headers,
                stream=True,
                allow_redirects=True,
                timeout=timeout,
            ) as response:

                if response.status_code >= 400:
                    raise RuntimeError(
                        f"Download failed "
                        f"({response.status_code}): {url}"
                    )

                resumed = (
                    existing > 0
                    and response.status_code == 206
                )

                if existing > 0 and not resumed:

                    print(
                        "    server did not honor "
                        "HTTP Range; restarting "
                        "from byte zero"
                    )

                    partial.unlink(
                        missing_ok=True
                    )

                    existing = 0

                mode = (
                    "ab"
                    if resumed
                    else "wb"
                )

                with open(partial, mode) as file_obj:

                    for chunk in response.iter_content(
                        chunk_size=chunk_size
                    ):
                        if chunk:
                            file_obj.write(chunk)

            final_size = partial.stat().st_size

            if (
                expected_size is not None
                and final_size != expected_size
            ):
                raise RuntimeError(
                    "Downloaded file size does not "
                    "match the expected size: "
                    f"{final_size} != "
                    f"{expected_size} bytes for {url}"
                )

            os.replace(
                partial,
                destination,
            )

            elapsed = (
                time.perf_counter()
                - total_start
            )

            return {
                "path": str(destination),
                "bytes": final_size,
                "seconds": elapsed,
                "resumed": resumed,
                "reused": False,
                "attempts": attempt,
            }

        except (
            requests.exceptions.RequestException,
            RuntimeError,
        ) as exc:

            last_error = exc

            downloaded = (
                partial.stat().st_size
                if partial.exists()
                else 0
            )

            print(
                f"    download interrupted: "
                f"{type(exc).__name__}: {exc}"
            )

            print(
                f"    partial size: "
                f"{downloaded / (1024 ** 2):.1f} MB"
            )

            if attempt >= max_attempts:
                break

            wait_seconds = min(
                retry_wait_seconds
                * (2 ** (attempt - 1)),
                300,
            )

            print(
                f"    retrying in "
                f"{wait_seconds} seconds..."
            )

            time.sleep(
                wait_seconds
            )

    raise RuntimeError(
        f"Unable to download {url} after "
        f"{max_attempts} attempts. "
        f"Last error: {last_error}"
    )


def _write_first_source(
    source_path: Path,
    output_path: Path,
    nodata: float,
    chunk_rows: int,
) -> dict:
    """
    Normalize the first age raster into the accumulator format.
    """
    with rasterio.open(source_path) as src:
        if src.count != 1:
            raise ValueError(
                f"Expected one band in {source_path}; found {src.count}"
            )

        profile = population_output_profile(
            src,
            nodata=nodata,
        )

        valid_pixels = 0
        nodata_pixels = 0

        with rasterio.open(
            output_path,
            "w",
            **profile,
        ) as dst:

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

                mask = np.ma.getmaskarray(arr)

                out = np.where(
                    mask,
                    nodata,
                    arr.filled(0.0),
                ).astype(np.float32)

                dst.write(
                    out,
                    1,
                    window=window,
                )

                valid_pixels += int(
                    arr.size - mask.sum()
                )
                nodata_pixels += int(mask.sum())

    return {
        "valid_pixels": valid_pixels,
        "nodata_pixels": nodata_pixels,
        "mask_mismatch_pixels": 0,
    }


def _add_source(
    accumulator_path: Path,
    source_path: Path,
    output_path: Path,
    nodata: float,
    chunk_rows: int,
) -> dict:
    """
    Build a new accumulator rather than modifying the previous one in place.

    This copy-on-write approach means that an interrupted merge never corrupts
    the last completed accumulator.
    """
    valid_pixels = 0
    nodata_pixels = 0
    mask_mismatch_pixels = 0

    with rasterio.open(accumulator_path) as acc:
        with rasterio.open(source_path) as src:

            if acc.count != 1 or src.count != 1:
                raise ValueError(
                    "Accumulator and source must both have one band."
                )

            assert_same_grid(acc, src)

            profile = acc.profile.copy()
            profile.update(
                nodata=float(nodata),
                BIGTIFF="YES",
            )

            with rasterio.open(
                output_path,
                "w",
                **profile,
            ) as dst:

                for window in row_windows(
                    acc.width,
                    acc.height,
                    chunk_rows=chunk_rows,
                ):
                    acc_arr = acc.read(
                        1,
                        window=window,
                        masked=True,
                    )

                    src_arr = src.read(
                        1,
                        window=window,
                        masked=True,
                    )

                    acc_mask = np.ma.getmaskarray(
                        acc_arr
                    )

                    src_mask = np.ma.getmaskarray(
                        src_arr
                    )

                    mismatch = np.logical_xor(
                        acc_mask,
                        src_mask,
                    )

                    mismatch_count = int(
                        mismatch.sum()
                    )

                    if mismatch_count:
                        mask_mismatch_pixels += (
                            mismatch_count
                        )

                        raise ValueError(
                            "Population age rasters do not share "
                            "the same validity mask. "
                            f"Detected {mismatch_count} mismatched "
                            "pixels in the current processing window."
                        )

                    valid_mask = ~acc_mask

                    summed = (
                        acc_arr.filled(0.0).astype(
                            np.float64,
                            copy=False,
                        )
                        + src_arr.filled(0.0).astype(
                            np.float64,
                            copy=False,
                        )
                    )

                    out = np.where(
                        valid_mask,
                        summed,
                        nodata,
                    ).astype(np.float32)

                    dst.write(
                        out,
                        1,
                        window=window,
                    )

                    valid_pixels += int(
                        valid_mask.sum()
                    )

                    nodata_pixels += int(
                        acc_mask.sum()
                    )

    return {
        "valid_pixels": valid_pixels,
        "nodata_pixels": nodata_pixels,
        "mask_mismatch_pixels": mask_mismatch_pixels,
    }


def _checkpoint_index(run_dir: Path) -> int:
    pattern = re.compile(r"^acc_(\d{2})\.tif$")
    indices = []

    for path in run_dir.glob("acc_*.tif"):
        match = pattern.match(path.name)
        if match:
            indices.append(int(match.group(1)))

    return max(indices) if indices else 0


def _remove_stale_files(
    run_dir: Path,
    keep_checkpoint: int,
) -> None:
    for tmp in run_dir.glob("acc_*.tmp.tif"):
        tmp.unlink(missing_ok=True)

    for acc in run_dir.glob("acc_*.tif"):
        match = re.match(
            r"^acc_(\d{2})\.tif$",
            acc.name,
        )

        if match:
            index = int(match.group(1))

            if index < keep_checkpoint:
                acc.unlink(missing_ok=True)


def _expected_size_lookup(
    remote_inventory_csv: str | Path | None,
) -> dict[tuple[int, str, int], int]:
    if remote_inventory_csv is None:
        return {}

    path = Path(remote_inventory_csv)

    if not path.exists():
        raise FileNotFoundError(
            f"Remote inventory not found: {path}"
        )

    table = pd.read_csv(path)

    required = {
        "year",
        "sex",
        "age_class",
        "content_length_bytes",
    }

    missing = required - set(table.columns)

    if missing:
        raise ValueError(
            "Remote inventory is missing columns: "
            + ", ".join(sorted(missing))
        )

    lookup = {}

    for row in table.itertuples(index=False):
        value = getattr(
            row,
            "content_length_bytes",
        )

        if pd.notna(value):
            lookup[
                (
                    int(getattr(row, "year")),
                    str(getattr(row, "sex")),
                    int(getattr(row, "age_class")),
                )
            ] = int(value)

    return lookup


def build_sex_population(
    inventory_csv: str | Path,
    year: int,
    sex: str,
    work_dir: str | Path,
    output_dir: str | Path,
    log_dir: str | Path,
    remote_inventory_csv: str | Path | None = None,
    nodata: float = -9999.0,
    chunk_rows: int = 128,
    min_free_gb: float = 15.0,
    overwrite: bool = False,
) -> dict:
    """
    Build one annual female or male population raster.

    Exactly one WorldPop age raster is downloaded at a time. After the raster
    has been incorporated into a copy-on-write accumulator, the source file is
    removed.
    """
    sex = sex.lower()

    if sex not in SEX_LABELS:
        raise ValueError(
            "sex must be 'f' or 'm'"
        )

    label = SEX_LABELS[sex]

    inventory_csv = Path(inventory_csv)
    work_dir = Path(work_dir)
    output_dir = Path(output_dir)
    log_dir = Path(log_dir)

    if not inventory_csv.exists():
        raise FileNotFoundError(
            f"Inventory not found: {inventory_csv}"
        )

    work_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    output_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    log_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    final_output = (
        output_dir
        / f"population_{label}_{year}.tif"
    )

    qa_output = (
        log_dir
        / f"so32_05_population_{label}_{year}_qa.csv"
    )

    manifest_output = (
        log_dir
        / f"so32_05_population_{label}_{year}_processing.csv"
    )

    if final_output.exists() and not overwrite:
        stats = raster_stats(
            final_output,
            chunk_rows=chunk_rows,
        )

        pd.DataFrame([stats]).to_csv(
            qa_output,
            index=False,
        )

        return {
            "status": "already_exists",
            "output": str(final_output),
            "qa": str(qa_output),
            "stats": stats,
        }

    if overwrite:
        final_output.unlink(
            missing_ok=True
        )

    inventory = pd.read_csv(
        inventory_csv
    )

    required_columns = {
        "year",
        "sex",
        "age_class",
        "filename",
        "url",
    }

    missing_columns = (
        required_columns
        - set(inventory.columns)
    )

    if missing_columns:
        raise ValueError(
            "Inventory is missing columns: "
            + ", ".join(
                sorted(missing_columns)
            )
        )

    selected = (
        inventory[
            (inventory["year"] == year)
            & (inventory["sex"] == sex)
        ]
        .copy()
        .sort_values("age_class")
        .reset_index(drop=True)
    )

    observed_ages = (
        selected["age_class"]
        .astype(int)
        .tolist()
    )

    if observed_ages != AGE_CLASSES:
        raise ValueError(
            "Unexpected age-class structure. "
            f"Observed: {observed_ages}"
        )

    size_lookup = _expected_size_lookup(
        remote_inventory_csv
    )

    run_dir = (
        work_dir
        / f"{year}_{label}"
    )

    run_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    completed = _checkpoint_index(
        run_dir
    )

    _remove_stale_files(
        run_dir,
        keep_checkpoint=completed,
    )

    processing_rows = []

    if manifest_output.exists():
        try:
            processing_rows = (
                pd.read_csv(manifest_output)
                .to_dict("records")
            )
        except Exception:
            processing_rows = []

    print(
        f"Building {label} population for {year}"
    )

    print(
        f"Completed age rasters detected: "
        f"{completed}/{len(AGE_CLASSES)}"
    )

    for position, row in selected.iterrows():
        step = position + 1

        if step <= completed:
            continue

        free_gb = (
            shutil.disk_usage(run_dir).free
            / (1024 ** 3)
        )

        if free_gb < min_free_gb:
            raise RuntimeError(
                "Insufficient free disk space before "
                f"processing step {step}. "
                f"Available: {free_gb:.2f} GB; "
                f"minimum required: {min_free_gb:.2f} GB."
            )

        age_class = int(
            row["age_class"]
        )

        source_path = (
            run_dir
            / row["filename"]
        )

        expected_size = size_lookup.get(
            (
                int(year),
                sex,
                age_class,
            )
        )

        print(
            f"[{step:02d}/{len(AGE_CLASSES)}] "
            f"age={age_class}: downloading "
            f"{row['filename']}"
        )

        download = download_with_resume(
            row["url"],
            source_path,
            expected_size=expected_size,
        )

        next_tmp = (
            run_dir
            / f"acc_{step:02d}.tmp.tif"
        )

        next_final = (
            run_dir
            / f"acc_{step:02d}.tif"
        )

        next_tmp.unlink(
            missing_ok=True
        )

        t0 = time.perf_counter()

        if step == 1:
            merge_info = _write_first_source(
                source_path=source_path,
                output_path=next_tmp,
                nodata=nodata,
                chunk_rows=chunk_rows,
            )
        else:
            previous = (
                run_dir
                / f"acc_{step - 1:02d}.tif"
            )

            if not previous.exists():
                raise RuntimeError(
                    "Previous accumulator is missing: "
                    f"{previous}"
                )

            merge_info = _add_source(
                accumulator_path=previous,
                source_path=source_path,
                output_path=next_tmp,
                nodata=nodata,
                chunk_rows=chunk_rows,
            )

        merge_seconds = (
            time.perf_counter() - t0
        )

        os.replace(
            next_tmp,
            next_final,
        )

        if step > 1:
            previous = (
                run_dir
                / f"acc_{step - 1:02d}.tif"
            )

            previous.unlink(
                missing_ok=True
            )

        source_path.unlink(
            missing_ok=True
        )

        processing_rows.append({
            "year": year,
            "sex": sex,
            "sex_label": label,
            "step": step,
            "age_class": age_class,
            "filename": row["filename"],
            "url": row["url"],
            "download_bytes": download["bytes"],
            "download_seconds": download["seconds"],
            "download_resumed": download["resumed"],
            "download_reused": download["reused"],
            "merge_seconds": merge_seconds,
            **merge_info,
        })

        pd.DataFrame(
            processing_rows
        ).drop_duplicates(
            subset=["year", "sex", "step"],
            keep="last",
        ).sort_values(
            ["year", "sex", "step"]
        ).to_csv(
            manifest_output,
            index=False,
        )

        print(
            f"    completed | "
            f"download={download['seconds'] / 60:.1f} min | "
            f"merge={merge_seconds / 60:.1f} min"
        )

    latest = (
        run_dir
        / f"acc_{len(AGE_CLASSES):02d}.tif"
    )

    if not latest.exists():
        raise RuntimeError(
            "Final accumulator was not created."
        )

    if final_output.exists():
        final_output.unlink()

    shutil.move(
        str(latest),
        str(final_output),
    )

    stats = raster_stats(
        final_output,
        chunk_rows=chunk_rows,
    )

    stats.update({
        "year": year,
        "sex": sex,
        "sex_label": label,
        "age_classes": len(AGE_CLASSES),
        "nodata_standard": nodata,
    })

    pd.DataFrame([stats]).to_csv(
        qa_output,
        index=False,
    )

    # The work directory should now contain only harmless remnants, if any.
    for path in run_dir.glob("*.part"):
        path.unlink(missing_ok=True)

    print(
        f"Finished: {final_output}"
    )

    return {
        "status": "completed",
        "output": str(final_output),
        "qa": str(qa_output),
        "processing_manifest": str(
            manifest_output
        ),
        "stats": stats,
    }
