# Phase 0.3 resolution sweep: captures every real scene at the five target
# sizes (windowed). Wraps capture_scene.ps1. PNGs land in out/captures/matrix/.
#
#   powershell -File AXEL/axel_project/tools/qa/capture_matrix.ps1
#   powershell -File ...capture_matrix.ps1 -Sizes @("1920x1080") -Scenes @("res://scenes/Arc_1/1.2_Corridor.tscn")
param(
    [string[]]$Sizes = @("1366x768", "1920x1080", "1920x1200", "2560x1440", "3840x2160"),
    [string[]]$Scenes = @(
        "res://scenes/Main_Menu/0.1_MainMenu.tscn",
        "res://scenes/Arc_1/1.1_SchoolExterior.tscn",
        "res://scenes/Arc_1/1.2_Corridor.tscn",
        "res://scenes/Arc_1/1.3_LockerHub.tscn",
        "res://scenes/Arc_1/1.3_SchoolMap.tscn",
        "res://scenes/Arc_1/1.4_BasementDoor.tscn",
        "res://scenes/Arc_2/2.1_Cafeteria.tscn",
        "res://scenes/Arc_2/2.2_CafeteriaMemory.tscn",
        "res://scenes/Arc_2/2.3_Kitchen.tscn",
        "res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn",
        "res://scenes/Arc_3/3.1_Backyard.tscn",
        "res://scenes/Arc_3/3.2_BackyardMemory.tscn",
        "res://scenes/Arc_4/4.1_TeachersLounge.tscn",
        "res://scenes/Arc_4/4.2_TeachersMemory.tscn",
        "res://scenes/Arc_5/5.1_Classroom.tscn",
        "res://scenes/Arc_5/5.2_ClassroomDesk.tscn",
        "res://scenes/Endings/7.1_Ending1.tscn",
        "res://combat/combat_test.tscn"
    ),
    [int]$Frames = 150,
    [string]$OutDir = ""
)

$ErrorActionPreference = "Continue"
$proj = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$repo = Split-Path (Split-Path $proj -Parent) -Parent
if ($OutDir -eq "") { $OutDir = Join-Path $repo "out/captures/matrix" }
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

# 1.1 forced intro takes ~10s; skip it so the capture shows free-roam state.
$env:AXEL_SKIP_INTRO = "1"

$fail = 0
$total = 0
foreach ($scene in $Scenes) {
    $sceneName = [System.IO.Path]::GetFileNameWithoutExtension($scene)
    foreach ($size in $Sizes) {
        $total++
        $out = Join-Path $OutDir "$sceneName`_$size.png"
        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "capture_scene.ps1") `
            -Scene $scene -Out $out -Size $size -Frames $Frames 2>&1 |
            Select-String -Pattern "CAPTURE_OK|CAPTURE_DRIVER_RESULT status=fail" |
            ForEach-Object { $_.Line }
        if ($LASTEXITCODE -ne 0) {
            $fail++
            Write-Output "MATRIX_FAIL scene=$sceneName size=$size"
        }
    }
}
Remove-Item Env:AXEL_SKIP_INTRO -ErrorAction SilentlyContinue

Write-Output "MATRIX_DONE total=$total failed=$fail out=$OutDir"
if ($fail -gt 0) { exit 1 } else { exit 0 }
