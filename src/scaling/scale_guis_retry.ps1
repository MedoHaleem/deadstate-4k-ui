<#
.SYNOPSIS
    Re-runs the GUI scaler on a specific list of .gui.dso entries that live in
    subdirectories of art/gui.aod (e.g. maps/, slideshow_editor/).

.DESCRIPTION
    A companion to scale_guis.ps1. The main batch script globs "*.gui.dso" when
    injecting, which works for entries at the ZIP root but not for entries nested
    under subdirectories. This script targets a hardcoded set of nested entries
    that were identified after the first pass, scales them with the same texhandle-
    aware logic, stages them preserving their subdirectory paths, and injects them
    with explicit path patterns.

    Shares the same scaling engine (Scale-GuiContent) and parameters as
    scale_guis.ps1.

.PARAMETER GameDir
    Path to the Dead State install. Default: standard Steam path.

.PARAMETER WorkRoot
    Scratch directory for decompiled sources and staging. Default: a temp folder.

.PARAMETER Untorque
    Path to Untorque.exe (figment/Untorque).

.PARAMETER SevenZip
    Path to a 7-Zip executable.

.PARAMETER RetryFiles
    Array of .gui.dso entry paths (relative to the ZIP root) to process.

.EXAMPLE
    ./scale_guis_retry.ps1 -GameDir "D:\Games\Dead State" -Untorque "C:\tools\Untorque.exe"
#>
param(
    [string]$GameDir  = "C:\Program Files (x86)\Steam\steamapps\common\Dead State",
    [string]$WorkRoot = (Join-Path $env:TEMP "deadstate-4k"),
    [string]$Untorque = "Untorque.exe",
    [string]$SevenZip = "7z.exe",
    [string[]]$RetryFiles = @(
        "maps/MapZrpg.gui.dso",
        "slideshow_editor/SlideType0.english.gui.dso",
        "slideshow_editor/SlideType1.english.gui.dso",
        "slideshow_editor/SlideType2.english.gui.dso",
        "slideshow_editor/SlideType3.english.gui.dso",
        "slideshow_editor/SlideType4.english.gui.dso"
    )
)

$ErrorActionPreference = "Stop"

$aodPath       = Join-Path $GameDir "art\gui.aod"
$backupAod     = Join-Path $GameDir "art\gui.aod.bak"
$un            = $Untorque
$staging       = Join-Path $WorkRoot "zip_update"
$decompiledDir = Join-Path $WorkRoot "decompiled\batch"

if (-not (Test-Path $backupAod)) { throw "Backup ZIP not found: $backupAod." }
if (-not (Test-Path $un))        { throw "Untorque not found: $un." }

function Scale-GuiContent {
    param([string[]]$Lines)
    $skipLines = @{}
    $blockStack = New-Object System.Collections.ArrayList
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
    $pattern = '(position|extent|minExtent)\s*=\s*"(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)"'
    $result = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($skipLines.ContainsKey($i)) {
            $result.Add($Lines[$i])
            continue
        }
        $modified = [regex]::Replace($Lines[$i], $pattern, {
            param($m)
            $field = $m.Groups[1].Value
            $x = [Math]::Round([double]$m.Groups[2].Value * 2.0)
            $y = [Math]::Round([double]$m.Groups[3].Value * 2.0)
            "$field = ""$x $y"""
        })
        $result.Add($modified)
    }
    return $result.ToArray()
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($backupAod)
$ok = 0; $fail = 0

foreach ($entryName in $RetryFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetFileNameWithoutExtension($entryName))
    $origDso   = Join-Path $decompiledDir "$baseName.orig.dso"
    $decompCs  = Join-Path $decompiledDir "$baseName.cs"
    $scaledCs  = Join-Path $decompiledDir "$baseName.2x.cs"
    $scaledDso = Join-Path $decompiledDir "$baseName.2x.dso"

    try {
        $entry = $zip.Entries | Where-Object { $_.FullName -eq $entryName } | Select-Object -First 1
        if (-not $entry) { Write-Host "  SKIP (not found): $entryName" -ForegroundColor Yellow; continue }
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $origDso, $true)

        & $un decompile $origDso $decompCs 2>&1 | Out-Null
        if (-not (Test-Path $decompCs)) { Write-Host "  FAIL (decompile): $entryName" -ForegroundColor Red; $fail++; continue }

        $lines = Get-Content $decompCs
        $scaled = Scale-GuiContent -Lines $lines
        Set-Content -Path $scaledCs -Value ($scaled -join "`n") -NoNewline

        & $un compile $scaledCs $scaledDso 2>&1 | Out-Null
        if (-not (Test-Path $scaledDso)) { Write-Host "  FAIL (compile): $entryName" -ForegroundColor Red; $fail++; continue }

        $stagedPath = Join-Path $staging $entryName
        $stagedDir = Split-Path $stagedPath -Parent
        if (-not (Test-Path $stagedDir)) { New-Item -ItemType Directory -Path $stagedDir -Force | Out-Null }
        Copy-Item $scaledDso $stagedPath -Force

        Write-Host "  OK: $entryName" -ForegroundColor Green
        $ok++
    } catch {
        Write-Host "  ERROR: $entryName - $_" -ForegroundColor Red
        $fail++
    }
}
$zip.Dispose()

Write-Host "`nOK: $ok  FAIL: $fail"

if ($ok -gt 0) {
    Write-Host "`n=== Updating ZIP ===" -ForegroundColor Cyan
    Push-Location $staging
    try {
        & $SevenZip u $aodPath "maps\*.gui.dso" "slideshow_editor\*.gui.dso" -spf -y
    } finally {
        Pop-Location
    }
}
