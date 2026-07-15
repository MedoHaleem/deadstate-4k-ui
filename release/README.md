# Dead State — 4K UI Scaling Mod

Makes the entire Dead State UI readable at 3840×2160 (4K), and fixes the multi-core
launch crash on modern CPUs. **Manual install** — no scripts, just copy files.

> **Extracting the download:** the mod is distributed as a `.7z` archive for a smaller
> download. Extract it with **[7-Zip](https://www.7-zip.org/)** (free) before installing —
> right-click the `.7z` → **7-Zip → Extract to "DeadState-4K-UI\"**. Windows can't open
> `.7z` files on its own.

---

## ⚠️ Before you start: back up your game

This mod replaces a few of the game's original files. **You only need to back up these 4
files** (the ones the mod overwrites). Copy them somewhere safe (e.g. a `backup` folder on
your Desktop) so you can restore the original game later:

| Back up this file | (relative to your Dead State folder) |
|---|---|
| `ZRPG.exe` | root |
| `art\gui.aod` | inside `art\` |
| `core\art\gui\profiles.cs.dso` | inside `core\art\gui\` |
| `core\art\gui\optionsDlg.gui.dso` | inside `core\art\gui\` |

> The 12 files in this mod's `art\gui\` folder do **not** exist in the original game, so
> there's nothing to back up for those — they're added by the mod (see Uninstall below to
> remove them).

---

## Install

1. **Close the game** if it's running.
2. Open your Dead State install folder. The default Steam path is usually:
   `C:\Program Files (x86)\Steam\steamapps\common\Dead State`
   (Right-click Dead State in Steam → Manage → Browse local files.)
3. **Copy the contents of this mod's folder into your Dead State folder**, merging/overwriting
   when asked. Specifically:
   - Copy **`ZRPG.exe`** → into the Dead State root (overwrite).
   - Copy **`d3d9.dll`** → into the Dead State root (new file).
   - Copy the **`art`** folder → into the Dead State root (merge). This replaces `art\gui.aod`
     and adds the 12 `.gui.dso` files in `art\gui\`.
   - Copy the **`core`** folder → into the Dead State root (merge). This replaces
     `core\art\gui\profiles.cs.dso` and `core\art\gui\optionsDlg.gui.dso`.
4. Launch the game via Steam as normal.

**That's it.** No launch options, no `.bat` file. The `d3d9.dll` proxy handles the multi-core
crash fix automatically.

In-game, go to **Options → Graphics** and set the resolution to **3840×2160** to see the
4K-scaled UI.

> **Tip:** To merge folders easily in Windows, drag the `art` and `core` folders onto the
> Dead State folder. Windows will ask "Replace or skip files?" / "Merge?" — choose
> **Replace the files in the destination**.

---

## Uninstall (restore the original game)

1. Restore your **4 backed-up files** to their original locations (overwrite the modded ones):
   - `ZRPG.exe` → Dead State root
   - `art\gui.aod` → inside `art\`
   - `core\art\gui\profiles.cs.dso` → inside `core\art\gui\`
   - `core\art\gui\optionsDlg.gui.dso` → inside `core\art\gui\`
2. Delete the mod's proxy DLL from the Dead State root:
   - `d3d9.dll`
3. Delete the 12 mod-added GUI files from `art\gui\`:
   - `CharCreationScreen_1080.english.gui.dso`
   - `CharScreen_1080.english.gui.dso`
   - `DailyResultsScreen_1080.english.gui.dso`
   - `DialogueScreen.english.gui.dso`
   - `GameMenu.gui.dso`
   - `GenericMessageBox.gui.dso`
   - `GoalsScreen_1080.english.gui.dso`
   - `InventoryScreen_1080.english.gui.dso`
   - `LootScreen_1080.english.gui.dso`
   - `MainMenuGui.english.gui.dso`
   - `MapScreen_1080.english.gui.dso`
   - `PlayGuiContent_1080.english.gui.dso`

Your game is now back to its original state. (Alternatively, the fastest clean uninstall is
to use Steam's **Verify integrity of game files** — this restores all original files and
removes any mod-added ones automatically.)

---

## What this mod changes

- **2× scales all UI** — fonts, control positions/extents, list-column offsets, and panels
  across ~60 GUI screens (dialogue, character/inventory/map/loot screens, message boxes, the
  pause menu, options, etc.).
- **Readable message-box dialogs** — the quit-confirm Yes/No and other popups use a dedicated
  font profile so text fits inside the box at 4K (fixed; previously overflowed).
- **Aligned list columns** — `GuiTextListCtrl` column offsets (shelter job board, daily results,
  shelter screen) are scaled to match the 2×-spaced headers (fixed; previously misaligned).
- **54 high-resolution texture variants** (`_1800`) for the party panel, AP pips, and noise meter.
- **1 panel background re-rendered at 4K** (`DS_options_screen_bg`).
- **>4-core launch crash fix** — a 2 KB proxy `d3d9.dll` caps process affinity to cores 0–3
  before the engine's crashing CPU enumeration runs. Works on any launch path (Steam,
  shortcut, or the exe directly).
- **4 GB Large Address Aware patch** on `ZRPG.exe` for stability with larger textures.

## Requirements

- **Dead State** (Steam version), installed and launched at least once.
- **Windows 10/11** with DirectX 9 (included with Windows — nothing to download). The game
  renders natively via D3D9; no graphics wrapper (dgVoodoo, ENB, etc.) is needed.
- A **4K (3840×2160) display** is recommended. Works at other resolutions, but the scaling
  is tuned for 4K.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Game crashes on launch (many-core CPU) | Confirm `d3d9.dll` is in the Dead State root next to `ZRPG.exe`. |
| Text still tiny | Set resolution to 3840×2160 in Options → Graphics. |
| Want a clean slate | Use Steam → Right-click Dead State → Properties → Installed Files → **Verify integrity of game files**, then reinstall the mod. |

> **Known issue (not fixed by this mod):** dropdown selected-text remains invisible in
> some `GuiPopUpMenuCtrl` dropdowns — a side-effect of the 2× font scaling clipping
> to the native-size arrow cell. The quit-confirmation (Yes/No) and other message-box
> dialogs **are** fixed and render correctly.

## Credits

- **figment** for **[Untorque](https://github.com/figment/Untorque)** — the Torque3D Script
  DSO decompiler/compiler. **This mod would not exist without it.** Every scaled GUI and
  profile was decompiled from the game's compiled `.dso` files, edited, and recompiled using
  Untorque. Many thanks to the author for releasing this essential tool.
- `ZRPG.exe` is patched only with the Large Address Awareness flag (allows >2GB RAM). The
  d3d9 proxy forwards Direct3D9 to the real system `d3d9.dll` after setting process affinity —
  it does not modify the real `d3d9.dll` or your GPU drivers.
- Does not touch your saves, settings (`prefs.cs`), or Steam.
