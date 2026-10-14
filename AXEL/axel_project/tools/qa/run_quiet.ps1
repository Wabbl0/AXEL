param(
    [string]$Script = "",
    [int]$QuitAfter = 0,
    [string[]]$UserArgs = @()
)

$ErrorActionPreference = "Continue"
$proj = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$repo = Split-Path (Split-Path $proj -Parent) -Parent

$godot = Join-Path $repo "Godot_v4.7.2-stable_win64_console.exe"
if (-not (Test-Path $godot)) {
    Write-Error "Console Godot exe not found at $godot"
    exit 1
}

$overrideText = "[display]`r`n`r`nwindow/size/no_focus=true`r`n"
$overridePath = Join-Path $proj "override.cfg"
$ownsOverride = $false
if (-not (Test-Path $overridePath)) {
    [System.IO.File]::WriteAllText($overridePath, $overrideText)
    $ownsOverride = $true
}

$godotArgs = @("--path", $proj, "--resolution", "64x64", "--position", "0,0")
if ($QuitAfter -gt 0) {
    $godotArgs += @("--quit-after", "$QuitAfter")
}
if ($Script -ne "") {
    $godotArgs += @("-s", $Script)
}
$godotArgs += @("--", "--capture") + $UserArgs

try {
    & $godot @godotArgs 2>&1 | ForEach-Object { $_ }
    $code = $LASTEXITCODE
} finally {
    if ($ownsOverride -and (Test-Path $overridePath)) {
        Remove-Item $overridePath -Force
    }
}
exit $code
