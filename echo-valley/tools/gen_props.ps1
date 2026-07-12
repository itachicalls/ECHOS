Add-Type -AssemblyName System.Drawing
# Generates small themed props for the expansion regions.
$out = "c:\Users\smyde\memoir\echo-valley\assets\kenney\props"
New-Item -ItemType Directory -Force -Path $out | Out-Null

function NewBmp($w, $h) {
  $b = New-Object System.Drawing.Bitmap $w, $h
  return $b
}
function Px($b, $x, $y, $col) {
  if ($x -ge 0 -and $y -ge 0 -and $x -lt $b.Width -and $y -lt $b.Height) { $b.SetPixel($x, $y, $col) }
}
function C($r,$g,$bl,$a=255) { return [System.Drawing.Color]::FromArgb($a,$r,$g,$bl) }

# ---- tombstone (16x16) ----
$tomb = NewBmp 16 16
$stone = C 150 156 168; $stoneD = C 110 116 130; $stoneL = C 190 196 208; $dark = C 60 64 78
for ($y=0; $y -lt 16; $y++){ for ($x=0; $x -lt 16; $x++){ Px $tomb $x $y (C 0 0 0 0) } }
# rounded slab
for ($y=4; $y -lt 15; $y++){
  for ($x=4; $x -lt 12; $x++){
    if ($y -eq 4 -and ($x -eq 4 -or $x -eq 11)) { continue }
    Px $tomb $x $y $stone
  }
}
for ($y=3; $y -lt 5; $y++){ for ($x=5; $x -lt 11; $x++){ Px $tomb $x $y $stone } }
# shading
for ($y=4; $y -lt 15; $y++){ Px $tomb 4 $y $stoneD; Px $tomb 5 $y $stoneL }
for ($y=4; $y -lt 15; $y++){ Px $tomb 11 $y $stoneD }
# cross engraving
for ($y=6; $y -lt 12; $y++){ Px $tomb 8 $y $dark }
for ($x=6; $x -lt 11; $x++){ Px $tomb $x 8 $dark }
# grass base
for ($x=3; $x -lt 13; $x++){ Px $tomb $x 15 (C 58 96 64) }
$tomb.Save((Join-Path $out "tombstone.png"), [System.Drawing.Imaging.ImageFormat]::Png)

# ---- palm tree (16x32; trunk base sits on the tile) ----
$palm = NewBmp 16 32
for ($y=0; $y -lt 32; $y++){ for ($x=0; $x -lt 16; $x++){ Px $palm $x $y (C 0 0 0 0) } }
$trunk = C 138 96 54; $trunkD = C 108 72 40
for ($y=12; $y -lt 32; $y++){
  $cx = 7 + [int][math]::Round([math]::Sin($y*0.25))
  Px $palm $cx $y $trunk
  Px $palm ($cx+1) $y $trunkD
}
$leaf = C 66 168 92; $leafD = C 44 120 66
# fronds radiating from top
$frondsX = @(-6,-4,-2,0,2,4,6,-5,5,0)
$frondsY = @(2,1,0,-1,0,1,2,4,4,-2)
$cx0 = 7; $cy0 = 11
for ($i=0; $i -lt 7; $i++){
  $ex = $cx0 + $frondsX[$i]; $ey = $cy0 + $frondsY[$i]
  # line from center to tip
  $steps = 6
  for ($s=0; $s -le $steps; $s++){
    $t = $s / $steps
    $px = [int][math]::Round($cx0 + ($ex-$cx0)*$t)
    $py = [int][math]::Round($cy0 + ($ey-$cy0)*$t)
    Px $palm $px $py $leaf
    Px $palm $px ($py+1) $leafD
  }
}
# coconut cluster
Px $palm 6 11 (C 90 60 36); Px $palm 8 12 (C 90 60 36)
$palm.Save((Join-Path $out "palm.png"), [System.Drawing.Imaging.ImageFormat]::Png)

# ---- crystal pylon (16x32; electric/psychic accent) ----
$cry = NewBmp 16 32
for ($y=0; $y -lt 32; $y++){ for ($x=0; $x -lt 16; $x++){ Px $cry $x $y (C 0 0 0 0) } }
$base = C 70 74 96; $baseD = C 48 52 72
for ($y=26; $y -lt 32; $y++){ for ($x=5; $x -lt 11; $x++){ Px $cry $x $y $base } }
for ($y=26; $y -lt 32; $y++){ Px $cry 5 $y $baseD; Px $cry 10 $y $baseD }
$glow = C 150 220 255; $glowC = C 220 245 255
for ($y=8; $y -lt 27; $y++){
  $half = [int][math]::Round(3.0 * (1.0 - [math]::Abs(($y-17)/12.0)))
  for ($x=(8-$half); $x -le (7+$half); $x++){ Px $cry $x $y $glow }
  Px $cry 7 $y $glowC
}
$cry.Save((Join-Path $out "crystal.png"), [System.Drawing.Imaging.ImageFormat]::Png)

Write-Output "props done: tombstone.png, palm.png, crystal.png"
