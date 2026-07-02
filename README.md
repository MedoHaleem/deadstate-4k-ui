# Dead State — 4K UI Scaling Mod

This is the **source repository** for a mod that makes the entire *Dead State* UI
readable at 3840×2160 (4K), and fixes the multi-core launch crash on modern CPUs.

The game (built on the Torque Game Engine Advanced, TGEA) authors every screen at
1920×1080. This mod 2×-scales all UI geometry, fonts, and key textures so they
render correctly at 4K, and ships a small proxy DLL that prevents the engine from
crashing on machines with more than four CPU cores.

> **Looking for the downloadable mod?** The prebuilt release (a ZIP you copy into
> your game folder) is hosted on **Nexus Mods**. This repo holds the full source
> code and build scripts so the mod can be reviewed and rebuilt from scratch.

---

## What the mod does

1. **2× UI scaling** — fonts, control positions/extents, and panels across ~60 GUI
   screens (dialogue, character/inventory/map/loot screens, message boxes, the
   pause menu, options, etc.).
2. **54 high-resolution texture variants** (`_1800`) for the in-game HUD elements
   driven by the engine's "texhandle" mechanism (party panel, AP pips, noise meter).
3. **>4-core launch crash fix** — a 2 KB proxy `d3d9.dll` that caps process affinity
   to cores 0–3 before the engine's crashing CPU-enumeration code runs. Works on any
   launch path (Steam, shortcut, or the exe directly).
4. **4 GB Large Address Aware patch** on `ZRPG.exe` for stability with larger
   textures.

See [`docs/TECHNICAL.md`](docs/TECHNICAL.md) for the engine internals behind each fix.

---

## Repository contents

| Path | What it is |
|---|---|
| [`src/proxy/`](src/proxy/) | C source for the `d3d9` proxy DLL (the core-crash fix) + a load test. |
| [`src/scaling/`](src/scaling/) | The scaling engine: GUI layout scaler, texture generator, and the LAA patcher. |
| [`build/build.ps1`](build/build.ps1) | One-shot orchestrator that rebuilds the whole mod from a stock install. |
| [`build/d3d9.dll`](build/d3d9.dll) | Prebuilt proxy DLL (2 KB — the only committed binary; rebuildable from source). |
| [`docs/BUILD.md`](docs/BUILD.md) | How to build everything from source (prerequisites + step-by-step). |
| [`docs/TECHNICAL.md`](docs/TECHNICAL.md) | Engine/reverse-engineering notes: why each fix is needed and how it works. |
| [`release/README.md`](release/README.md) | The end-user install guide shipped inside the mod ZIP. |

**This repo does not contain any game assets.** No `.dso`, no `gui.aod`, no
decompiled game code, no game binaries (other than the rebuildable 2 KB proxy).
Everything is regenerated from *your own* game install by the build scripts.
See [`LICENSE`](LICENSE) for the copyright notice.

---

## Quick start (build from source)

Prerequisites: a clean *Dead State* install, [Untorque](https://github.com/figment/Untorque),
[tcc](https://bellard.org/tcc/) (optional, for rebuilding the proxy), 7-Zip, Python
3 + Pillow. See [`docs/BUILD.md`](docs/BUILD.md) for download links and full steps.

```powershell
./build/build.ps1 `
    -GameDir  "C:\Program Files (x86)\Steam\steamapps\common\Dead State" `
    -Untorque "C:\tools\Untorque.exe" `
    -Tcc      "C:\tools\tcc\tcc.exe"
```

---

## Credits

This mod would not exist without **[Untorque](https://github.com/figment/Untorque)**
by **figment** — the Torque3D Script DSO decompiler/compiler. Every scaled GUI and
font profile was decompiled from the game's compiled `.dso` files, edited, and
recompiled with it. See [`CREDITS.md`](CREDITS.md) for the full toolchain attribution.

## License

MIT — see [`LICENSE`](LICENSE). Covers only this repository's original code and
scripts. *Dead State* and all its assets are property of DoubleBear Productions.
