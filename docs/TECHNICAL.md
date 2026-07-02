# Technical notes

How and why each part of the mod works. Written for reviewers and anyone who wants
to understand the engine internals. (These notes are distilled from the project's
working document; local install paths and ephemeral diagnostics have been removed.)

---

## Engine

*Dead State* runs on **TGEA** (Torque Game Engine Advanced), DSO version 46
(Torque3D 3.5-era). The game ships its scripts and GUIs as compiled `.dso` bytecode
inside ZIP-like archives with a `.aod` extension:

- `art/gui.aod` — all GUI layout files (`.gui.dso`), font profiles, panel/portrait/
  button PNGs, and in-game text graphics.
- `scripts.aod` — gameplay scripts.
- `core/art/gui/*.dso` — engine-level profiles and the Options dialog (loose files).

A few GUIs exist as **loose `.gui.dso` files** in `art/gui/` *in addition to* their
entries inside `gui.aod`. The engine loads the **loose file** and it overrides the
ZIP entry — so for those ~12 GUIs, editing only the ZIP is a no-op. This matters
during install (loose files must be updated directly).

---

## 1. Font / profile scaling

Every on-screen text size is governed by a **GuiControlProfile**. The game has two
profile sources:

- **Engine profiles** (`core/art/gui/profiles.cs.dso`, loose): ~50 profiles
  (`GuiDefaultProfile`, `GuiTextProfile`, `GuiButtonProfile`, …).
- **Game profiles** (`gameProfiles.english.cs.dso`, inside `gui.aod`): ~130
  game-specific profiles (SegoePrint, Sapphire, RTS, …).

Scaling is straightforward: decompile each `.dso` with Untorque, then double the
`fontSize`, `textOffset`, and `borderThickness` fields (`14→28`, `16→32`, `18→36`,
`20→40`, `24→48`, `36→72`, etc.), and dynamic expressions like
`$platform $= "macos" ? 13 : 12` → `? 26 : 24`. Recompile and replace.

**Gotcha:** Torque uses the *last* assignment when a field appears twice in one
block. When patching, remove the original line rather than appending a duplicate —
otherwise the leftover original value wins.

---

## 2. GUI layout scaling

Each `.gui.dso` defines a tree of controls with `position`, `extent`, and
`minExtent` fields, authored for 1920×1080. The scaler (`scale_guis.ps1`):

1. Extracts each `.gui.dso` from the factory `gui.aod.bak`.
2. Decompiles it to TorqueScript.
3. 2×-scales every `position`/`extent`/`minExtent` via regex.
4. Recompiles and stages it for injection.

Two engine quirks are handled:

- **Resolution variants.** Some GUIs ship `_768`, `_900`, and `_1080` variants; at
  4K the engine loads `_1080` (closest available). `_768`/`_900` are skipped.
- **`texhandle` controls** (next section).

---

## 3. The "texhandle" mechanism

Some HUD controls use `bitmap = "texhandle"`. This tells `GuiBitmapCtrl::setBitmap`
to *clear* its file texture and accept one supplied externally by engine code.
The texture is loaded from a PNG by the engine via `getFittingRes()` — a resolution-
fitting function that searches for files named `<base>_<NNN>.png` and picks the one
whose `NNN` is the **largest value ≤ the internal canvas height**.

> **The canvas height is 1800 at 4K**, not 2160. (The engine's own canvas behavior
> at this display mode; an internal detail, not a wrapper artifact.) So
> `getFittingRes(base, 1800)` rejects a `_2160` file and selects `_1080` by default.

**Key insight: the texture sizes the control.** When a 2× texture is loaded, the
control's extent auto-becomes 2×. So the fix is to provide higher-resolution PNG
variants — `getFittingRes(base, 1800)` will pick a `_1800` file over `_1080`, and
the 2× texture drives the control to 2×. No script hook, no enforcer, no exe patch.

`gen_1800_textures.py` generates the 54 `_1800` variants (2× Lanczos upscale of the
stock `_1080` PNGs) for three HUD families: the party panel (4 sizes), AP digits
(big + small, 0–9), and the noise meter (high/low/medium, 0–9).

**What did NOT work** (documented for completeness): a TorqueScript package that
polled and called `setExtent()` on texhandle controls — `setExtent` resizes the
control box but cannot resize the texture (the texture drives the box, not the
reverse). And `_2160`-suffixed textures are never selected because 2160 > 1800.

