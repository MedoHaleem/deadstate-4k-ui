# Credits

## Essential tools

### [Untorque](https://github.com/figment/Untorque) — by **figment**

The single most important tool for this project. Untorque is a decompiler and
compiler for Torque3D / TGEA Script `.dso` files (DSO version 46). *Dead State* ships
all of its GUI layouts and font profiles as compiled `.dso` bytecode; without
Untorque there would be no way to read, edit, or recompile them.

**Every scaled GUI screen and every adjusted font profile** in this mod was:

1. Decompressed from the game's archives,
2. Decompiled to readable TorqueScript with `Untorque decompile`,
3. Edited (geometry/font values 2×-scaled),
4. Recompiled back to `.dso` with `Untorque compile`.

Many thanks to figment for releasing and maintaining this essential tool.

- **Project:** https://github.com/figment/Untorque

### [tcc](https://bellard.org/tcc/) — Tiny C Compiler

Used to compile the `d3d9` proxy DLL (`src/proxy/d3d9_proxy.c`) — the core-crash
fix. tcc is a small, fast C compiler that produces 32-bit Windows DLLs without a
full SDK install.

- **Project:** https://bellard.org/tcc/ (version 0.9.27, i386-win32)

### [Pillow](https://python-pillow.org/) — Python imaging library

Used by `src/scaling/gen_1800_textures.py` to 2×-upscale the texhandle textures
(Lanczos resampling) for the party panel, AP pips, and noise meter.

- **Project:** https://python-pillow.org/

### [7-Zip](https://www.7-zip.org/)

Used to update entries inside the game's `art/gui.aod` archive in place.

- **Project:** https://www.7-zip.org/

## Game

**Dead State** — developed by **DoubleBear Productions** and published by
Darklore Industries. This mod is an independent, non-commercial fan work and is
not affiliated with or endorsed by DoubleBear or Darklore. All game assets and
trademarks remain the property of their respective owners.
