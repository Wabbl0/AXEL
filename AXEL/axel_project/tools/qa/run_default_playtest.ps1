# Run default QA playtest gates; prints QA_PLAYTEST_RESULT lines.
$ErrorActionPreference = "Continue"
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$repo = Split-Path (Split-Path $root -Parent) -Parent
Set-Location $repo

$godot = Join-Path $repo "tools\cmd\godot.cmd"
$proj = "--headless --path AXEL/axel_project -s"

$commands = @(
    @{ key = "princess_check"; script = "res://combat/test/princess_check.gd" },
    @{ key = "determinism"; script = "res://combat/test/determinism_check.gd" },
    @{ key = "rtp_audit"; script = "res://combat/test/rtp_audit.gd"; metrics_only = $true },
    @{ key = "scene_smoke"; script = "res://tools/scene_smoke_check.gd" },
    @{ key = "background_fit"; script = "res://scenes/core/test/background_fit_check.gd" },
    @{ key = "player_cover_sync"; script = "res://scenes/core/test/player_cover_sync_check.gd" },
    @{ key = "player_walk_speed"; script = "res://scenes/core/test/player_walk_speed_check.gd" },
    @{ key = "player_spawn_sync"; script = "res://scenes/core/test/player_spawn_sync_check.gd" },
    @{ key = "interact_arrival"; script = "res://scenes/core/test/interact_arrival_check.gd" },
    @{ key = "corridor_depth_seed"; script = "res://scenes/core/test/corridor_depth_seed_check.gd" },
    @{ key = "combat_test_scaffold"; script = "res://combat/test/combat_test_scaffold_check.gd" },
    @{ key = "audio_bus_layout"; script = "res://tools/qa/audio_bus_layout_check.gd" },
    @{ key = "settings_persistence"; script = "res://tools/qa/settings_persistence_check.gd" },
    @{ key = "pause_contract"; script = "res://tools/qa/pause_contract_check.gd" },
    @{ key = "canon_consistency_audit"; script = "res://tools/qa/canon_consistency_audit.gd"; metrics_only = $true },
    @{ key = "bot_arc1_exterior"; script = "res://tools/bots/playthrough_arc1_exterior.gd" },
    @{ key = "bot_dialogue_loop"; script = "res://tools/bots/playthrough_dialogue_loop.gd" }
)

foreach ($cmd in $commands) {
    $outFile = [System.IO.Path]::GetTempFileName()
    & $godot @($proj.Split(" ") + $cmd.script) 2>&1 | Tee-Object -FilePath $outFile
    $exit = $LASTEXITCODE
    $status = if ($exit -eq 0) { "pass" } else { "fail" }
  if ($cmd.metrics_only) { $status = "pass" }
    Write-Output "QA_PLAYTEST_RESULT $($cmd.key)=$status exit=$exit"
    if ($cmd.key -eq "canon_consistency_audit") {
        Select-String -Path $outFile -Pattern "CANON_AUDIT_JSON" | ForEach-Object { $_.Line }
    }
    if ($cmd.key -eq "rtp_audit") {
        Select-String -Path $outFile -Pattern "RTP_AUDIT_JSON" | ForEach-Object { $_.Line }
    }
    Remove-Item $outFile -Force -ErrorAction SilentlyContinue
}

$itemsDir = "AXEL/axel_project/combat/data/items"
if (Test-Path $itemsDir) {
    $files = Get-ChildItem $itemsDir -Recurse -File -ErrorAction SilentlyContinue
    if ($files.Count -gt 0) {
        & $godot @($proj.Split(" ") + "res://combat/test/item_balance_audit.gd") 2>&1 | Out-Null
        $ibExit = $LASTEXITCODE
        Write-Output "QA_PLAYTEST_RESULT item_balance_audit=pass exit=$ibExit"
        & $godot @($proj.Split(" ") + "res://combat/test/item_synergy_smoke.gd") 2>&1 | Out-Null
        $isExit = $LASTEXITCODE
        $isStatus = if ($isExit -eq 0) { "pass" } else { "fail" }
        Write-Output "QA_PLAYTEST_RESULT item_synergy_smoke=$isStatus exit=$isExit"
    } else {
        Write-Output "QA_PLAYTEST_RESULT item_balance_audit=skip"
    }
} else {
    Write-Output "QA_PLAYTEST_RESULT item_balance_audit=skip"
}
