<#
.SYNOPSIS
    One-shot build orchestrator for the Dead State 4K UI mod.

.DESCRIPTION
    Rebuilds every part of the mod from a stock (factory) Dead State install:
      1. Backs up art/gui.aod -> art/gui.aod.bak (originals source for the scaler).
      2. Applies the Large Address Aware flag to ZRPG.exe (patch_laa.py).
      3. Builds the d3d9 proxy DLL (tcc) from src/proxy/d3d9_proxy.c — the
         affinity cap + always-on borderless-windowed force — then strips
         tcc's decorated export names via src/proxy/undecorate_exports.ps1.
      4. 2x-scales the GUI layout files (scale_guis.ps1 + scale_guis_retry.ps1).
      5. 2x-scales the engine font profiles (decompile -> scale -> compile).
      6. Applies the message-box font fix: compiles the scaled game profiles
         (with the new SegoePrint_Left_MsgBox profile) and the 4 repointed
         message-box dialogs, and installs them.
      7. Generates the 54 _1800 texhandle variants and the 2x tiled
          skill progress/cost bitmaps (gen_1800_textures.py).
      8. Injects the textures into art/gui.aod (7-Zip).
      9. Installs the loose GUI .dso overrides + proxy DLL.

    See docs/BUILD.md for prerequisites and step-by-step instructions. This
    orchestrator exists to document the full pipeline; the individual scripts
    under src/ can also be run standalone.

.PARAMETER GameDir
    Path to the Dead State install (must be a factory/clean copy, or one you've
    already backed up). Default: standard Steam path.

.PARAMETER Untorque
    Path to figment's Untorque.exe. REQUIRED. Download:
    https://github.com/figment/Untorque

.PARAMETER Tcc
    Path to tcc.exe (Tiny C Compiler) for building the proxy DLL. REQUIRED for
    step 3; the prebuilt build/d3d9.dll is used if tcc is unavailable.

.PARAMETER SevenZip
    Path to 7-Zip. Default: 7z.exe (expects it on PATH).

.PARAMETER Python
    Python interpreter. Default: python.

.PARAMETER Steps
    Which steps to run. Default: all. Useful to rerun a single stage, e.g.
    -Steps Profiles to re-do only the font scaling.

.EXAMPLE
    ./build.ps1 -GameDir "D:\Steam\...\Dead State" -Untorque "C:\tools\Untorque.exe" -Tcc "C:\tools\tcc\tcc.exe"
