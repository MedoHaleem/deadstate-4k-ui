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
3. 2×-scales every `position`/`extent`/`minExtent` value, and the `columns` field
   of `GuiTextListCtrl` controls (see §7).
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

The proxy (`src/proxy/d3d9_proxy.c`, ~250 lines of C) does two jobs — the
affinity cap and the always-on borderless force (next subsection):

- **`DllMain`** (`DLL_PROCESS_ATTACH`): calls
  `SetProcessAffinityMask(GetCurrentProcess(), 0xF)` — restricts to cores 0–3.
  Non-fatal on failure.
- **`Direct3DCreate9`**: forwards to the real `C:\Windows\System32\d3d9.dll` via
  `LoadLibraryA` + `GetProcAddress` (absolute path avoids self-recursion), then
  vtable-hooks device creation (below).
- **`D3DPERF_*`** (3 functions): no-op stubs — these are PIX profiler hooks that are
  no-ops on non-PIX systems anyway.

The proxy does **not** modify the real `d3d9.dll`, your GPU drivers, or anything
outside the game directory. It forwards the one real graphics call transparently.

### Borderless fullscreen windowed (always-on)

The same proxy makes the game a borderless, titlebar-less window filling the
primary monitor at full 4K, so alt-tab is instant. There is no toggle; it is
always on for 4K-mod users, and the proxy is the injection point.

Why it is done at the D3D9 layer and not in prefs/script:

- Flipping `$pref::Video::mode`'s fullscreen bit to `false` hits an engine C++
  guard (windowed resolution = desktop → auto-downscale to 1440×900, persisted
  into `prefs.cs`, which collapses the canvas and breaks `_1800` texture
  selection). The mode string must stay `"3840 2160 true 32 75 2"`.
- Restyling the HWND of an exclusive-FS D3D9 device alone is a visual no-op —
  the swap chain still owns the display.

Mechanism: keep the engine believing it is exclusive-FS at 3840×2160, then in the
D3D9 layer only — vtable-hook `IDirect3D9::CreateDevice` and `IDirect3DDevice9::Reset`,
force `D3DPRESENT_PARAMETERS.Windowed = TRUE` and `FullScreen_RefreshRateInHz = 0`
while leaving the backbuffer size alone, and restyle the engine window
(`TorqueJuggernaughtWindow`) to `WS_POPUP` at primary-monitor bounds. A short
watcher thread reapplies the restyle for ~6 s after launch (the engine re-touches
the window briefly; it starts ~132×37 under this path).

Verified: instant alt-tab, clean quit (full shutdown, no freeze regression),
affinity still `0xF`, 4K UI intact, prefs mode string unchanged.

### Rebuilding the proxy

```
tcc -shared -o d3d9.dll src\proxy\d3d9_proxy.c -lkernel32 -luser32
powershell -NoProfile -File src\proxy\undecorate_exports.ps1 d3d9.dll
```

tcc emits stdcall-decorated exports (`_Direct3DCreate9@4`); the game's import
table needs the bare names, so `undecorate_exports.ps1` rewrites the four export
name strings in place. With tcc 0.9.27 this reproduces the shipped
`build/d3d9.dll` **byte-for-byte** (MD5 `FEDCA9D8B867464AF76BC07020758CDA`).

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

In T3D v3.5.x (DSO v46 era), a `GuiBitmapCtrl` with `wrap = 0` calls
`drawBitmapStretch(texture, controlExtent)` in `onRender` — the bitmap is
**stretched to fill the control's extent**, not rendered at native pixel size.
(Verified against the v3.5.1 source `guiBitmapCtrl.cpp`.) So after 2×-scaling a
GUI layout, setting the control's extent to the desired visible box size is what
matters; the PNG stretches to match.

For sharper results on photographic backgrounds, a 2× (`_4k`) PNG variant can be
generated, added to `gui.aod`, and the control's `bitmap` field re-pointed at it
— a better stretch source, but not required for sizing. Applied to the
Options-screen background (`DS_options_screen_bg`).

---

## 7. The `columns` field of `GuiTextListCtrl`

