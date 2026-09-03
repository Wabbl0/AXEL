# Scans capture PNGs and prints size + mean luminance so blank/broken frames
# stand out (mean ~0 = black frame, ~255 = white frame; noir rooms sit ~5-45).
#   powershell -File AXEL/axel_project/tools/qa/scan_captures.ps1 [-Dir out/captures/matrix]
param([string]$Dir = "")

$proj = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$repo = Split-Path (Split-Path $proj -Parent) -Parent
if ($Dir -eq "") { $Dir = Join-Path $repo "out/captures/matrix" }

Add-Type -AssemblyName System.Drawing
Get-ChildItem $Dir -Filter *.png | Sort-Object Name | ForEach-Object {
    $bmp = [System.Drawing.Bitmap]::FromFile($_.FullName)
    # Sample a 64x64 grid (fast, good enough for a blank-frame heuristic).
    $sum = 0.0; $n = 0
    $stepX = [Math]::Max(1, [int]($bmp.Width / 64))
    $stepY = [Math]::Max(1, [int]($bmp.Height / 64))
    for ($y = 0; $y -lt $bmp.Height; $y += $stepY) {
        for ($x = 0; $x -lt $bmp.Width; $x += $stepX) {
            $p = $bmp.GetPixel($x, $y)
            $sum += ($p.R * 0.299 + $p.G * 0.587 + $p.B * 0.114)
            $n++
        }
    }
    $mean = [Math]::Round($sum / $n, 1)
    $flag = ""
    if ($mean -lt 1.5) { $flag = " FLAG_BLACK" }
    elseif ($mean -gt 240) { $flag = " FLAG_WHITE" }
    Write-Output ("CAPTURE_SCAN {0} {1}x{2} mean={3}{4}" -f $_.Name, $bmp.Width, $bmp.Height, $mean, $flag)
    $bmp.Dispose()
}
