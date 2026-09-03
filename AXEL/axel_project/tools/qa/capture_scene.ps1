# Generic scene-to-PNG capture driver (Master Build Plan Phase 0.1).
# Runs Godot WINDOWED (never headless) via the console exe so stdout is visible.
#
# Examples (from anywhere):
#   powershell -File AXEL/axel_project/tools/qa/capture_scene.ps1 -Scene res://scenes/Main_Menu/0.1_MainMenu.tscn -Out out/menu.png
#   powershell -File ...capture_scene.ps1 -Scene res://combat/combat_test.tscn -Out out/hud_4k.png -Size 3840x2160 -Frames 90 -Mode borderless
#
# Optional env before calling (forwarded to the game): AXEL_SKIP_INTRO=1,
# AXEL_DISABLE_POST_FX=1, AXEL_DISABLE_EVENT_FX=1, AXEL_DISABLE_MUSIC=1.
param(
    [Parameter(Mandatory = $true)][string]$Scene,
    [Parameter(Mandatory = $true)][string]$Out,
    [int]$Frames = 60,
    [string]$Size = "1920x1280",
    [ValidateSet("windowed", "borderless", "fullscreen")][string]$Mode = "windowed"
)

$ErrorActionPreference = "Continue"
$proj = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent    # tools/qa -> tools -> AXEL/axel_project
$repo = Split-Path (Split-Path $proj -Parent) -Parent            # AXEL/axel_project -> AXEL -> repo root

$godot = Join-Path $repo "Godot_v4.7.2-stable_win64_console.exe"
if (-not (Test-Path $godot)) {
    Write-Error "Console Godot exe not found at $godot"
    exit 1
}

# Resolve output to an absolute path unless it is a Godot virtual path.
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
