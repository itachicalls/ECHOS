Add-Type -AssemblyName System.Drawing
$town = "c:\Users\smyde\memoir\echo-valley\assets\kenney\tiny_town_sheet.png"
$gendir = "c:\Users\smyde\memoir\echo-valley\assets\kenney\gen"
New-Item -ItemType Directory -Force -Path $gendir | Out-Null
$src = [System.Drawing.Bitmap]::FromFile($town)

function Avg($bmp, $x0, $y0, $w, $h) {
  $r=0;$g=0;$b=0;$n=0
  for ($x=$x0; $x -lt $x0+$w; $x++){ for ($y=$y0; $y -lt $y0+$h; $y++){
    $p=$bmp.GetPixel($x,$y); if($p.A -lt 128){continue}; $r+=$p.R;$g+=$p.G;$b+=$p.B;$n++ } }
  if($n -eq 0){ return [System.Drawing.Color]::FromArgb(255,90,140,60) }
  return [System.Drawing.Color]::FromArgb(255, [int]($r/$n), [int]($g/$n), [int]($b/$n))
}
function Shade($c, $f) {
  $r=[math]::Max(0,[math]::Min(255,[int]($c.R*$f)))
  $g=[math]::Max(0,[math]::Min(255,[int]($c.G*$f)))
  $b=[math]::Max(0,[math]::Min(255,[int]($c.B*$f)))
  return [System.Drawing.Color]::FromArgb(255,$r,$g,$b)
}

# sample real grass + dirt tones from the tiny-town sheet
$grass = Avg $src 18 2 12 12       # tile (1,0) plain grass
$dirt  = Avg $src 18 34 12 12      # tile (1,2) dirt
$src.Dispose()
$gDark = Shade $grass 0.82; $gLite = Shade $grass 1.14
$dDark = Shade $dirt  0.80; $dLite = Shade $dirt  1.16
$rng = New-Object System.Random 1337

# ---- textured grass tile (16x16) ----
$gf = New-Object System.Drawing.Bitmap 16,16
for($x=0;$x -lt 16;$x++){for($y=0;$y -lt 16;$y++){ $gf.SetPixel($x,$y,$grass) }}
for($i=0;$i -lt 46;$i++){
  $x=$rng.Next(16);$y=$rng.Next(16)
  $c = if($rng.Next(2) -eq 0){$gDark}else{$gLite}
  $gf.SetPixel($x,$y,$c)
}
for($i=0;$i -lt 8;$i++){ # little blades
  $x=$rng.Next(16);$y=$rng.Next(14)
  $gf.SetPixel($x,$y,$gDark); $gf.SetPixel($x,$y+1,$gDark)
}
$gf.Save((Join-Path $gendir "grass_field.png")); $gf.Dispose()

# ---- 16-case dirt-path autotile (4x4 = 64x64) ----
# mask bits: 1=N connected, 2=E, 4=S, 8=W  (connected side = dirt runs to edge)
$atlas = New-Object System.Drawing.Bitmap 64,64
for($mask=0; $mask -lt 16; $mask++){
  $ox = ($mask % 4) * 16
  $oy = [math]::Floor($mask / 4) * 16
  $cN = ($mask -band 1) -ne 0
  $cE = ($mask -band 2) -ne 0
  $cS = ($mask -band 4) -ne 0
  $cW = ($mask -band 8) -ne 0
  # base dirt + pebble texture
  for($x=0;$x -lt 16;$x++){for($y=0;$y -lt 16;$y++){ $atlas.SetPixel($ox+$x,$oy+$y,$dirt) }}
  for($i=0;$i -lt 20;$i++){
    $x=$rng.Next(16);$y=$rng.Next(16)
    $c = if($rng.Next(2) -eq 0){$dDark}else{$dLite}
    $atlas.SetPixel($ox+$x,$oy+$y,$c)
  }
  # a couple 2px pebbles
  for($i=0;$i -lt 3;$i++){
    $x=$rng.Next(14);$y=$rng.Next(14)
    $atlas.SetPixel($ox+$x,$oy+$y,$dDark);$atlas.SetPixel($ox+$x+1,$oy+$y,$dDark)
    $atlas.SetPixel($ox+$x,$oy+$y+1,$dLite)
  }
  $band = 5
  # paint grass on each OPEN (not connected) side with an irregular edge
  if(-not $cN){ for($x=0;$x -lt 16;$x++){ $d=$band+$rng.Next(-1,2); for($y=0;$y -lt $d;$y++){ $atlas.SetPixel($ox+$x,$oy+$y,$grass) } } }
  if(-not $cS){ for($x=0;$x -lt 16;$x++){ $d=$band+$rng.Next(-1,2); for($y=16-$d;$y -lt 16;$y++){ $atlas.SetPixel($ox+$x,$oy+$y,$grass) } } }
  if(-not $cW){ for($y=0;$y -lt 16;$y++){ $d=$band+$rng.Next(-1,2); for($x=0;$x -lt $d;$x++){ $atlas.SetPixel($ox+$x,$oy+$y,$grass) } } }
  if(-not $cE){ for($y=0;$y -lt 16;$y++){ $d=$band+$rng.Next(-1,2); for($x=16-$d;$x -lt 16;$x++){ $atlas.SetPixel($ox+$x,$oy+$y,$grass) } } }
  # sprinkle grass specks over the grass regions for texture
  for($i=0;$i -lt 16;$i++){
    $x=$rng.Next(16);$y=$rng.Next(16)
    if($atlas.GetPixel($ox+$x,$oy+$y).ToArgb() -eq $grass.ToArgb()){
      $c = if($rng.Next(2) -eq 0){$gDark}else{$gLite}
      $atlas.SetPixel($ox+$x,$oy+$y,$c)
    }
  }
}
$atlas.Save((Join-Path $gendir "path_set.png")); $atlas.Dispose()