#>
param(
    [string]$GameDir   = "C:\Program Files (x86)\Steam\steamapps\common\Dead State",
    [string]$Untorque  = "",
    [string]$Tcc       = "",
    [string]$SevenZip  = "7z.exe",
    [string]$Python    = "python",
    [ValidateSet("All","Backup","LAA","Proxy","GUIs","Profiles","MsgBox","Textures","Inject","Install")]
    [string[]]$Steps   = @("All")
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$workRoot = Join-Path $env:TEMP "deadstate-4k"
$all = $Steps -contains "All"
function Test-Step($name) { $all -or ($Steps -contains $name) }

function Write-Step($n, $msg) { Write-Host "`n[$n] $msg" -ForegroundColor Cyan }

# --- Sanity checks ----------------------------------------------------------
if (-not (Test-Path $GameDir)) { throw "GameDir not found: $GameDir" }
if (-not (Test-Path (Join-Path $GameDir "ZRPG.exe"))) { throw "ZRPG.exe not found in GameDir." }
if (-not (Test-Path (Join-Path $GameDir "art\gui.aod"))) { throw "art\gui.aod not found in GameDir." }
if (-not $Untorque -or -not (Test-Path $Untorque)) {
    throw "Untorque.exe path required. Download from https://github.com/figment/Untorque"
}

$aodPath   = Join-Path $GameDir "art\gui.aod"
$backupAod = Join-Path $GameDir "art\gui.aod.bak"

Write-Host "Dead State 4K UI mod - build" -ForegroundColor Green
Write-Host "  GameDir:   $GameDir"
Write-Host "  Untorque:  $Untorque"
Write-Host "  Tcc:       $(if ($Tcc) { $Tcc } else { '(none - will use prebuilt proxy)' })"
Write-Host "  WorkRoot:  $workRoot"
Write-Host "  Steps:     $($Steps -join ', ')"

# --- Step 1: Backup ---------------------------------------------------------
if (Test-Step "Backup") {
    Write-Step 1 "Backing up art/gui.aod -> art/gui.aod.bak"
    if (-not (Test-Path $backupAod)) {
        Copy-Item $aodPath $backupAod
        Write-Host "  Created $backupAod" -ForegroundColor Green
    } else {
        Write-Host "  Backup already exists, leaving as-is: $backupAod" -ForegroundColor Yellow
    }
}

# --- Step 2: LAA patch on ZRPG.exe -----------------------------------------
if (Test-Step "LAA") {
    Write-Step 2 "Applying Large Address Aware flag to ZRPG.exe"
    & $Python (Join-Path $repoRoot "src\scaling\patch_laa.py") (Join-Path $GameDir "ZRPG.exe") --backup
    if ($LASTEXITCODE -ne 0) { throw "LAA patch failed." }
}

# --- Step 3: Build proxy DLL ------------------------------------------------
if (Test-Step "Proxy") {
    $proxySrc  = Join-Path $repoRoot "src\proxy\d3d9_proxy.c"
    $undec     = Join-Path $repoRoot "src\proxy\undecorate_exports.ps1"
    $proxyDll  = Join-Path $GameDir "d3d9.dll"
    if ($Tcc -and (Test-Path $Tcc)) {
        Write-Step 3 "Building d3d9 proxy DLL with tcc (affinity + borderless)"
        & $Tcc -shared -o $proxyDll $proxySrc -lkernel32 -luser32
        if ($LASTEXITCODE -ne 0) { throw "Proxy build failed." }
        # tcc emits stdcall-decorated exports (_Direct3DCreate9@4); the game's
        # import table needs bare names. Verified: tcc + this script reproduces
        # the shipped d3d9.dll byte-for-byte (MD5 FEDCA9D8B867464AF76BC07020758CDA).
        & powershell -NoProfile -File $undec $proxyDll
        Write-Host "  Built + undecorated $proxyDll" -ForegroundColor Green
    } else {
        Write-Step 3 "Copying prebuilt d3d9 proxy DLL (tcc not provided)"
        $prebuilt = Join-Path $repoRoot "build\d3d9.dll"
        if (-not (Test-Path $prebuilt)) { throw "Prebuilt proxy not found: $prebuilt" }
        Copy-Item $prebuilt $proxyDll -Force
        Write-Host "  Copied $prebuilt -> $proxyDll" -ForegroundColor Green
    }
}

# --- Step 4: Scale GUI layout files ----------------------------------------
if (Test-Step "GUIs") {
    Write-Step 4 "2x-scaling GUI layout files"
    & (Join-Path $repoRoot "src\scaling\scale_guis.ps1") `
        -GameDir $GameDir -WorkRoot $workRoot -Untorque $Untorque -SevenZip $SevenZip
    & (Join-Path $repoRoot "src\scaling\scale_guis_retry.ps1") `
        -GameDir $GameDir -WorkRoot $workRoot -Untorque $Untorque -SevenZip $SevenZip
}

# --- Step 5: Scale engine font profiles ------------------------------------
# The ENGINE profiles (core\art\gui\profiles.cs.dso) are decompiled from the stock
# loose file, 2x-scaled (fontSize/textOffset/borderThickness), and recompiled in
# place. This uses the same regex-driven scaling approach as the GUI scaler but on
# a single file. The GAME profiles (gameProfiles.english.cs.dso) are handled in the
# MessageBox step below, because they carry a mod-specific profile addition
# (SegoePrint_Left_MsgBox) that cannot be derived by scaling a stock file alone.
if (Test-Step "Profiles") {
    Write-Step 5 "2x-scaling engine font profiles (core\art\gui\profiles.cs.dso)"
    $engineProfDso = Join-Path $GameDir "core\art\gui\profiles.cs.dso"
    $profStage     = Join-Path $workRoot "profiles"
    if (-not (Test-Path $profStage)) { New-Item -ItemType Directory -Path $profStage -Force | Out-Null }
    $origCs = Join-Path $profStage "profiles.orig.cs"
    $scaledCs = Join-Path $profStage "profiles.2x.cs"

    & $Untorque decompile $engineProfDso $origCs 2>&1 | Out-Null
    if (-not (Test-Path $origCs)) { throw "Failed to decompile engine profiles." }

    # Scale fontSize/textOffset/borderThickness x2 in the decompiled source.
    $lines = Get-Content $origCs
    $scaled = $lines | ForEach-Object {
        [regex]::Replace($_, '(fontSize|textOffset|borderThickness)\s*=\s*(\d+)', {
            param($m)
            $v = [Math]::Round([double]$m.Groups[2].Value * 2.0)
            "$($m.Groups[1].Value) = $v"
        })
    }
    Set-Content -Path $scaledCs -Value ($scaled -join "`n") -NoNewline

    & $Untorque compile $scaledCs $engineProfDso 2>&1 | Out-Null
    Write-Host "  Scaled + installed engine profiles -> $engineProfDso" -ForegroundColor Green
}

# --- Step 6: Message-box font fix (game profiles + 4 dialogs) ---------------
# The game profiles source under src\profiles\ already carries the 2x-scaled
# values AND the mod's SegoePrint_Left_MsgBox profile (fontSize 35 -- the native
# value, since these dialogs render in unscaled coordinate space). The 4 dialog
# sources under src\msgbox\ repoint their text controls at that profile. This step
# compiles all 5 and installs them to the three required surfaces (see
# docs/TECHNICAL.md "Message-box dialogs"). gameProfiles installs to BOTH the
# loose art\gui\ copy AND the gui.aod ZIP root -- the loose file overrides the ZIP
# entry (VFS), so both must match or the loose one silently wins.
if (Test-Step "MsgBox") {
    Write-Step 6 "Applying message-box font fix (game profiles + 4 dialogs)"
    $gpSrc      = Join-Path $repoRoot "src\profiles\gameProfiles.english.cs"
    $mbDir      = Join-Path $repoRoot "src\msgbox"
    $msgDest    = Join-Path $GameDir "core\scripts\gui\messageBoxes"
    $gpLooseDst = Join-Path $GameDir "art\gui\gameProfiles.english.cs.dso"
    $gpStage    = Join-Path $workRoot "msgbox_stage"
    if (-not (Test-Path $gpStage)) { New-Item -ItemType Directory -Path $gpStage -Force | Out-Null }

    # Compile game profiles -> install to both loose + ZIP-root surfaces.
    $gpDso = Join-Path $gpStage "gameProfiles.english.cs.dso"
    & $Untorque compile $gpSrc $gpDso 2>&1 | Out-Null
    if (-not (Test-Path $gpDso)) { throw "Failed to compile game profiles." }
    Copy-Item $gpDso $gpLooseDst -Force
    Write-Host "  Installed game profiles (loose) -> $gpLooseDst" -ForegroundColor Green

    Push-Location $gpStage
    try {
        & $SevenZip u $aodPath "gameProfiles.english.cs.dso" -mx=1 -y | Out-Null
    } finally { Pop-Location }
    Write-Host "  Installed game profiles (ZIP root) -> art\gui.aod" -ForegroundColor Green

    # Compile the 4 repointed dialogs -> install to core\scripts\gui\messageBoxes\.
    if (-not (Test-Path $msgDest)) { New-Item -ItemType Directory -Path $msgDest -Force | Out-Null }
    foreach ($name in "messageBoxOk","messageBoxYesNo","messageBoxYesNoCancel","messageBoxOkCancel") {
        $guiSrc = Join-Path $mbDir "$name.ed.gui"
        $guiDso = Join-Path $msgDest "$name.ed.gui.edso"
        & $Untorque compile $guiSrc $guiDso 2>&1 | Out-Null
        if (-not (Test-Path $guiDso)) { throw "Failed to compile dialog: $name" }
        Write-Host "  Installed dialog -> $name.ed.gui.edso" -ForegroundColor Green
    }
    Write-Host "  NOTE: gameProfiles is installed before the dialogs reference the new" -ForegroundColor Yellow
    Write-Host "        profile; load order is safe (init.cs execs gameProfiles first)." -ForegroundColor Yellow
}

# --- Step 7: Generate _1800 textures ---------------------------------------
if (Test-Step "Textures") {
    Write-Step 7 "Generating 2x texhandle and tiled skill bitmaps"
    & $Python (Join-Path $repoRoot "src\scaling\gen_1800_textures.py") --game-dir $GameDir
    if ($LASTEXITCODE -ne 0) { throw "Texture generation failed." }
}

# --- Step 8: Inject scaled assets into gui.aod -----------------------------
if (Test-Step "Inject") {
    Write-Step 8 "Injecting _1800 textures into art/gui.aod"
    $stage = Join-Path $repoRoot "src\scaling\_zipstage"
    if (Test-Path $stage) {
        Push-Location $stage
        try {
            & $SevenZip u $aodPath panels text -spf -mx=1 -y
        } finally { Pop-Location }
        Write-Host "  Injected textures into $aodPath" -ForegroundColor Green
    } else {
        Write-Host "  No staging dir found ($stage) - skip" -ForegroundColor Yellow
    }
}

# --- Step 9: Install loose files -------------------------------------------
if (Test-Step "Install") {
    Write-Step 9 "Installing loose GUI .dso overrides into art\gui\"
    # The 12 GUIs that ship loose (engine loads these over the ZIP entries) are
    # copied from the scaler's staging dir into the game's art\gui\ folder.
    $staging = Join-Path $workRoot "zip_update"
    $dest = Join-Path $GameDir "art\gui"
    $looseGuis = @(
        "CharCreationScreen_1080.english.gui.dso","CharScreen_1080.english.gui.dso",
        "DailyResultsScreen_1080.english.gui.dso","DialogueScreen.english.gui.dso",
        "GameMenu.gui.dso","GenericMessageBox.gui.dso","GoalsScreen_1080.english.gui.dso",
        "InventoryScreen_1080.english.gui.dso","LootScreen_1080.english.gui.dso",
        "MainMenuGui.english.gui.dso","MapScreen_1080.english.gui.dso",
        "PlayGuiContent_1080.english.gui.dso"
    )
    foreach ($g in $looseGuis) {
        $src = Join-Path $staging $g
        if (Test-Path $src) {
            Copy-Item $src (Join-Path $dest $g) -Force
        }
    }
    Write-Host "  Installed loose GUI overrides into $dest" -ForegroundColor Green
}

Write-Host "`n=== BUILD COMPLETE ===" -ForegroundColor Green
Write-Host "Launch ZRPG.exe directly. Set resolution to 3840x2160 in Options -> Graphics." -ForegroundColor Green
