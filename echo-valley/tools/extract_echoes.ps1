Add-Type -AssemblyName System.Drawing
$src = "c:\Users\smyde\memoir\echo-valley\assets\raw\monsters\50+ Monsters Pack 2D\Monsters\Normal Colors"
$dst = "c:\Users\smyde\memoir\echo-valley\assets\echoes"
New-Item -ItemType Directory -Force -Path $dst | Out-Null

# echo id -> monster number in the 50+ Monsters Pack (64x64, front + back)
$map = [ordered]@{
  # fire
  "emberkit"=23; "flarefox"=18; "infernix"=36; "cindboth"=15
  # water
  "tideling"=3; "marowl"=30; "leviaqua"=5; "dewling"=32; "naiaqua"=27; "aquari"=38
  # grass
  "mossling"=17; "bramblor"=50; "eldertree"=55; "fernkit"=4; "frondex"=8
  # rock
  "pebblit"=53; "craggan"=25; "titanag"=41
  # air
  "zephyr"=14; "gustrel"=51; "cyclora"=47; "boltmoth"=7
  # shadow
  "duskling"=22; "nocturn"=13; "umbrix"=45; "wispurr"=39
}

foreach ($id in $map.Keys) {
  $n = $map[$id]
  $front = Join-Path $src ("Monster #$n Front Normal Color Palette.png")
  $back  = Join-Path $src ("Monster #$n Back Normal Color Palette.png")
  Copy-Item $front (Join-Path $dst "$id.png") -Force
  if (Test-Path $back) { Copy-Item $back (Join-Path $dst "${id}_back.png") -Force }
}
Write-Output "copied $($map.Count) echoes (front + back)"

# verification montage of FRONT sprites
$ids = @($map.Keys)
$cols = 6; $rows = [math]::Ceiling($ids.Count / $cols)
$scale = 1; $cell = 64*$scale; $lh = 14
$canvas = New-Object System.Drawing.Bitmap ($cols*$cell), ($rows*($cell+$lh))
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.Clear([System.Drawing.Color]::FromArgb(255,235,235,235))
$font = New-Object System.Drawing.Font("Consolas", 8)
for ($i=0; $i -lt $ids.Count; $i++){
  $c = $i % $cols; $r = [math]::Floor($i/$cols)
  $t = [System.Drawing.Bitmap]::FromFile((Join-Path $dst "$($ids[$i]).png"))
  $dstRect = New-Object System.Drawing.Rectangle ($c*$cell), ($r*($cell+$lh)), $cell, $cell
  $g.DrawImage($t, $dstRect, (New-Object System.Drawing.Rectangle 0,0,$t.Width,$t.Height), [System.Drawing.GraphicsUnit]::Pixel)
  $t.Dispose()
  $g.DrawString($ids[$i], $font, [System.Drawing.Brushes]::Black, ($c*$cell)+1, ($r*($cell+$lh))+$cell)
}
$g.Dispose()
$canvas.Save("c:\Users\smyde\memoir\echo-valley\assets\kenney\_echo_check.png")
$canvas.Dispose()
Write-Output "montage done"
