# Changelog

## v4 — skill-bar fix + always-on borderless

- **Fixed:** skill progress/cost bars tiled their stock bitmaps across the
  scaler-expanded controls, producing double rows of tiny red marks — first on
  the character (level-up) screen, then on the character-creation screen when
  assigning starting skill points. The texture build now injects 2× replacements
  for all three affected bitmaps (audited across all 63 loaded GUIs; the only
  other `wrap = 1` bitmaps are flat shade scrims that tile seamlessly and are
  unaffected).
- **New:** always-on borderless fullscreen windowed. The `d3d9` proxy now also
  forces a windowed D3D9 swap chain at full 4K and restyles the game window to a
  titlebar-less full-screen popup — instant alt-tab, no Options toggle. The
  engine's mode string stays `"3840 2160 true 32 75 2"` (flipping it to windowed
  trips an engine guard that collapses the UI to ~900p). New vs the published v3.
- **Repo:** the proxy source is now the ship variant (affinity + borderless) and
  `src/proxy/undecorate_exports.ps1` (export-name fixer) is committed — tcc +
  the script reproduce the shipped `d3d9.dll` byte-for-byte
  (MD5 `FEDCA9D8B867464AF76BC07020758CDA`).
- **Docs:** shipped README updated — backup/uninstall lists now include the 4
  message-box dialog files (they replace stock files; previously omitted).

## v3 — list-column alignment + reproducible build

- **Fixed:** list-column alignment on the shelter screen and daily-results screen. The
  `columns` field of `GuiTextListCtrl` controls (per-column X-offsets) was not being 2×-scaled,
  so list bodies stayed clamped at 1080p spacing under the 2×-spread header labels. The job
  board was fixed in v2; this closes the remaining two screens.
- **Build:** the GUI scaler (`scale_guis.ps1`) now scales the `columns` field — every numeric
  token in the value is multiplied by the factor (handles variable column counts).
- **Build:** `build.ps1` is now fully reproducible. The Profiles step (previously a manual stub)
  is real, and a new MsgBox step compiles + installs the message-box font fix.
- **Docs:** TECHNICAL.md corrected (`wrap=0` stretches to the control extent, not native size)
  and gained sections on the `columns` field (§7) and message-box fix (§8).

## v2 — message-box font fix + job-board columns + repackage

- **Fixed:** the quit-confirmation Yes/No dialog (and all `MessageBoxYesNo/OK/YesNoCancel/
  OKCancel` popups) rendered with oversized text overflowing the box. Root cause: these stock
  T3D dialogs were never 2×-scaled, but the font profiles they referenced were — 2× fonts in a
  1× dialog. Fix: a dedicated `SegoePrint_Left_MsgBox` profile at the native size (35), with
  the four dialogs repointed at it.
- **Fixed:** shelter job-board list columns misaligned at 4K (`columns` field scaled).
- **Packaging:** re-packaged at maximum compression (`.7z` LZMA2). Added a 7-Zip extraction note
  to the install guide.

## v1 — initial release

- 2× UI scaling across ~60 GUI screens (fonts, control positions/extents, panels).
- 54 `_1800` (2×) texture variants for the texhandle HUD elements (party panel, AP pips, noise meter).
- >4-core launch crash fix via a proxy `d3d9.dll` (caps process affinity to cores 0–3).
- 4 GB Large Address Aware patch on `ZRPG.exe`.
