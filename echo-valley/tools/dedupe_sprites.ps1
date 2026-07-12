# ============================================================================
# Fix duplicate Harmon art: some original echoes share byte-identical sprites
# under different names/types. This groups every echo by the MD5 of its FRONT
# sprite; for each group after the first id, it applies a deterministic hue
# rotation to BOTH front and back sprites so every Harmon (and every evolved
# form) is a visually unique asset. The canonical (first) id in each group is
# left untouched.
#   -Apply   actually writes recolored PNGs (otherwise report-only / dry run)
# ============================================================================
param([switch]$Apply)
Add-Type -AssemblyName System.Drawing

$root      = "c:\Users\smyde\memoir\echo-valley"
$echoesDir = Join-Path $root "assets\echoes"
$dataFile  = Join-Path $root "data\echoes.json"

$echoes = Get-Content $dataFile -Raw | ConvertFrom-Json

function FileHash($p) {
  if (-not (Test-Path $p)) { return $null }
  return (Get-FileHash -Path $p -Algorithm MD5).Hash
}

# group ids by front-sprite hash (in JSON order)
$groups = [ordered]@{}
foreach ($e in $echoes) {
  $spr = Join-Path $echoesDir ("{0}.png" -f $e.id)
  $h = FileHash $spr
  if ($null -eq $h) { Write-Warning ("missing front sprite: " + $e.id); continue }
  if (-not $groups.Contains($h)) { $groups[$h] = @() }
  $groups[$h] += $e.id
}

$dupGroups = @()
foreach ($h in $groups.Keys) { if ($groups[$h].Count -gt 1) { $dupGroups += ,$groups[$h] } }

$dupFiles = 0
foreach ($g in $dupGroups) { $dupFiles += ($g.Count - 1) }
Write-Output ("duplicate groups: " + $dupGroups.Count + "   redundant ids to recolor: " + $dupFiles)
foreach ($g in $dupGroups) { Write-Output ("  [" + ($g -join ", ") + "]") }

if (-not $Apply) { Write-Output "DRY RUN (pass -Apply to recolor)"; return }

# --- hue rotation preserving alpha & luma-ish ------------------------------
function RotateHue([System.Drawing.Bitmap]$bmp, [double]$deg) {
  $w = $bmp.Width; $h = $bmp.Height
  $rect = New-Object System.Drawing.Rectangle 0,0,$w,$h
  $bd = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $bytes = $w * $h * 4
  $buf = New-Object byte[] $bytes
  [System.Runtime.InteropServices.Marshal]::Copy($bd.Scan0, $buf, 0, $bytes)
  $rad = $deg * [Math]::PI / 180.0
  $cos = [Math]::Cos($rad); $sin = [Math]::Sin($rad)
  # YIQ hue-rotation matrix coefficients
  for ($i = 0; $i -lt $bytes; $i += 4) {
    $b = $buf[$i]; $g = $buf[$i+1]; $r = $buf[$i+2]; $a = $buf[$i+3]
    if ($a -eq 0) { continue }
    $rr = $r/255.0; $gg = $g/255.0; $bb = $b/255.0
    $nr = (0.299 + 0.701*$cos + 0.168*$sin)*$rr + (0.587 - 0.587*$cos + 0.330*$sin)*$gg + (0.114 - 0.114*$cos - 0.497*$sin)*$bb
    $ng = (0.299 - 0.299*$cos - 0.328*$sin)*$rr + (0.587 + 0.413*$cos + 0.035*$sin)*$gg + (0.114 - 0.114*$cos + 0.292*$sin)*$bb
    $nb = (0.299 - 0.300*$cos + 1.250*$sin)*$rr + (0.587 - 0.588*$cos - 1.050*$sin)*$gg + (0.114 + 0.886*$cos - 0.203*$sin)*$bb
    $buf[$i]   = [byte][Math]::Max(0,[Math]::Min(255,[Math]::Round($nb*255)))
    $buf[$i+1] = [byte][Math]::Max(0,[Math]::Min(255,[Math]::Round($ng*255)))
    $buf[$i+2] = [byte][Math]::Max(0,[Math]::Min(255,[Math]::Round($nr*255)))
  }
  [System.Runtime.InteropServices.Marshal]::Copy($buf, 0, $bd.Scan0, $bytes)
  $bmp.UnlockBits($bd)
}

function RecolorFile($path, $deg) {
  if (-not (Test-Path $path)) { return }
  $img = [System.Drawing.Bitmap]::FromFile($path)
  $bmp = New-Object System.Drawing.Bitmap $img.Width, $img.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.DrawImage($img, 0, 0, $img.Width, $img.Height)
  $g.Dispose(); $img.Dispose()
  RotateHue $bmp $deg
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

$recolored = 0
foreach ($g in $dupGroups) {
  for ($k = 1; $k -lt $g.Count; $k++) {
    $id = $g[$k]
    # spread hues evenly across the group so every variant is clearly distinct
    $deg = [double](($k * 360.0 / $g.Count) + ($k * 47))
    $deg = $deg % 360.0
    RecolorFile (Join-Path $echoesDir ("{0}.png" -f $id)) $deg
    RecolorFile (Join-Path $echoesDir ("{0}_back.png" -f $id)) $deg
    $recolored++
    Write-Output ("  recolored " + $id + "  (+" + [int]$deg + " deg)")
  }
}
Write-Output ("DONE. recolored " + $recolored + " harmons.")
