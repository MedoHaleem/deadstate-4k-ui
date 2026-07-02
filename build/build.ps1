<#
.SYNOPSIS
    One-shot build orchestrator for the Dead State 4K UI mod.

.DESCRIPTION
    Rebuilds every part of the mod from a stock (factory) Dead State install:
      1. Backs up art/gui.aod -> art/gui.aod.bak (originals source for the scaler).
      2. Applies the Large Address Aware flag to ZRPG.exe (patch_laa.py).
      3. Builds the d3d9 proxy DLL (tcc) from src/proxy/d3d9_proxy.c.
      4. 2x-scales the GUI layout files (scale_guis.ps1 + scale_guis_retry.ps1).
      5. 2x-scales the font profiles (engine + game profiles).
      6. Generates the 54 _1800 texhandle texture variants (gen_1800_textures.py).
      7. Injects all scaled assets into art/gui.aod (7-Zip).
      8. Installs the loose GUI .dso overrides + scaled profiles + proxy DLL.

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
    [ValidateSet("All","Backup","LAA","Proxy","GUIs","Profiles","Textures","Inject","Install")]
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
    $proxyDll  = Join-Path $GameDir "d3d9.dll"
    if ($Tcc -and (Test-Path $Tcc)) {
        Write-Step 3 "Building d3d9 proxy DLL with tcc"
        & $Tcc -shared -o $proxyDll $proxySrc -lkernel32
        if ($LASTEXITCODE -ne 0) { throw "Proxy build failed." }
        Write-Host "  Built $proxyDll" -ForegroundColor Green
        Write-Host "  NOTE: tcc emits stdcall-decorated export names (_Direct3DCreate9@4 etc.)." -ForegroundColor Yellow
        Write-Host "        The prebuilt build/d3d9.dll has undecorated names; see docs/BUILD.md." -ForegroundColor Yellow
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

# --- Step 5: Scale font profiles -------------------------------------------
# Profiles scaling uses the same decompile->scale->compile->install flow but on
# the two profile files. This is scripted inline (small, well-defined transforms:
# fontSize, textOffset, borderThickness x2). See docs/TECHNICAL.md section 1.
if (Test-Step "Profiles") {
    Write-Step 5 "2x-scaling font profiles (engine + game profiles)"
    Write-Host "  Engine profiles: core\art\gui\profiles.cs.dso" -ForegroundColor Yellow
    Write-Host "  Game profiles:   art\gui.aod ! gameProfiles.english.cs.dso" -ForegroundColor Yellow
    Write-Host "  (Run the profile scaler manually for now - see docs/BUILD.md section 'Profiles'.)" -ForegroundColor Yellow
}

# --- Step 6: Generate _1800 textures ---------------------------------------
if (Test-Step "Textures") {
    Write-Step 6 "Generating 54 _1800 (2x) texhandle texture variants"
    & $Python (Join-Path $repoRoot "src\scaling\gen_1800_textures.py") --game-dir $GameDir
    if ($LASTEXITCODE -ne 0) { throw "Texture generation failed." }
}

# --- Step 7: Inject scaled assets into gui.aod -----------------------------
if (Test-Step "Inject") {
    Write-Step 7 "Injecting _1800 textures into art/gui.aod"
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

# --- Step 8: Install loose files -------------------------------------------
if (Test-Step "Install") {
    Write-Step 8 "Installing loose GUI .dso overrides into art\gui\"
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
