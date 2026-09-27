<#
.SYNOPSIS
    Rewrite tcc's stdcall-decorated export names (_Name@N) to bare names.

.DESCRIPTION
    tcc compiles __stdcall exports with decorated names (_Direct3DCreate9@4,
    _D3DPERF_BeginEvent@8, ...). The game's import table expects the bare
    names. This script rewrites the decorated strings in place inside the
    built DLL: the decoration is stripped and the remainder padded with NUL,
    so every export name lands exactly where the export directory points.

    Only the four known proxy exports are touched, and each must occur
    exactly once, or the script fails loudly.

.PARAMETER Path
    The d3d9.dll to patch (in place).

.EXAMPLE
    powershell -NoProfile -File undecorate_exports.ps1 d3d9.dll
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

$ErrorActionPreference = "Stop"

$decorated = @(
    "_Direct3DCreate9@4",
    "_D3DPERF_BeginEvent@8",
    "_D3DPERF_EndEvent@0",
    "_D3DPERF_SetMarker@8"
)

$bytes = [System.IO.File]::ReadAllBytes($Path)
$patched = 0

foreach ($name in $decorated) {
    $needle = [System.Text.Encoding]::ASCII.GetBytes($name)
    $bare = [System.Text.Encoding]::ASCII.GetBytes($name.Substring(1, $name.IndexOf('@') - 1))

    $hits = @()
    for ($i = 0; $i -le $bytes.Length - $needle.Length; $i++) {
        $ok = $true
        for ($j = 0; $j -lt $needle.Length; $j++) {
            if ($bytes[$i + $j] -ne $needle[$j]) { $ok = $false; break }
        }
        if ($ok) { $hits += $i }
    }
    if ($hits.Count -ne 1) {
        throw "Expected exactly 1 occurrence of '$name', found $($hits.Count). Refusing to patch."
    }

    $offset = $hits[0]
    for ($j = 0; $j -lt $bare.Length; $j++) { $bytes[$offset + $j] = $bare[$j] }
    $bytes[$offset + $bare.Length] = 0    # NUL-terminate the shorter name
    $patched++
}

[System.IO.File]::WriteAllBytes($Path, $bytes)
Write-Host "undecorated $patched/$($decorated.Count) exports in $Path"
