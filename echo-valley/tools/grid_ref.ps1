param([int]$col0 = 0, [int]$row0 = 0, [int]$cols = 20, [int]$rows = 12, [string]$out = "c:\Users\smyde\memoir\echo-valley\assets\kenney\_rogue_grid.png", [string]$src = "c:\Users\smyde\memoir\echo-valley\assets\kenney\roguelike_sheet.png", [int]$stride = 17)

# Builds a labeled, upscaled grid of a sheet region for coord-finding.
Add-Type -AssemblyName System.Drawing

$scale = 12  # upscale factor
$cell = 16 * $scale

$bmp = [System.Drawing.Bitmap]::FromFile($src)
$w = $cols * $cell
$h = $rows * $cell
$outBmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($outBmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.Clear([System.Drawing.Color]::FromArgb(40,40,40))

$font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
$penR = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(180,255,0,0)), 1
$brushBg = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(160,0,0,0))
$brushTx = [System.Drawing.Brushes]::Yellow

for ($c = 0; $c -lt $cols; $c++) {
  for ($r = 0; $r -lt $rows; $r++) {
    $ac = $c + $col0
    $ar = $r + $row0
    $sx = $ac * $stride
    $sy = $ar * $stride
    $dst = New-Object System.Drawing.Rectangle ($c*$cell), ($r*$cell), $cell, $cell
    $srcRect = New-Object System.Drawing.Rectangle $sx, $sy, 16, 16
    $g.DrawImage($bmp, $dst, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    $g.DrawRectangle($penR, ($c*$cell), ($r*$cell), $cell, $cell)
    $label = "$ac,$ar"
    $g.FillRectangle($brushBg, ($c*$cell)+1, ($r*$cell)+1, 42, 20)
    $g.DrawString($label, $font, $brushTx, ($c*$cell)+2, ($r*$cell)+1)
  }
}
$g.Dispose(); $bmp.Dispose()
$outBmp.Save($out)
$outBmp.Dispose()
Write-Output "GRID DONE $out"
