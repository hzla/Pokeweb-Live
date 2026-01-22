#!/usr/bin/env python3
"""
Batch remove background from PNGs by sampling the top-left pixel (0,0)
and making all pixels "close enough" to that color transparent.

- Does NOT preserve palette (outputs RGBA PNG).
- Supports tolerance (per-channel or Euclidean distance).
- Can process a folder (optionally recursive) and mirror structure into output.

Requires: pillow
  pip install pillow
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path
from typing import Tuple

from PIL import Image


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser(
        description="Remove background by top-left pixel color with tolerance."
    )
    ap.add_argument("input", type=str, help="Input file or directory")
    ap.add_argument("output", type=str, help="Output directory (or output file if input is a file)")
    ap.add_argument(
        "--recursive", "-r", action="store_true",
        help="If input is a directory, search recursively for images"
    )
    ap.add_argument(
        "--glob", type=str, default="*.png",
        help="Glob pattern when input is a directory (default: *.png)"
    )
    ap.add_argument(
        "--tol", type=int, default=0,
        help="Tolerance. Meaning depends on --mode. Default: 0 (exact match)."
    )
    ap.add_argument(
        "--mode", choices=["per_channel", "euclidean"], default="per_channel",
        help=(
            "Tolerance mode:\n"
            "  per_channel: abs(R-R0)<=tol AND abs(G-G0)<=tol AND abs(B-B0)<=tol\n"
            "  euclidean: sqrt((dR)^2+(dG)^2+(dB)^2) <= tol\n"
            "Default: per_channel"
        )
    )
    ap.add_argument(
        "--include-alpha", action="store_true",
        help="Also compare alpha to the sampled pixel (rarely needed)."
    )
    ap.add_argument(
        "--only-if-opaque", action="store_true",
        help="Only remove if the pixel is fully opaque (a==255). Prevents nuking existing transparency."
    )
    ap.add_argument(
        "--dry-run", action="store_true",
        help="Print what would be processed without writing files."
    )
    return ap.parse_args()


def list_inputs(inp: Path, recursive: bool, pattern: str) -> list[Path]:
    if inp.is_file():
        return [inp]
    if inp.is_dir():
        if recursive:
            return sorted(inp.rglob(pattern))
        return sorted(inp.glob(pattern))
    raise FileNotFoundError(f"Input not found: {inp}")


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def dist_euclidean(a: Tuple[int, int, int], b: Tuple[int, int, int]) -> int:
    dr = a[0] - b[0]
    dg = a[1] - b[1]
    db = a[2] - b[2]
    return int((dr * dr + dg * dg + db * db) ** 0.5)


def should_clear(
    px_rgba: Tuple[int, int, int, int],
    bg_rgba: Tuple[int, int, int, int],
    tol: int,
    mode: str,
    include_alpha: bool,
    only_if_opaque: bool,
) -> bool:
    r, g, b, a = px_rgba
    br, bg, bb, ba = bg_rgba

    if only_if_opaque and a != 255:
        return False

    if mode == "per_channel":
        if abs(r - br) > tol or abs(g - bg) > tol or abs(b - bb) > tol:
            return False
        if include_alpha and abs(a - ba) > tol:
            return False
        return True

    # euclidean
    if dist_euclidean((r, g, b), (br, bg, bb)) > tol:
        return False
    if include_alpha and abs(a - ba) > tol:
        return False
    return True


def process_one(
    in_path: Path,
    out_path: Path,
    tol: int,
    mode: str,
    include_alpha: bool,
    only_if_opaque: bool,
    dry_run: bool,
) -> None:
    if dry_run:
        print(f"[dry-run] {in_path} -> {out_path}")
        return

    img = Image.open(in_path).convert("RGBA")
    bg = img.getpixel((0, 0))  # (r,g,b,a)

    # Fast-ish: operate on the flattened pixel list once
    pixels = list(img.getdata())
    out_pixels = []

    cleared = 0
    for px in pixels:
        if should_clear(px, bg, tol, mode, include_alpha, only_if_opaque):
            out_pixels.append((0, 0, 0, 0))
            cleared += 1
        else:
            out_pixels.append(px)

    img.putdata(out_pixels)
    ensure_parent(out_path)
    img.save(out_path, format="PNG")

    print(f"{in_path.name}: bg={bg} tol={tol} mode={mode} cleared={cleared}/{len(pixels)}")


def main() -> None:
    args = parse_args()
    inp = Path(args.input)
    out = Path(args.output)

    files = list_inputs(inp, args.recursive, args.glob)

    if not files:
        print("No input files found.")
        return

    # If input is a single file, output may be a file path; otherwise output is a directory
    input_is_file = inp.is_file()
    if input_is_file:
        if out.suffix.lower() != ".png" and out.exists() and out.is_dir():
            # output given as dir
            out_path = out / inp.name
        elif out.suffix.lower() == ".png":
            out_path = out
        else:
            # output given as dir that may not exist yet
            if str(out).endswith(os.sep) or out.suffix == "":
                out_path = out / inp.name
            else:
                out_path = out
        process_one(
            inp, out_path, args.tol, args.mode, args.include_alpha,
            args.only_if_opaque, args.dry_run
        )
        return

    # Directory mode: mirror structure relative to input dir
    out.mkdir(parents=True, exist_ok=True)
    base = inp.resolve()

    for f in files:
        if not f.is_file():
            continue
        rel = f.resolve().relative_to(base)
        out_path = out / rel
        process_one(
            f, out_path, args.tol, args.mode, args.include_alpha,
            args.only_if_opaque, args.dry_run
        )


if __name__ == "__main__":
    main()
