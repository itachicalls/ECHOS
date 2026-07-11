# Exports the Echo Valley web build using Godot 4.7.
$ErrorActionPreference = "Stop"

$godot = "C:\Users\smyde\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"
$proj = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $proj "build\web"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Write-Host "Importing project..."
& $godot --headless --path $proj --import | Out-Null

Write-Host "Exporting Web build..."
& $godot --headless --path $proj --export-release "Web" (Join-Path $outDir "index.html")

if (Test-Path (Join-Path $outDir "index.html")) {
  Write-Host "Export complete -> $outDir"
} else {
  Write-Error "Export failed: index.html not produced."
}