`GuiTextListCtrl` controls (the game's tabular lists — the shelter job board,
daily results, etc.) carry a `columns` field: a space-separated list of per-column
X-offsets in the control's coordinate space (e.g. `columns = "0 120 250"`). Every
token is an X position and must be 2×-scaled like any other — otherwise the list
body's columns stay clamped at 1080p spacing while the header labels above them
(separate `fbHLMLTextCtrl`s whose `position` *was* 2×'d) spread to 4K spacing,
producing misaligned list rows.

The scaler's pass-2 handles this with a dedicated regex that matches the `columns`
value, splits it on whitespace, multiplies every numeric token by the factor, and
rejoins — independent of the `position`/`extent`/`minExtent` transform and of the
texhandle skip-set. Variable token counts are handled (lists range from 2 to 3+
columns).

---

## 8. Tiled (`wrap = 1`) skill bitmaps

The skill progress/cost controls on the character screens are `fbItemBitmapCtrl`s
with `wrap = 1` — the bitmap **tiles** across the control (a `wrap = 0` control
stretches instead; see §6). At stock, each control's extent equals its bitmap, so
each renders as exactly one tile. The GUI scaler doubles the extents; if the
bitmap stays at 1× the tile **count** doubles — the "double rows of tiny red
marks" bug seen first on `CharScreen`, then on `CharCreationScreen`.

The three affected textures (2× replacements generated in place, same path):

| Bitmap | Stock | 2× | Used by |
|---|---|---|---|
| `panels/CharScreen_Skill_Progress1080.png` | 210×23 | 420×46 | `CS_Skill0-7_Progress` (level-up screen) |
| `panels/CharCreationScreen_Skill_Progress900.png` | 219×23 | 438×46 | `CCS_Skill0-7_Progress`, `CCS_Final_Skill0-7_Progress` |
| `panels/CharCreationScreen_Skill_Cost_900.png` | 219×19 | 438×38 | `CCS_Skill0-7_Cost` |

(`CCS_Skill*_Progress` has `extent = "0 22"` — the engine sets the bar width at
runtime, same as on CharScreen, where the 2× texture alone was confirmed to fix
the fill.)

**Audit (all 63 loaded GUIs):** these three are the only `wrap = 1` file bitmaps
that render as a single tile at stock. The remaining `wrap = 1` users are flat
translucent shade scrims (`black_semi_dark.png`, `shade.png`) behind popups —
uniform-color overlays that tile seamlessly at any tile count, visually identical
at 4K, deliberately left at 1×. (`panels/progressBar`, referenced by the dev-only
`AI_Analyzer` screen, is missing from the archive even at stock.)

The generator reads these sources from `gui.aod.bak`, so repeated builds remain
idempotent and never upscale an already-fixed asset again.

---

## 9. Message-box dialogs (the font-profile fix)

The stock T3D message-box dialogs (`MessageBoxYesNoDlg`, `…Ok`, `…YesNoCancel`,
`…OkCancel`, in `core/scripts/gui/messageBoxes/*.ed.gui`) are a **separate system**
from `GenericMessageBox` and were never 2×-scaled by the layout pass — they still
render at native `1024 768` extents. But the font profiles they referenced
(`SegoePrint_Left_35` → fontSize 70, `…_25` → 50, in `gameProfiles.english.cs.dso`)
*were* 2×-scaled. The result: 2×-sized fonts crammed in a 1×-sized dialog —
illegible text overflowing the box.

**Fix — a dedicated small-font profile.** Since these dialogs render in native
(unscaled) coordinate space, the correct font is the original native size, not the
2× value. A new singleton `SegoePrint_Left_MsgBox` (fontSize 35) is added to
`gameProfiles.english.cs.dso`, and the four dialogs' text controls are repointed
at it. Surgical: `SegoePrint_Left_35` is shared with `CharScreen` (which *is*
2×-scaled and needs 70), so the shared profile is left alone — only the dialogs
move to the dedicated one.

**Install surfaces (three, all required):**

1. `gameProfiles.english.cs.dso` → **both** the loose `art/gui/` copy AND the
   `gui.aod` ZIP-root entry. The loose file overrides the ZIP entry (VFS), so both
   must match or the loose one silently wins.
2. The four dialog `.ed.gui.edso` → loose in `core/scripts/gui/messageBoxes/`
   (loose files are honored under `core/`).
3. **Load order is safe:** `client/init.cs.dso` execs `gameProfiles` (line 7)
   *before* `messageBox.ed.cs` (line 8), so the new profile exists before the
   dialogs reference it.

Sources in the repo: `src/profiles/gameProfiles.english.cs` (the 2×-scaled game
profiles + the `SegoePrint_Left_MsgBox` profile) and `src/msgbox/*.ed.gui` (the
four repointed dialogs). Build step: `build.ps1 -Steps MsgBox`.
