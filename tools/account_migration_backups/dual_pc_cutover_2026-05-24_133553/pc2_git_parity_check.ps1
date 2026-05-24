param(
  [string] = "C:\Users\valtt\OneDrive\Godot",
  [string] = "c99e410edd8d3580ae5ba4bc4d09d649bddb341a"
)

Set-Location 
git fetch --all --prune
git checkout main
git pull --ff-only
 = git rev-parse HEAD
 = git rev-list --left-right --count origin/main...main
Write-Output "CurrentCommit="
Write-Output "ExpectedCommit="
Write-Output "AheadBehind="
if ( -ne ) {
  Write-Error "Commit mismatch. Do not proceed with account retirement."
  exit 1
}
Write-Output "Parity check passed."
