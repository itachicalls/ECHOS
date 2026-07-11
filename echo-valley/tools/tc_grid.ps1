Add-Type -AssemblyName System.Drawing
$dir = "c:\Users\smyde\memoir\echo-valley\assets\raw\tiny-creatures\tiny-creatures\Tiles"
$out = "c:\Users\smyde\memoir\echo-valley\assets\kenney\_tc_grid.png"
$cols = 10; $rows = 18; $scale = 8; $cell = 16 * $scale; $pad = 16
$canvas = New-Object System.Drawing.Bitmap (($cols*$cell)+$pad), (($rows*$cell)+$pad)
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.Clear([System.Drawing.Color]::FromArgb(255,40,44,52))
$font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
$white = [System.Drawing.Brushes]::White
$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(120,255,80,80)),1
for ($i=1; $i -le 180; $i++){
  $c = ($i-1) % $cols
  $r = [math]::Floor(($i-1) / $cols)
  $f = Join-Path $dir ("tile_{0:D4}.png" -f $i)
  if (Test-Path $f){
    $t = [System.Drawing.Bitmap]::FromFile($f)
    $dst = New-Object System.Drawing.Rectangle (($c*$cell)+$pad), (($r*$cell)+$pad), $cell, $cell
    $g.DrawImage($t, $dst, (New-Object System.Drawing.Rectangle 0,0,$t.Width,$t.Height), [System.Drawing.GraphicsUnit]::Pixel)
    $t.Dispose()
    $g.DrawRectangle($pen, $dst)
    $g.DrawString([string]$i, $font, $white, ($c*$cell)+$pad+2, ($r*$cell)+$pad+1)
  }
}
$g.Dispose()
$canvas.Save($out)
$canvas.Dispose()
Write-Output "TC GRID DONE $out"
