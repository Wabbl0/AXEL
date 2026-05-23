# Run Scene 1.1 visual style screenshot sweep (all variants).
$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")
Set-Location $repoRoot

$godot = Join-Path $repoRoot "tools\cmd\godot.cmd"
$project = "AXEL\axel_project"

Write-Host "Running Scene 1.1 style sweep..."
& $godot --path $project -s res://tools/visual_style/capture_scene_1_1_style_sweep.gd
exit $LASTEXITCODE
