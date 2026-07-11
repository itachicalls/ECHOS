# Generates composited tiles the packs lack (tall grass) from real Kenney pixels,
# and re-mocks the map with 2-tile trees + water candidates.
Add-Type -AssemblyName System.Drawing

$K = "c:\Users\smyde\memoir\echo-valley\assets\kenney"
$town = [System.Drawing.Bitmap]::FromFile("$K\tiny_town_sheet.png")
$dun  = [System.Drawing.Bitmap]::FromFile("$K\tiny_dungeon_sheet.png")
$rog  = [System.Drawing.Bitmap]::FromFile("$K\roguelike_sheet.png")

New-Item -ItemType Directory -Force -Path "$K\gen" | Out-Null

# --- Composite TALL GRASS: tiny-town grass base + darkened grass blades ---
function Crop($sheet,$col,$row,$stride){
  $b = New-Object System.Drawing.Bitmap 16,16
  $g = [System.Drawing.Graphics]::FromImage($b)
  $sr = New-Object System.Drawing.Rectangle ($col*$stride),($row*$stride),16,16
  $g.DrawImage($sheet,(New-Object System.Drawing.Rectangle 0,0,16,16),$sr,[System.Drawing.GraphicsUnit]::Pixel)
  $g.Dispose(); return $b
}

$grass = Crop $town 0 0 16
$tg = New-Object System.Drawing.Bitmap 16,16
$g = [System.Drawing.Graphics]::FromImage($tg)
$g.DrawImage($grass,0,0)
# darker green blades: draw vertical tufts using a dark-green sampled tone
$dark = [System.Drawing.Color]::FromArgb(255,58,120,42)
$dark2 = [System.Drawing.Color]::FromArgb(255,74,148,58)
$pen = New-Object System.Drawing.Pen $dark,1
$pen2 = New-Object System.Drawing.Pen $dark2,1
# blade clusters (x, baseY, height)
$blades = @(@(2,14,5),@(4,15,7),@(6,13,6),@(8,15,7),@(10,14,6),@(12,15,7),@(14,14,5),@(3,15,4),@(11,15,4))
foreach($b in $blades){
  $x=$b[0]; $by=$b[1]; $h=$b[2]
  $g.DrawLine($pen, $x, $by, $x, ($by-$h))
  $g.DrawLine($pen2, ($x+1), $by, ($x+1), ($by-$h+1))
}
$g.Dispose()
$tg.Save("$K\gen\tall_grass.png")
$grass.Dispose(); $tg.Dispose()
Write-Output "wrote gen/tall_grass.png"

# --- Composite DESERT BRUSH: tiny-dungeon sand base + dry olive blades ---
$sand = Crop $dun 0 4 16
$db = New-Object System.Drawing.Bitmap 16,16
$g2 = [System.Drawing.Graphics]::FromImage($db)
$g2.DrawImage($sand,0,0)
$dry = [System.Drawing.Color]::FromArgb(255,150,132,60)
$dry2 = [System.Drawing.Color]::FromArgb(255,178,158,80)
$pd = New-Object System.Drawing.Pen $dry,1
$pd2 = New-Object System.Drawing.Pen $dry2,1
$blades2 = @(@(3,15,4),@(5,14,5),@(7,15,4),@(9,14,5),@(11,15,4),@(13,14,5),@(2,15,3),@(10,15,3))
foreach($b in $blades2){
  $x=$b[0]; $by=$b[1]; $h=$b[2]
  $g2.DrawLine($pd, $x, $by, $x, ($by-$h))
  $g2.DrawLine($pd2, ($x+1), $by, ($x+1), ($by-$h+1))
}
$g2.Dispose()
$db.Save("$K\gen\desert_brush.png")
$sand.Dispose(); $db.Dispose()
Write-Output "wrote gen/desert_brush.png"

# --- Re-mock the map with improvements ---
$MW=20; $MH=13; $T=16; $scale=6
$canvas = New-Object System.Drawing.Bitmap ($MW*$T*$scale), ($MH*$T*$scale)
$cg = [System.Drawing.Graphics]::FromImage($canvas)
$cg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$cg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$tgTile = [System.Drawing.Bitmap]::FromFile("$K\gen\tall_grass.png")

function DrawT($sheet,$col,$row,$cx,$cy,$stride,$wpx=16,$hpx=16){
  $src = New-Object System.Drawing.Rectangle ($col*$stride),($row*$stride),$wpx,$hpx
  $dst = New-Object System.Drawing.Rectangle ($cx*$T*$scale),($cy*$T*$scale),($wpx*$scale),($hpx*$scale)
  $cg.DrawImage($sheet,$dst,$src,[System.Drawing.GraphicsUnit]::Pixel)
}
function TT($c,$r,$x,$y){ DrawT $town $c $r $x $y 16 }
function DN($c,$r,$x,$y){ DrawT $dun  $c $r $x $y 16 }
function RG($c,$r,$x,$y){ DrawT $rog  $c $r $x $y 17 }
function TREE($c,$x,$y){ DrawT $town $c 0 $x ($y-1) 16 16 32 }  # 16x32 top+trunk

for ($x=0;$x -lt $MW;$x++){ for ($y=0;$y -lt $MH;$y++){ TT 0 0 $x $y } }
for ($y=0;$y -lt $MH;$y++){ TT 1 2 9 $y; TT 1 2 10 $y }
for ($x=0;$x -lt $MW;$x++){ TT 1 2 $x 6 }
for ($x=8;$x -le 11;$x++){ for ($y=5;$y -le 7;$y++){ TT 1 9 $x $y } }

# water candidates: A=rog(1,0)  B=rog(3,3)  C=rog(4,3)
RG 1 0 2 2; RG 1 0 3 2; RG 1 0 2 3; RG 1 0 3 3
RG 3 3 5 2; RG 3 3 6 2; RG 3 3 5 3; RG 3 3 6 3

# tall grass patch (composited)
for ($x=13;$x -le 17;$x++){ for ($y=2;$y -le 4;$y++){ DrawT $tgTile 0 0 $x $y 16 } }

# 2-tile trees along a border
TREE 4 1 9; TREE 4 3 9; TREE 3 5 9; TREE 4 17 9; TREE 3 0 11
# bush + mushroom
TT 5 0 7 10; TT 5 2 2 10

# house 3x3
TT 4 4 13 8; TT 5 4 14 8; TT 6 4 15 8
TT 4 6 13 9; TT 5 6 14 9; TT 6 6 15 9
TT 4 7 13 10; TT 5 7 14 10; TT 6 7 15 10

TT 11 6 8 5
DN 3 8 10 5
DN 0 7 5 4
DN 4 8 6 11
DN 8 9 8 11

$cg.Dispose()
$town.Dispose(); $dun.Dispose(); $rog.Dispose(); $tgTile.Dispose()
$canvas.Save("$K\_mock_map2.png")
$canvas.Dispose()
Write-Output "MOCK2 DONE"
