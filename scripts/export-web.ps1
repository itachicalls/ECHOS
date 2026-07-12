$ErrorActionPreference = "Stop"

$godot = "C:\Users\smyde\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"
$templatesDir = Join-Path $env:APPDATA "Godot\export_templates\4.7.stable"
$tpz = Join-Path $env:TEMP "Godot_v4.7-stable_export_templates.tpz"
$repo = Split-Path $PSScriptRoot -Parent
$project = Join-Path $repo "echo-valley"

if (-not (Test-Path $godot)) {
  throw "Godot not found at $godot"
}

if (-not (Test-Path (Join-Path $templatesDir "web_release.zip"))) {
  Write-Host "Downloading Godot 4.7 web export templates..."
  New-Item -ItemType Directory -Force -Path $templatesDir | Out-Null
  if (-not (Test-Path $tpz)) {
    Invoke-WebRequest -Uri "https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_export_templates.tpz" -OutFile $tpz
  }
  $zip = "$tpz.zip"
  Copy-Item $tpz $zip -Force
  $extractDir = Join-Path $templatesDir "_extract"
  if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
  Expand-Archive -Path $zip -DestinationPath $extractDir -Force
  Get-ChildItem (Join-Path $extractDir "templates") -File | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $templatesDir $_.Name) -Force
  }
  Remove-Item $extractDir -Recurse -Force
}

$outDir = Join-Path $repo "build\web"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Write-Host "Exporting Echo Valley for Web..."
& $godot --headless --path $project --export-release "Web" (Join-Path $outDir "index.html")
if ($LASTEXITCODE -ne 0) {
  throw "Web export failed with exit code $LASTEXITCODE"
}

Write-Host "Web export complete: build/web/index.html"

# Ensure the canvas fills mobile viewports (no tiny letterboxed strip).
$htmlPath = Join-Path $outDir "index.html"
if (Test-Path $htmlPath) {
  $html = Get-Content $htmlPath -Raw
  if ($html -notmatch 'canvas-fullscreen-fix') {
    $inject = @'
<style id="canvas-fullscreen-fix">
html,body,#canvas,canvas{width:100%!important;height:100%!important;max-width:100vw;max-height:100vh;}
</style>
'@
    $html = $html -replace '</head>', ($inject + "`n</head>")
    Set-Content -Path $htmlPath -Value $html -NoNewline
    Write-Host "Patched index.html for full-viewport mobile canvas."
  }
}
