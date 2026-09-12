#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
from pathlib import Path


REPO_SO32 = Path(__file__).resolve().parents[1]
SRC_DIR = REPO_SO32 / "src"

if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from prais_so32.population import (  # noqa: E402
    AGE_CLASSES,
    SEX_LABELS,
    build_sex_population,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Build one annual WorldPop female or male population raster "
            "from the 18 historical age-class GeoTIFFs."
        )
    )

    parser.add_argument(
        "--inventory",
        required=True,
        help=(
            "CSV produced by SO3.2-03 with year, sex, age_class, "
            "filename and URL."
        ),
    )

    parser.add_argument(
        "--remote-inventory",
        default=None,
        help=(
            "Optional SO3.2-04 remote inventory containing "
            "content_length_bytes for transfer validation."
        ),
    )

    parser.add_argument(
        "--year",
        required=True,
        type=int,
    )

    parser.add_argument(
        "--sex",
        required=True,
        choices=sorted(SEX_LABELS),
        help="'f' for female or 'm' for male.",
    )

    parser.add_argument(
        "--work-dir",
        required=True,
        help=(
            "Persistent temporary workspace. "
            "One source raster at a time is stored here."
        ),
    )

    parser.add_argument(
        "--output-dir",
        required=True,
        help="Directory for the persistent annual raster.",
    )

    parser.add_argument(
        "--log-dir",
        required=True,
        help="Directory for processing and QA CSV files.",
    )

    parser.add_argument(
        "--chunk-rows",
        type=int,
        default=128,
        help="Number of raster rows processed per block.",
    )

    parser.add_argument(
        "--nodata",
        type=float,
        default=-9999.0,
    )

    parser.add_argument(
        "--min-free-gb",
        type=float,
        default=15.0,
        help=(
            "Abort before a new source if the work filesystem "
            "has less free space than this threshold."
        ),
    )

    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Replace an existing final output.",
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate inputs and print the planned run without downloading.",
    )

    return parser.parse_args()


def main() -> int:
    args = parse_args()

    inventory = Path(args.inventory)

    if not inventory.exists():
        print(
            f"Inventory not found: {inventory}",
            file=sys.stderr,
        )
        return 2

    if args.dry_run:
        import pandas as pd

        table = pd.read_csv(inventory)

        selected = (
            table[
                (table["year"] == args.year)
                & (table["sex"] == args.sex)
            ]
            .sort_values("age_class")
        )

        observed = (
            selected["age_class"]
            .astype(int)
            .tolist()
        )

        print(
            f"Year: {args.year}"
        )
        print(
            f"Sex: {args.sex} ({SEX_LABELS[args.sex]})"
        )
        print(
            f"Files: {len(selected)}"
        )
        print(
            f"Age classes: {observed}"
        )
        print(
            f"Expected: {AGE_CLASSES}"
        )
        print(
            f"Work dir: {args.work_dir}"
        )
        print(
            f"Output dir: {args.output_dir}"
        )
        print(
            f"Log dir: {args.log_dir}"
        )

        return 0 if observed == AGE_CLASSES else 3

    result = build_sex_population(
        inventory_csv=args.inventory,
        remote_inventory_csv=args.remote_inventory,
        year=args.year,
        sex=args.sex,
        work_dir=args.work_dir,
        output_dir=args.output_dir,
        log_dir=args.log_dir,
        nodata=args.nodata,
        chunk_rows=args.chunk_rows,
        min_free_gb=args.min_free_gb,
        overwrite=args.overwrite,
    )

    print("\nRun summary")
    print("-----------")
    print(f"status : {result['status']}")
    print(f"output : {result['output']}")
    print(f"qa     : {result['qa']}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
