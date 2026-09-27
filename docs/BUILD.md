# Build guide

This rebuilds the entire 4K UI mod from a stock (factory) *Dead State* install.
No prebuilt game-derived assets are needed — every scaled file is regenerated
from your own copy of the game by the scripts in this repo.

---

## Prerequisites

| Tool | Why | Where to get it |
|---|---|---|
| **Dead State** (Steam) | The game itself. Install and launch once so the file layout exists. | [Steam store](https://store.steampowered.com/app/239840/Dead_State/) |
| **Untorque** | Decompiles & recompiles the game's `.dso` script files. Required. | [github.com/figment/Untorque](https://github.com/figment/Untorque) |
| **tcc** 0.9.27 | Compiles the `d3d9` proxy DLL (optional — prebuilt DLL included). | [bellard.org/tcc](https://bellard.org/tcc/) (grab `tcc-0.9.27-win32-bin.zip`) |
| **7-Zip** | Updates entries inside `art/gui.aod`. | [7-zip.org](https://www.7-zip.org/) |
| **Python 3** + **Pillow** | Runs the texture generator and LAA patcher. | [python.org](https://www.python.org/) → `pip install Pillow` |
| **PowerShell 5+** | Runs the build scripts (built into Windows 10/11). | included with Windows |

> The game ships its GUI layouts and font profiles as **compiled TorqueScript
> `.dso` files**, not source. Untorque is the only tool that can turn them into
> editable text and back. This is why it's a hard requirement.

### Setup

1. Install the tools above.
2. Note the full paths to `Untorque.exe` and (if rebuilding the proxy) `tcc.exe`.
3. Make sure `7z.exe` is on your `PATH`, or note its full path (commonly
   `C:\Program Files\7-Zip\7z.exe`).

---

## Option A — One-shot build (recommended)

```powershell
git clone https://github.com/MedoHaleem/deadstate-4k-ui.git
cd deadstate-4k-ui

./build/build.ps1 `
    -GameDir  "C:\Program Files (x86)\Steam\steamapps\common\Dead State" `
    -Untorque "C:\tools\Untorque.exe" `
    -Tcc      "C:\tools\tcc\tcc.exe" `
    -SevenZip "C:\Program Files\7-Zip\7z.exe"
```

What it does, step by step:

1. **Backup** — copies `art\gui.aod` → `art\gui.aod.bak` (the scaler reads
   originals from here, so the mod is always built from clean game files).
2. **LAA patch** — runs `patch_laa.py` on `ZRPG.exe` (flips the Large Address Aware
   flag in the PE header; writes `ZRPG.exe.bak` first).
3. **Proxy DLL** — compiles `d3d9.dll` with tcc, or copies the prebuilt one if tcc
   is not supplied.
4. **GUI scaling** — runs the layout scaler over all eligible `.gui.dso` files
   (positions, extents, `minExtent`, and the `columns` field — see TECHNICAL §2/§7).
5. **Profiles** — decompiles the stock engine profiles
   (`core\art\gui\profiles.cs.dso`), 2×-scales `fontSize`/`textOffset`/
   `borderThickness`, recompiles in place.
6. **Message-box fix** — compiles the game-profiles source (with the new
   `SegoePrint_Left_MsgBox` profile) and the four repointed message-box dialogs,
   and installs them to all required surfaces (see TECHNICAL §9).
7. **Textures** — generates the 54 `_1800` texture variants and the 2×
   tiled skill progress/cost bitmaps (see TECHNICAL §8).
8. **Inject** — inserts the textures into `art\gui.aod`.
9. **Install** — copies the 12 loose `.gui.dso` overrides into `art\gui\`.

You can run individual steps with `-Steps`, e.g. `-Steps Textures,Inject`. The
available steps are: `Backup`, `LAA`, `Proxy`, `GUIs`, `Profiles`, `MsgBox`,
`Textures`, `Inject`, `Install` (or `All`).

---

## Option B — Run the scripts individually

### GUI layout scaling

```powershell
./src/scaling/scale_guis.ps1 `
    -GameDir  "C:\...\Dead State" `
    -Untorque "C:\tools\Untorque.exe" `
    -SevenZip "C:\Program Files\7-Zip\7z.exe"
```

This is the bulk of the mod: it decompiles each `.gui.dso` from `art\gui.aod.bak`,
2×-scales all `position`/`extent`/`minExtent` values (skipping `_768`/`_900`
resolution variants and preserving `texhandle` control extents), recompiles, and
injects the results into `art\gui.aod`.

A companion, `scale_guis_retry.ps1`, handles the handful of GUIs nested in
subdirectories of the ZIP (`maps\`, `slideshow_editor\`).

### Texture generation

```powershell
python ./src/scaling/gen_1800_textures.py --game-dir "C:\...\Dead State"
# then follow the printed 7z command to inject the staged textures
```

### LAA patch (ZRPG.exe)

```powershell
python ./src/scaling/patch_laa.py "C:\...\Dead State\ZRPG.exe" --backup
python ./src/scaling/patch_laa.py "C:\...\Dead State\ZRPG.exe" --verify  # check
```

This is idempotent and produces a byte-for-byte identical result to the shipped
`ZRPG.exe` (verified: same Characteristics `0x0123`, same recomputed checksum).

### Proxy DLL (optional rebuild)

```powershell
C:\tools\tcc\tcc.exe -shared -o d3d9.dll src\proxy\d3d9_proxy.c -lkernel32
```

> **Export name caveat:** tcc emits stdcall-decorated export names
> (`_Direct3DCreate9@4`, `_D3DPERF_BeginEvent@8`, etc.). The game's import table
> expects *undecorated* names (`Direct3DCreate9`). The prebuilt `build\d3d9.dll`
> has the names rewritten to undecorated (a small post-build PE edit). If you
> rebuild with tcc, you'll need to do the same rewrite, or the game won't resolve
> the import. Easiest path: just use the prebuilt `build\d3d9.dll`.

### Profiles (engine)

Run by the `Profiles` step of the orchestrator. Decompile the stock loose
`core\art\gui\profiles.cs.dso`, double every `fontSize`/`textOffset`/
`borderThickness` value, recompile, and replace the loose file in place. See
[`docs/TECHNICAL.md`](TECHNICAL.md) §1 for the exact fields.

### Message-box dialogs

Run by the `MsgBox` step of the orchestrator. The game-profiles source
(`src\profiles\gameProfiles.english.cs`) already carries the 2×-scaled values
**and** the mod's `SegoePrint_Left_MsgBox` profile (fontSize 35 — the native
value, since these dialogs render in unscaled coordinate space; see TECHNICAL §9).
The four dialog sources in `src\msgbox\` repoint their text controls at that
profile. The step compiles all five and installs them:

- `gameProfiles.english.cs.dso` → **both** the loose `art\gui\` copy **and** the
  `gui.aod` ZIP-root entry (the loose file overrides the ZIP entry, so both must
  match).
- The four dialog `.ed.gui.edso` → `core\scripts\gui\messageBoxes\`.

Load order is safe — `client\init.cs.dso` execs `gameProfiles` before the
message-box dialogs.

---

## Verifying the build

After building, launch `ZRPG.exe` directly (no Steam launch options, no `.bat`).
The game should reach the main menu without crashing (the proxy handles the
core-affinity fix). In **Options → Graphics**, set the resolution to 3840×2160;
the UI should now render at 2× scale.

To confirm the proxy is loaded, check that `d3d9.dll` sits next to `ZRPG.exe`. To
confirm the LAA patch, run `patch_laa.py ZRPG.exe --verify` (should report `SET`).

---

## Uninstall / restore factory state

The build writes `.bak` copies of `ZRPG.exe` and `art\gui.aod`. To revert:

```powershell
Copy-Item "ZRPG.exe.bak"      "ZRPG.exe"          -Force
Copy-Item "art\gui.aod.bak"   "art\gui.aod"       -Force
Remove-Item "d3d9.dll"        -ErrorAction SilentlyContinue
```

Or use Steam → right-click *Dead State* → Properties → Installed Files →
**Verify integrity of game files** (restores all originals, removes mod files).
