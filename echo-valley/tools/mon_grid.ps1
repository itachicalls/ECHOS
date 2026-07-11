Add-Type -AssemblyName System.Drawing
$dir = "c:\Users\smyde\memoir\echo-valley\assets\raw\monsters\50+ Monsters Pack 2D\Monsters\Normal Colors"
$out = "c:\Users\smyde\memoir\echo-valley\assets\kenney\_mon_grid.png"
$cols = 8; $count = 56; $rows = [math]::Ceiling($count / $cols)
$scale = 2; $cell = 64 * $scale; $lh = 18
$canvas = New-Object System.Drawing.Bitmap ($cols*$cell), ($rows*($cell+$lh))
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.Clear([System.Drawing.Color]::FromArgb(255,235,235,235))
$font = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
for ($i=1; $i -le $count; $i++){
  $c = ($i-1) % $cols; $r = [math]::Floor(($i-1)/$cols)
  $f = Join-Path $dir ("Monster #$i Front Normal Color Palette.png")
  if (Test-Path $f){
    $t = [System.Drawing.Bitmap]::FromFile($f)
    $dst = New-Object System.Drawing.Rectangle ($c*$cell), ($r*($cell+$lh)), $cell, $cell
    $g.DrawImage($t, $dst, (New-Object System.Drawing.Rectangle 0,0,$t.Width,$t.Height), [System.Drawing.GraphicsUnit]::Pixel)
    $t.Dispose()
    $g.DrawString([string]$i, $font, [System.Drawing.Brushes]::Black, ($c*$cell)+2, ($r*($cell+$lh))+$cell)
  }
}
$g.Dispose(); $canvas.Save($out); $canvas.Dispose()
Write-Output "MON GRID DONE $out"
