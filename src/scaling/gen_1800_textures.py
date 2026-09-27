#!/usr/bin/env python3
"""Regenerate the 54 _1800 (2x) texhandle texture variants plus the scaled
character-screen skill progress bitmap and stage them for injection into
art/gui.aod.

WHY THIS EXISTS
---------------
Several in-game HUD controls (party panel, AP pips, noise meter) use
`bitmap = "texhandle"` -- they don't load a texture file directly; instead the
engine (compiled in ZRPG.exe) loads a PNG and hands it to the control at runtime.
The engine's `getFittingRes()` picks the texture variant whose resolution suffix
(_NNN) is the largest value <= the canvas height. At 4K the internal canvas height
is 1800, so getFittingRes(base, 1800) selects a `_1800` file over the stock
`_1080`. By providing 2x-upscaled `_1800` PNGs, the texture -- and therefore the
control -- renders at 2x automatically. No script hook, no exe patch.

This script reads each stock `_1080.png` from art/gui.aod, 2x-upscales it with
Lanczos resampling (Pillow), and stages the `_1800.png` outputs. The character
screen's skill progress controls are also 2x-scaled by the GUI pass, but their
bitmap uses `wrap = 1` rather than `wrap = 0`; its source bitmap therefore has
to be upscaled in place or the engine tiles the 1x image across the 2x control.

PREREQUISITES
-------------
- pip install Pillow
- 7-Zip (for the injection step)

USAGE
-----
    python gen_1800_textures.py --game-dir "C:\\Path\\To\\Dead State"
    # then inject the staged files:
    #   cd <staging dir> && 7z u "<game>/art/gui.aod" panels text -spf -mx=1

The staging directory defaults to ./_zipstage next to this script; override with
--stage-dir.
"""
import argparse
import zipfile
import io
import os
import shutil
import sys

from PIL import Image  # type: ignore


def build_job_list():
    """The 54 texhandle texture families: party panel (4 sizes), AP digits
    (big+small, 0-9), noise meter (high/low/medium, 0-9)."""
    jobs = []
    for i in range(1, 5):
        jobs.append(f"panels/playgui/pg_party{i}")
    for d in range(0, 10):
        jobs.append(f"text/playgui/apdisplay/big_{d}")
        jobs.append(f"text/playgui/apdisplay/small_{d}")
    for lvl in ("high", "low", "medium"):
        for d in range(0, 10):
            jobs.append(f"text/playgui/noisemeter/n_{lvl}_{d}")
    return jobs


def main():
    default_game = r"C:\Program Files (x86)\Steam\steamapps\common\Dead State"
    default_stage = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_zipstage")

    ap = argparse.ArgumentParser(
        description="Generate 2x (_1800) texhandle and character-screen textures."
    )
    ap.add_argument("--game-dir", default=default_game,
                    help="Dead State install path (default: %(default)s)")
    ap.add_argument("--stage-dir", default=default_stage,
                    help="Where to write staged _1800 PNGs (default: %(default)s)")
    ap.add_argument("--factor", type=int, default=2,
                    help="Upscale factor (default: %(default)s)")
    args = ap.parse_args()

    aod = os.path.join(args.game_dir, "art", "gui.aod")
    if not os.path.isfile(aod):
        sys.exit(f"ERROR: art/gui.aod not found at {aod}")

    if os.path.exists(args.stage_dir):
        shutil.rmtree(args.stage_dir)

    jobs = build_job_list()
    # Tiled (wrap=1) bitmaps behind scaler-doubled extents. Wrapping tiles
    # rather than stretches, so leaving the source at 1x doubles the tile
    # count at 4K (the "double rows of tiny marks" bug on the skill screens).
    # Sources are read from the factory backup so rerunning the build never
    # upscales an already-upscaled in-place asset a second time.
    # Audit note: the only other wrap=1 bitmaps in loaded GUIs are flat
    # translucent shade scrims (black_semi_dark.png, shade.png) that tile
    # seamlessly -- visually identical at any tile count, left at 1x.
    fixed_jobs = [
        ("panels/CharScreen_Skill_Progress1080.png",
         "panels/CharScreen_Skill_Progress1080.png"),
        ("panels/CharCreationScreen_Skill_Progress900.png",
         "panels/CharCreationScreen_Skill_Progress900.png"),
        ("panels/CharCreationScreen_Skill_Cost_900.png",
         "panels/CharCreationScreen_Skill_Cost_900.png"),
    ]
    source_aod = aod
    backup_aod = aod + ".bak"
    if os.path.isfile(backup_aod):
        source_aod = backup_aod

    generated, missing = 0, []
    with zipfile.ZipFile(aod, "r") as z, zipfile.ZipFile(source_aod, "r") as source_z:
        for base in jobs:
            src = base + "_1080.png"
            try:
                src_bytes = z.read(src)
            except KeyError:
                missing.append(src)
                continue
            img = Image.open(io.BytesIO(src_bytes)).convert("RGBA")
            w, h = img.size
            img_up = img.resize((w * args.factor, h * args.factor), Image.LANCZOS)
            buf = io.BytesIO()
            img_up.save(buf, format="PNG")
            dst = os.path.join(args.stage_dir, (base + "_1800.png").replace("/", os.sep))
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            with open(dst, "wb") as f:
                f.write(buf.getvalue())
            generated += 1

        for src, dst_name in fixed_jobs:
            try:
                src_bytes = source_z.read(src)
            except KeyError:
                missing.append(src)
                continue
            img = Image.open(io.BytesIO(src_bytes)).convert("RGBA")
            w, h = img.size
            img_up = img.resize((w * args.factor, h * args.factor), Image.LANCZOS)
            buf = io.BytesIO()
            img_up.save(buf, format="PNG")
            dst = os.path.join(args.stage_dir, dst_name.replace("/", os.sep))
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            with open(dst, "wb") as f:
                f.write(buf.getvalue())
            generated += 1

    print(f"generated: {generated}   missing: {len(missing)}")
    for m in missing:
        print("   missing:", m)
    print("staged in:", args.stage_dir)
    if generated:
        rel = os.path.relpath(args.stage_dir, os.getcwd())
        print(f"\nNext step:  cd \"{rel}\" && 7z u \"{aod}\" panels text -spf -mx=1")


if __name__ == "__main__":
    main()
