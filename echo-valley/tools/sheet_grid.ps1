param([string]$sheet = "tiny_town_sheet.png", [int]$tile = 16)
Add-Type -AssemblyName System.Drawing
$path = "c:\Users\smyde\memoir\echo-valley\assets\kenney\$sheet"
$src = [System.Drawing.Bitmap]::FromFile($path)
$cols = [int][math]::Floor($src.Width / $tile); $rows = [int][math]::Floor($src.Height / $tile)
$scale = 3; $cell = $tile * $scale; $lh = 12
$canvas = New-Object System.Drawing.Bitmap ([int]($cols*$cell)), ([int]($rows*($cell+$lh)))
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.Clear([System.Drawing.Color]::FromArgb(255,60,60,70))
$font = New-Object System.Drawing.Font("Consolas", 7)
for ($r=0; $r -lt $rows; $r++){
  for ($c=0; $c -lt $cols; $c++){
    $dst = New-Object System.Drawing.Rectangle ($c*$cell), ($r*($cell+$lh)), $cell, $cell
    $srcR = New-Object System.Drawing.Rectangle ($c*$tile), ($r*$tile), $tile, $tile
    $g.DrawImage($src, $dst, $srcR, [System.Drawing.GraphicsUnit]::Pixel)
    $g.DrawString("$c,$r", $font, [System.Drawing.Brushes]::White, ($c*$cell), ($r*($cell+$lh))+$cell)
  }
}
$g.Dispose()
$out = "c:\Users\smyde\memoir\echo-valley\assets\kenney\_sheet_$($sheet.Replace('.png','')).png"
$canvas.Save($out); $canvas.Dispose(); $src.Dispose()
Write-Output "$out  ($cols x $rows tiles)"
