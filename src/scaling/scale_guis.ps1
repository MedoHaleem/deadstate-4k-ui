<#
.SYNOPSIS
    2x-scales the GUI layout files in Dead State's art/gui.aod for the 4K UI mod.

.DESCRIPTION
    Dead State's GUI layout files (.gui.dso) define the positions/extents of every
    on-screen control, authored for 1920x1080. This script decompiles each one with
    figment's Untorque, doubles all position/extent/minExtent values via regex, and
    recompiles them, producing 4K-scaled .dso files staged for injection into
    art/gui.aod.

    Two engine quirks are handled:
      * Resolution variants: the game ships _768/_900/_1080 variants of some GUIs;
        at 4K the engine loads _1080, so _768/_900 are skipped (never loaded).
      * "texhandle" controls: controls whose bitmap is the literal string "texhandle"
        receive their texture from engine code at runtime, and the texture sizes the
        control. Scaling such a control's extent would mismatch the fixed texture
        size, so their extents are preserved (only positions are scaled). Detection
        is a two-pass parser: pass 1 marks control blocks containing a texhandle
        bitmap, pass 2 skips the extent lines inside those blocks.

.PARAMETER GameDir
    Path to the Dead State install. Default: standard Steam path.

.PARAMETER WorkRoot
    Scratch directory for decompiled sources and staging. Default: a temp folder.

.PARAMETER Untorque
    Path to Untorque.exe (figment/Untorque). Must be downloaded separately - see
    docs/BUILD.md.

.PARAMETER SevenZip
    Path to a 7-Zip executable used to update art/gui.aod in place.

.PARAMETER Factor
    Scale factor. 2.0 = the 4K target. (Game was authored at 1080p.)

.PARAMETER AlreadyDone
    Array of .gui.dso entry names to skip (already scaled in a prior pass).

.EXAMPLE
    ./scale_guis.ps1 -GameDir "D:\Games\Dead State" -Untorque "C:\tools\Untorque.exe"
#>
param(
    [string]$GameDir   = "C:\Program Files (x86)\Steam\steamapps\common\Dead State",
    [string]$WorkRoot  = (Join-Path $env:TEMP "deadstate-4k"),
    [string]$Untorque  = "Untorque.exe",
    [string]$SevenZip  = "7z.exe",
    [double]$Factor    = 2.0,
    [string[]]$AlreadyDone = @()
)

$ErrorActionPreference = "Stop"

$aodPath     = Join-Path $GameDir "art\gui.aod"
$backupAod   = Join-Path $GameDir "art\gui.aod.bak"   # originals extracted from here
$un          = $Untorque
$staging     = Join-Path $WorkRoot "zip_update"
$decompiledDir = Join-Path $WorkRoot "decompiled\batch"

if (-not (Test-Path $staging))     { New-Item -ItemType Directory -Path $staging -Force | Out-Null }
if (-not (Test-Path $decompiledDir)) { New-Item -ItemType Directory -Path $decompiledDir -Force | Out-Null }

if (-not (Test-Path $backupAod)) { throw "Backup ZIP not found: $backupAod. Run the build once to create art/gui.aod.bak (a copy of the factory art/gui.aod)." }
if (-not (Test-Path $un))        { throw "Untorque not found: $un. Download from https://github.com/figment/Untorque (see docs/BUILD.md)." }

# --- Step 1: Get list of files to process ---
Write-Host "=== Step 1: Enumerating GUI files ===" -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($backupAod)
$allGui = $zip.Entries | Where-Object { $_.FullName -match '\.gui\.dso$' } | Select-Object -ExpandProperty FullName
$todo = $allGui | Where-Object {
    $_ -notmatch '_768\.' -and
    $_ -notmatch '_900\.' -and
    $_ -notin $AlreadyDone
}
$zip.Dispose()
Write-Host "  Total .gui.dso entries: $($allGui.Count)"
Write-Host "  To process: $($todo.Count)"

