# Composes a mock overworld render from chosen sheet coords to validate the look.
Add-Type -AssemblyName System.Drawing

$K = "c:\Users\smyde\memoir\echo-valley\assets\kenney"
$town = [System.Drawing.Bitmap]::FromFile("$K\tiny_town_sheet.png")
$dun  = [System.Drawing.Bitmap]::FromFile("$K\tiny_dungeon_sheet.png")
$rog  = [System.Drawing.Bitmap]::FromFile("$K\roguelike_sheet.png")

$MW = 20; $MH = 13; $T = 16; $scale = 6
$canvas = New-Object System.Drawing.Bitmap ($MW*$T*$scale), ($MH*$T*$scale)
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

function Draw($sheet, $col, $row, $cx, $cy, $stride) {
  $src = New-Object System.Drawing.Rectangle ($col*$stride), ($row*$stride), 16, 16
  $dst = New-Object System.Drawing.Rectangle ($cx*$T*$scale), ($cy*$T*$scale), ($T*$scale), ($T*$scale)
  $g.DrawImage($sheet, $dst, $src, [System.Drawing.GraphicsUnit]::Pixel)
}
function TT($c,$r,$x,$y){ Draw $town $c $r $x $y 16 }
function DN($c,$r,$x,$y){ Draw $dun  $c $r $x $y 16 }
function RG($c,$r,$x,$y){ Draw $rog  $c $r $x $y 17 }

# base grass
for ($x=0;$x -lt $MW;$x++){ for ($y=0;$y -lt $MH;$y++){ TT 0 0 $x $y } }

# dirt path cross
for ($y=0;$y -lt $MH;$y++){ TT 1 2 9 $y; TT 1 2 10 $y }
for ($x=0;$x -lt $MW;$x++){ TT 1 2 $x 6 }

# stone plaza
for ($x=8;$x -le 11;$x++){ for ($y=5;$y -le 7;$y++){ TT 1 9 $x $y } }

# water pond (roguelike)
for ($x=2;$x -le 4;$x++){ for ($y=2;$y -le 3;$y++){ RG 3 3 $x $y } }

# tall grass patch
for ($x=13;$x -le 17;$x++){ for ($y=2;$y -le 4;$y++){ TT 5 1 $x $y } }

# trees / bushes
TT 4 1 2 8; TT 3 1 4 8; TT 6 1 6 9; TT 5 0 15 8; TT 5 2 3 10

# house (red roof) 3x3 at (13,8)
TT 4 4 13 8; TT 5 4 14 8; TT 6 4 15 8
TT 4 6 13 9; TT 5 6 14 9; TT 6 6 15 9
TT 4 7 13 10; TT 5 7 14 10; TT 6 7 15 10

# sign + fence
TT 11 6 8 5
TT 10 4 0 5; TT 10 4 1 5

# characters: nurse, trainers, hero
DN 3 8 10 5   # nurse
DN 0 7 5 3    # wizard trainer
DN 3 7 16 4   # viking trainer
DN 4 8 6 10   # hero-ish

# echoes sample row (bottom)
DN 0 9 0 12; DN 1 9 1 12; DN 2 9 2 12; DN 3 10 3 12; DN 2 10 4 12; DN 1 10 5 12
# capsule
DN 8 9 7 12

$g.Dispose()
$town.Dispose(); $dun.Dispose(); $rog.Dispose()
$canvas.Save("$K\_mock_map.png")
$canvas.Dispose()
Write-Output "MOCK DONE $K\_mock_map.png"
