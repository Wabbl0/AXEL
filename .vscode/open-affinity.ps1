param(
  [string]$Path
)

$affinityExe = "C:\Program Files\WindowsApps\Canva.Affinity_3.1.0.4231_x64__8a0j1tnjnt4a4\App\Affinity.exe"

if (-not (Test-Path $affinityExe)) {
  Write-Error "Affinity executable not found: $affinityExe"
  exit 1
}

if (-not $Path) {
  try {
    $Path = Get-Clipboard -Raw
  } catch {
    $Path = $null
  }
}

if (-not $Path) {
  Write-Error "No image path provided. Pass -Path or copy a file path to clipboard first."
  exit 1
}

$Path = $Path.Trim().Trim('"').Trim("'")

if (-not (Test-Path $Path)) {
  Write-Error "File does not exist: $Path"
  exit 1
}

Start-Process -FilePath $affinityExe -ArgumentList @($Path)