# --- Step 2: Scale function with texhandle handling ---
function Scale-GuiContent {
    param([string[]]$Lines, [double]$F = 2.0)

    $skipLines = @{}
    $blockStack = New-Object System.Collections.ArrayList

    # Pass 1: find texhandle blocks, collect their extent line indices
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]

        if ($line -match 'new\s+\w+\s*\(') {
            $block = [PSCustomObject]@{ ExtLines = @(); HasTexhandle = $false }
            [void]$blockStack.Add($block)
        }

        if ($line -match 'bitmap\s*=\s*"texhandle"' -and $blockStack.Count -gt 0) {
            $blockStack[$blockStack.Count - 1].HasTexhandle = $true
        }

        if ($line -match 'extent\s*=\s*"' -and $blockStack.Count -gt 0) {
            $blockStack[$blockStack.Count - 1].ExtLines += $i
        }

        if ($line -match '};' -and $blockStack.Count -gt 0) {
            $top = $blockStack[$blockStack.Count - 1]
            if ($top.HasTexhandle) {
                foreach ($ln in $top.ExtLines) { $skipLines[$ln] = $true }
            }
            $blockStack.RemoveAt($blockStack.Count - 1)
        }
    }

    # Pass 2: scale position/extent/minExtent + the `columns` field; skip texhandle extents.
    # `columns` (GuiTextListCtrl) is a space-separated list of per-column X-offsets with a
    # variable token count (e.g. "0 120 250"); every token is an X position and must be scaled
    # like any other X coordinate, or list bodies stay clamped at 1080p spacing under 2x-spread
    # headers. Unrelated to texhandle extents, so it is never in $skipLines.
    $pattern = '(position|extent|minExtent)\s*=\s*"(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)"'
    $columnsPattern = '(?<=columns\s*=\s*")(-?\d+(?:\.\d+)?(?:\s+-?\d+(?:\.\d+)?)*)(")'
    $result = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($skipLines.ContainsKey($i)) {
            $result.Add($Lines[$i])
            continue
        }
        $line = $Lines[$i]
        # Scale the columns list first (every numeric token xF), then position/extent/minExtent.
        if ($line -match 'columns\s*=\s*"') {
            $line = [regex]::Replace($line, $columnsPattern, {
                param($m)
                $tokens = $m.Groups[1].Value -split '\s+'
                $scaled = $tokens | ForEach-Object { [Math]::Round([double]$_ * $F) }
                "$($scaled -join ' ')`""
            })
        }
        $modified = [regex]::Replace($line, $pattern, {
            param($m)
            $field = $m.Groups[1].Value
            $x = [Math]::Round([double]$m.Groups[2].Value * $F)
            $y = [Math]::Round([double]$m.Groups[3].Value * $F)
            "$field = ""$x $y"""
        })
        $result.Add($modified)
    }
    return $result.ToArray()
}

# --- Step 3: Process each file ---
Write-Host "`n=== Step 2: Processing files ===" -ForegroundColor Cyan
$ok = 0; $fail = 0; $skip = 0
$stagedFiles = @()

# Reopen zip for extraction
$zip = [System.IO.Compression.ZipFile]::OpenRead($backupAod)

foreach ($entryName in $todo) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetFileNameWithoutExtension($entryName))
    $origDso   = Join-Path $decompiledDir "$baseName.orig.dso"
    $decompCs  = Join-Path $decompiledDir "$baseName.cs"
    $scaledCs  = Join-Path $decompiledDir "$baseName.2x.cs"
    $scaledDso = Join-Path $decompiledDir "$baseName.2x.dso"

    try {
        # Extract original
        $entry = $zip.Entries | Where-Object { $_.FullName -eq $entryName } | Select-Object -First 1
        if (-not $entry) { Write-Host "  SKIP (not found): $entryName" -ForegroundColor Yellow; $skip++; continue }
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $origDso, $true)

        # Decompile
        & $un decompile $origDso $decompCs 2>&1 | Out-Null
        if (-not (Test-Path $decompCs)) { Write-Host "  FAIL (decompile): $entryName" -ForegroundColor Red; $fail++; continue }

        # Check for texhandle
        $rawContent = Get-Content $decompCs -Raw
        $hasTexhandle = $rawContent -match 'texhandle'

        # Scale
        $lines = Get-Content $decompCs
        $scaled = Scale-GuiContent -Lines $lines -F $Factor
        $scaledText = $scaled -join "`n"
        Set-Content -Path $scaledCs -Value $scaledText -NoNewline

        # Compile
        & $un compile $scaledCs $scaledDso 2>&1 | Out-Null
        if (-not (Test-Path $scaledDso)) { Write-Host "  FAIL (compile): $entryName" -ForegroundColor Red; $fail++; continue }

        # Stage
        $stagedPath = Join-Path $staging $entryName
        Copy-Item $scaledDso $stagedPath -Force
        $stagedFiles += $entryName

        $texStr = if ($hasTexhandle) { " (has texhandle)" } else { "" }
        Write-Host "  OK: $entryName$texStr" -ForegroundColor Green
        $ok++
    } catch {
        Write-Host "  ERROR: $entryName - $_" -ForegroundColor Red
        $fail++
    }
}
$zip.Dispose()

Write-Host "`n=== Results ===" -ForegroundColor Cyan
Write-Host "  OK:     $ok"
Write-Host "  FAIL:   $fail"
Write-Host "  SKIP:   $skip"
Write-Host "  Staged: $($stagedFiles.Count) files"

# --- Step 4: Update ZIP ---
if ($stagedFiles.Count -gt 0) {
    Write-Host "`n=== Step 3: Updating ZIP ===" -ForegroundColor Cyan
    Push-Location $staging
    try {
        & $SevenZip u $aodPath "*.gui.dso" -spf -y
    } finally {
        Pop-Location
    }
    Write-Host "`nZIP update complete." -ForegroundColor Green
}

Write-Host "`n=== DONE ===" -ForegroundColor Green
