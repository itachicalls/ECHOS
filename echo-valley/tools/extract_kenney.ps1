# Extracts Kenney CC0 sprites into assets/kenney/ (verified grid coords).
Add-Type -AssemblyName System.Drawing

$root = "c:\Users\smyde\memoir\echo-valley\assets\kenney"
$raw  = "c:\Users\smyde\memoir\echo-valley\assets\raw\kenney"
New-Item -ItemType Directory -Force -Path "$root\tiles","$root\chars","$root\items","$root\props" | Out-Null

function Copy-Tile($srcPath, $col, $row, $size, $dest, $spacing=0) {
    $bmp = [System.Drawing.Bitmap]::FromFile($srcPath)
    $sx = $col * ($size + $spacing)
    $sy = $row * ($size + $spacing)
    $out = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($out)
    $g.DrawImage($bmp, 0, 0, (New-Object System.Drawing.Rectangle $sx,$sy,$size,$size), [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose(); $bmp.Dispose()
    $out.Save($dest); $out.Dispose()
}

$td = "$raw\tiny-dungeon\Tilemap\tilemap_packed.png"

# Trainers (row 7-8)
$trainers = @{
    "trainer_wizard" = @(0,7); "trainer_monk" = @(1,7); "trainer_smith" = @(2,7)
    "trainer_viking" = @(3,7); "trainer_scout" = @(4,7); "trainer_knight" = @(0,8)
    "trainer_guard" = @(1,8); "trainer_soldier" = @(2,8)
}
foreach ($k in $trainers.Keys) {
    $c = $trainers[$k]
    Copy-Tile $td $c[0] $c[1] 16 "$root\chars\$k.png"
}
Copy-Tile $td 3 8 16 "$root\chars\nurse.png"          # purple dress healer
Copy-Tile $td 4 8 16 "$root\chars\trainer_elder.png"

# Wild echo monsters
$mons = @{ "ghost"=@(0,9); "golem"=@(1,9); "crab"=@(2,9); "rogue"=@(4,9)
           "bat"=@(0,10); "wraith"=@(1,10); "spider"=@(2,10); "rat"=@(3,10) }
foreach ($k in $mons.Keys) {
    $c = $mons[$k]; Copy-Tile $td $c[0] $c[1] 16 "$root\chars\echo_$k.png"
}

# Echo Capsule (blue vial) + alt (red)
Copy-Tile $td 7 10 16 "$root\items\echo_capsule.png"
Copy-Tile $td 5 10 16 "$root\items\echo_capsule_red.png"

# Desert sand tiles + fountain shrine prop
foreach ($i in 0..5) { Copy-Tile $td $i 4 16 "$root\tiles\desert_$i.png" }
Copy-Tile $td 7 0 16 "$root\props\shrine_fountain.png"
Copy-Tile $td 8 0 16 "$root\props\shrine_fountain2.png"

# Roguelike terrain (17px stride)
$rg = "$raw\roguelike\Spritesheet\roguelikeSheet_transparent.png"
function Copy-Rg($col,$row,$dest) { Copy-Tile $rg $col $row 16 $dest 1 }
Copy-Rg 0 6 "$root\tiles\grass.png"
Copy-Rg 1 6 "$root\tiles\grass2.png"
Copy-Rg 0 7 "$root\tiles\tall_grass.png"
Copy-Rg 4 6 "$root\tiles\sand.png"
Copy-Rg 11 6 "$root\tiles\jungle.png"
Copy-Rg 12 6 "$root\tiles\jungle2.png"
Copy-Rg 16 0 "$root\tiles\water.png"
Copy-Rg 2 3 "$root\tiles\dirt.png"
Copy-Rg 40 23 "$root\items\echo_net.png"   # orange capsule from roguelike sheet

Copy-Item $rg "$root\roguelike_sheet.png" -Force
Copy-Item $td "$root\tiny_dungeon_sheet.png" -Force
Copy-Item "$raw\tiny-town\Tilemap\tilemap_packed.png" "$root\tiny_town_sheet.png" -Force
# Red medical cross (+) for Echo Rest clinics — 16x16 pixel art.
$hc = New-Object System.Drawing.Bitmap 16, 16
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
$red = [System.Drawing.Color]::FromArgb(255, 210, 48, 48)
$hi = [System.Drawing.Color]::FromArgb(255, 255, 210, 210)
for ($x = 0; $x -lt 16; $x++) { for ($y = 0; $y -lt 16; $y++) { $hc.SetPixel($x, $y, $clear) } }
for ($y = 2; $y -lt 14; $y++) { for ($x = 6; $x -lt 10; $x++) { $hc.SetPixel($x, $y, $red) } }
for ($y = 6; $y -lt 10; $y++) { for ($x = 2; $x -lt 14; $x++) { $hc.SetPixel($x, $y, $red) } }
for ($y = 7; $y -lt 9; $y++) { for ($x = 7; $x -lt 9; $x++) { $hc.SetPixel($x, $y, $hi) } }
$hc.Save("$root\props\heal_cross.png"); $hc.Dispose()

Write-Output "EXTRACT DONE"