# ---- 16-case cobblestone autotile (gray plaza w/ grass edges) ----
$stone = [System.Drawing.Color]::FromArgb(255,140,146,158)
$sDark = Shade $stone 0.70; $sLite = Shade $stone 1.15
$catlas = New-Object System.Drawing.Bitmap 64,64
for($mask=0; $mask -lt 16; $mask++){
  $ox = ($mask % 4) * 16
  $oy = [math]::Floor($mask / 4) * 16
  $cN = ($mask -band 1) -ne 0; $cE = ($mask -band 2) -ne 0
  $cS = ($mask -band 4) -ne 0; $cW = ($mask -band 8) -ne 0
  for($x=0;$x -lt 16;$x++){for($y=0;$y -lt 16;$y++){ $catlas.SetPixel($ox+$x,$oy+$y,$stone) }}
  # mortar grid + cobble highlights
  for($x=0;$x -lt 16;$x++){for($y=0;$y -lt 16;$y++){
    if(((($x+ ($y -band 1)*2) % 4) -eq 0) -or (($y % 4) -eq 0)){ $catlas.SetPixel($ox+$x,$oy+$y,$sDark) }
  }}
  for($i=0;$i -lt 14;$i++){ $x=$rng.Next(16);$y=$rng.Next(16); $catlas.SetPixel($ox+$x,$oy+$y,$sLite) }
  $band = 4
  if(-not $cN){ for($x=0;$x -lt 16;$x++){ $d=$band+$rng.Next(-1,2); for($y=0;$y -lt $d;$y++){ $catlas.SetPixel($ox+$x,$oy+$y,$grass) } } }
  if(-not $cS){ for($x=0;$x -lt 16;$x++){ $d=$band+$rng.Next(-1,2); for($y=16-$d;$y -lt 16;$y++){ $catlas.SetPixel($ox+$x,$oy+$y,$grass) } } }
  if(-not $cW){ for($y=0;$y -lt 16;$y++){ $d=$band+$rng.Next(-1,2); for($x=0;$x -lt $d;$x++){ $catlas.SetPixel($ox+$x,$oy+$y,$grass) } } }
  if(-not $cE){ for($y=0;$y -lt 16;$y++){ $d=$band+$rng.Next(-1,2); for($x=16-$d;$x -lt 16;$x++){ $catlas.SetPixel($ox+$x,$oy+$y,$grass) } } }
  for($i=0;$i -lt 12;$i++){ $x=$rng.Next(16);$y=$rng.Next(16)
    if($catlas.GetPixel($ox+$x,$oy+$y).ToArgb() -eq $grass.ToArgb()){
      $c = if($rng.Next(2) -eq 0){$gDark}else{$gLite}; $catlas.SetPixel($ox+$x,$oy+$y,$c) } }
}
$catlas.Save((Join-Path $gendir "cobble_set.png")); $catlas.Dispose()

Write-Output ("grass={0},{1},{2}  dirt={3},{4},{5}" -f $grass.R,$grass.G,$grass.B,$dirt.R,$dirt.G,$dirt.B)
Write-Output "DONE path_set.png + grass_field.png + cobble_set.png"
