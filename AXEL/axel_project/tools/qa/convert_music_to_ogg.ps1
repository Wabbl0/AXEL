

$ErrorActionPreference = "Stop"
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$music = Join-Path $root "assets\audio\music"
$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
    Write-Output "ffmpeg not found; skip Ogg conversion"
    exit 0
}
Get-ChildItem $music -Filter "*.wav" | ForEach-Object {
    $out = Join-Path $_.DirectoryName ($_.BaseName + ".ogg")
    if ((Test-Path $out) -and ((Get-Item $out).Length -gt 1024)) {
        Write-Output "exists $($_.Name) -> $(Split-Path $out -Leaf)"
        return
    }
    & ffmpeg -y -i $_.FullName -c:a libvorbis -q:a 6 $out
    Write-Output "wrote $(Split-Path $out -Leaf) ($((Get-Item $out).Length))"
}
Write-Output "convert_music_to_ogg done"
