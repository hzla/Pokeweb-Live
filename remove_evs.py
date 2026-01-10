#!/usr/bin/env python3
"""
Remove all Pokémon EV yields from the personal NARC in Pokémon BW / B2W2.

- Input: .nds ROM (Black/White or Black2/White2)
- Edits: a/0/1/6 (personal NARC)
- Change: sets the 2-byte "evs" field to 0x0000 for every entry
- Output: writes a new ROM file (does not overwrite unless you pass --inplace)

Requires: ndspy
    pip install ndspy
"""

from __future__ import annotations

import argparse
import os
import sys

import ndspy.rom
import ndspy.narc


PERSONAL_NARC_PATH = "a/0/1/6"

# Given format:
# [1 base_hp, 1 base_atk, 1 base_def, 1 base_speed, 1 base_spatk, 1 base_spdef] => 6
# [1 type_1, 1 type_2] => +2 = 8
# [1 catchrate] => +1 = 9
# [1 stage] => +1 = 10
# [2 evs] starts at offset 10, length 2
EVS_OFFSET = 10
EVS_LENGTH = 2


def get_file_by_name(rom: ndspy.rom.NintendoDSRom, path: str) -> bytes:
    """Robustly read a ROM file by name across ndspy versions."""
    # Newer ndspy typically supports getFileByName / setFileByName.
    if hasattr(rom, "getFileByName"):
        try:
            return rom.getFileByName(path)
        except Exception:
            pass

    # Fallback: use filename table -> file id -> rom.files[file_id]
    if getattr(rom, "filenames", None) is None:
        raise RuntimeError("ROM has no filename table; cannot access file by name.")

    try:
        file_id = rom.filenames.idOf(path)
    except Exception as e:
        raise FileNotFoundError(f"Could not find '{path}' in ROM filenames table.") from e

    try:
        return rom.files[file_id]
    except Exception as e:
        raise RuntimeError(f"Found '{path}' as file id {file_id}, but could not read rom.files[{file_id}].") from e


def set_file_by_name(rom: ndspy.rom.NintendoDSRom, path: str, data: bytes) -> None:
    """Robustly write a ROM file by name across ndspy versions."""
    if hasattr(rom, "setFileByName"):
        try:
            rom.setFileByName(path, data)
            return
        except Exception:
            pass

    if getattr(rom, "filenames", None) is None:
        raise RuntimeError("ROM has no filename table; cannot set file by name.")

    try:
        file_id = rom.filenames.idOf(path)
    except Exception as e:
        raise FileNotFoundError(f"Could not find '{path}' in ROM filenames table.") from e

    if file_id < 0 or file_id >= len(rom.files):
        raise RuntimeError(f"Bad file id for '{path}': {file_id} (rom.files length={len(rom.files)})")

    rom.files[file_id] = data


def zero_personal_evs(narc_data: bytes) -> tuple[bytes, int, int]:
    """
    Parse the NARC, zero the EV-yield field for every entry, and rebuild.

    Returns: (new_narc_bytes, num_entries, num_modified)
    """
    narc = ndspy.narc.NARC(narc_data)

    modified = 0
    for i, entry in enumerate(narc.files):
        # entry is bytes-like
        b = bytearray(entry)
        if len(b) < EVS_OFFSET + EVS_LENGTH:
            # Unexpected entry size; skip safely
            continue

        if b[EVS_OFFSET:EVS_OFFSET + EVS_LENGTH] != b"\x00\x00":
            modified += 1
        b[EVS_OFFSET:EVS_OFFSET + EVS_LENGTH] = b"\x00\x00"
        narc.files[i] = bytes(b)

    return narc.save(), len(narc.files), modified


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Zero EV yields in BW/B2W2 personal NARC (a/0/1/6) using ndspy."
    )
    ap.add_argument("rom", help="Path to input .nds ROM (BW or B2W2).")
    ap.add_argument(
        "-o",
        "--out",
        default=None,
        help="Output ROM path. Default: <input>_no_evs.nds",
    )
    ap.add_argument(
        "--inplace",
        action="store_true",
        help="Overwrite the input ROM (DANGEROUS). If set, --out is ignored.",
    )
    args = ap.parse_args()

    rom_path = args.rom
    if not os.path.isfile(rom_path):
        print(f"ERROR: ROM not found: {rom_path}", file=sys.stderr)
        return 2

    out_path = rom_path
    if not args.inplace:
        if args.out:
            out_path = args.out
        else:
            base, ext = os.path.splitext(rom_path)
            out_path = f"{base}_no_evs{ext or '.nds'}"

    try:
        rom = ndspy.rom.NintendoDSRom.fromFile(rom_path)
    except Exception as e:
        print(f"ERROR: Failed to load ROM with ndspy: {e}", file=sys.stderr)
        return 2

    try:
        personal_narc_bytes = get_file_by_name(rom, PERSONAL_NARC_PATH)
    except Exception as e:
        print(f"ERROR: Failed to read '{PERSONAL_NARC_PATH}' from ROM: {e}", file=sys.stderr)
        return 2

    try:
        new_narc_bytes, num_entries, num_modified = zero_personal_evs(personal_narc_bytes)
    except Exception as e:
        print(f"ERROR: Failed to parse/edit NARC '{PERSONAL_NARC_PATH}': {e}", file=sys.stderr)
        return 2

    try:
        set_file_by_name(rom, PERSONAL_NARC_PATH, new_narc_bytes)
    except Exception as e:
        print(f"ERROR: Failed to write edited NARC back into ROM: {e}", file=sys.stderr)
        return 2

    try:
        rom.saveToFile(out_path)
    except Exception as e:
        print(f"ERROR: Failed to save output ROM '{out_path}': {e}", file=sys.stderr)
        return 2

    print(f"OK: Edited {PERSONAL_NARC_PATH}")
    print(f"Entries: {num_entries}")
    print(f"EV fields modified (nonzero -> zeroed): {num_modified}")
    print(f"Output ROM: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
