


param(
    [Parameter(Mandatory = $true)][string]$Scene,
    [Parameter(Mandatory = $true)][string]$Out,
    [int]$Frames = 60,
    [string]$Size = "1920x1280",
    [ValidateSet("windowed", "borderless", "fullscreen")][string]$Mode = "windowed"
)

$ErrorActionPreference = "Continue"
$proj = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$repo = Split-Path (Split-Path $proj -Parent) -Parent

$godot = Join-Path $repo "Godot_v4.7.2-stable_win64_console.exe"
if (-not (Test-Path $godot)) {
    Write-Error "Console Godot exe not found at $godot"
    exit 1
}


if ($Out -notmatch "^(user|res)://") {
    if (-not [System.IO.Path]::IsPathRooted($Out)) {
        $Out = Join-Path (Get-Location).Path $Out
    }
    $Out = [System.IO.Path]::GetFullPath($Out)
    $outDir = Split-Path $Out -Parent
    if ($outDir -and -not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }
}

& $godot --path (Join-Path $repo "AXEL/axel_project") -s res://tools/qa/capture_scene.gd -- `
    "--scene=$Scene" "--out=$Out" "--frames=$Frames" "--size=$Size" "--mode=$Mode" 2>&1 |
    ForEach-Object { $_ }
$code = $LASTEXITCODE
if ($code -eq 0) {
    Write-Output "CAPTURE_DRIVER_RESULT status=pass out=$Out"
} else {
    Write-Output "CAPTURE_DRIVER_RESULT status=fail exit=$code"
}
exit $code