---

## 4. The >4-core launch crash

### The bug

On systems with more than four logical processors, `ZRPG.exe` crashes during early
engine init **before any script runs** — so it cannot be fixed via TorqueScript.

Root cause: the TGEA processor-enumeration code loops once per logical CPU,
appending a formatted per-core string into a **fixed-size global buffer**. With many
cores (e.g. 32), the loop overflows that buffer, corrupting adjacent `.data`, and
the next pointer store hits a corrupted address → access violation. The crash
happens before `console.log` is even opened.

### Approaches considered

1. **`/affinity 0F` launch flag** (the original community workaround). Works, but
   only when the game is launched *through* a wrapper batch file — launching the exe
   directly, via Steam, or via a shortcut still crashes.
2. **Binary-patching `ZRPG.exe`** to cap the enumerator loop at 4. Fixed the launch
   crash but introduced a **freeze on quit** (the patched thread-pool stored a
   worker count inconsistent with the workers actually created, deadlocking
   shutdown). Reverted.
3. **Proxy `d3d9.dll`** (the final fix). Same effect as the affinity flag, but
   intrinsic to any launch path, and the exe stays clean so quit works.

### The proxy DLL fix

`ZRPG.exe` **statically imports `d3d9.dll`**. Static imports load before `main()`,
so a proxy `d3d9.dll` placed in the EXE directory (Windows' DLL search order
favours it over `C:\Windows\System32\d3d9.dll`) runs its `DllMain` before the
engine's crashing CPU-init.

The proxy (`src/proxy/d3d9_proxy.c`, ~60 lines of C):

- **`DllMain`** (`DLL_PROCESS_ATTACH`): calls
  `SetProcessAffinityMask(GetCurrentProcess(), 0xF)` — restricts to cores 0–3.
  Non-fatal on failure.
- **`Direct3DCreate9`**: forwards to the real `C:\Windows\System32\d3d9.dll` via
  `LoadLibraryA` + `GetProcAddress` (absolute path avoids self-recursion).
- **`D3DPERF_*`** (3 functions): no-op stubs — these are PIX profiler hooks that are
  no-ops on non-PIX systems anyway.

The proxy does **not** modify the real `d3d9.dll`, your GPU drivers, or anything
outside the game directory. It forwards the one real graphics call transparently.

### Rendering note (dgVoodoo not required)

The game renders **natively via D3D9** — confirmed by the game's own console log
(`Attempting to create GFX device: … (D3D9)`, `$pref::Video::displayDevice = "D3D9"`).
The exe statically imports `d3d9.dll` + `DXGI.DLL` and never loads any graphics
wrapper. No dgVoodoo / ENB / wrapper is needed; the proxy above is a plain
affinity shim, not a graphics layer.

---

## 5. The Large Address Aware patch

`ZRPG.exe` ships a 32-bit PE **without** the `IMAGE_FILE_LARGE_ADDRESS_AWARE`
flag, capping it at 2 GB of virtual memory. With the 4K mod's larger fonts and
higher-resolution textures, the process can exceed 2 GB and crash.

`patch_laa.py` sets the flag, giving the process up to 4 GB on 64-bit Windows.
It does two things to the PE header (offsets derived from `e_lfanew`, not
hardcoded):

1. **Characteristics field** — OR in bit `0x20` (`IMAGE_FILE_LARGE_ADDRESS_AWARE`),
   preserving all other bits.
2. **CheckSum field** — recomputed with the Windows `CheckSumMappedFile` API so the
   output matches the standard patcher result byte-for-byte.

The script is idempotent and includes a `--verify` mode. Verified to reproduce the
reference patch exactly.

---

## 6. Bitmap backgrounds (`wrap=0`)

A `GuiBitmapCtrl` with `wrap = 0` renders its PNG at **native pixel size**. The
control's extent defines the child coordinate space but doesn't resize the bitmap.
After 2×-scaling a GUI layout, if the bitmap PNG is left at native resolution, the
2×-scaled children misalign with the visible (native-size) bitmap.

Fix: generate a 2× (`_4k`) PNG variant, add it to `gui.aod`, and re-point the
control's `bitmap` field at it. Applied to the Options-screen background
(`DS_options_screen_bg`) and the message-box background (`messageBox_bg`).
