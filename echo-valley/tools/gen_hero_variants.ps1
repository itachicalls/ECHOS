# Playable hero variants — same 64x128 hero-layout sheets via exact-palette recolor.
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$heroPath = Join-Path $root "assets\sprites\hero.png"
$outDir = Join-Path $root "assets\sprites"

$HAIR_L = @(106,72,52);  $HAIR_D = @(67,46,39)
$SKIN_L = @(232,212,178); $SKIN_D = @(191,167,135)
$SHIRT_L = @(196,60,60); $SHIRT_M = @(136,46,46); $SHIRT_D = @(104,28,28)
$PANTS_D = @(42,42,52);  $PANTS_H = @(101,101,155)
$ACCENT  = @(85,134,185)

function Key($c) { "{0},{1},{2}" -f $c[0],$c[1],$c[2] }
function Shade($base, $f) {
  @([Math]::Min(255,[int]($base[0]*$f)), [Math]::Min(255,[int]($base[1]*$f)), [Math]::Min(255,[int]($base[2]*$f)))
}

function Build-Map($shirt, $hair, $pants, $skin, $accent) {
  $m = @{}
  $m[(Key $SHIRT_L)] = (Shade $shirt 1.15)
  $m[(Key $SHIRT_M)] = (Shade $shirt 0.78)
  $m[(Key $SHIRT_D)] = (Shade $shirt 0.50)
  $m[(Key $HAIR_L)]  = $hair
  $m[(Key $HAIR_D)]  = (Shade $hair 0.62)
  $m[(Key $PANTS_D)] = $pants
  $m[(Key $PANTS_H)] = (Shade $pants 1.7)
  if ($accent) { $m[(Key $ACCENT)] = $accent }
  if ($skin) {
    $m[(Key $SKIN_L)] = $skin
    $m[(Key $SKIN_D)] = (Shade $skin 0.82)
  }
  return $m
}

# keeper = original hero.png (no file). curly = pink dress + golden curls. cap = darker skin + street cap fit.
$variants = @(
  @{
    n = "hero_curly"
    shirt = @(236, 132, 168)   # pink dress top
    hair  = @(210, 148, 88)    # warm curly gold
    pants = @(188, 88, 128)    # dress hem
    skin  = @(242, 210, 188)
    accent = @(255, 220, 200)
  }
  @{
    n = "hero_cap"
    shirt = @(58, 118, 168)    # cool jacket
    hair  = @(36, 40, 58)      # cap / dark hair
    pants = @(34, 38, 52)
    skin  = @(148, 108, 82)    # darker skin tone
    accent = @(230, 200, 120)
  }
)

$hero = [System.Drawing.Bitmap]::FromFile($heroPath)
$W = $hero.Width; $H = $hero.Height
foreach ($v in $variants) {
  $map = Build-Map $v.shirt $v.hair $v.pants $v.skin $v.accent
  $out = New-Object System.Drawing.Bitmap($W, $H)
  for ($y=0; $y -lt $H; $y++) {
    for ($x=0; $x -lt $W; $x++) {
      $c = $hero.GetPixel($x,$y)
      if ($c.A -lt 20) { $out.SetPixel($x,$y,[System.Drawing.Color]::FromArgb(0,0,0,0)); continue }
      $k = "{0},{1},{2}" -f $c.R,$c.G,$c.B
      if ($map.ContainsKey($k)) {
        $t = $map[$k]
        $out.SetPixel($x,$y,[System.Drawing.Color]::FromArgb($c.A,$t[0],$t[1],$t[2]))
      } else {
        $out.SetPixel($x,$y,$c)
      }
    }
  }
  $dest = Join-Path $outDir ($v.n + ".png")
  $out.Save($dest, [System.Drawing.Imaging.ImageFormat]::Png)
  $out.Dispose()
  Write-Host "wrote $dest"
}
$hero.Dispose()
Write-Host "done"
