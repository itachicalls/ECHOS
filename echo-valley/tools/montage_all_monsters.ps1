Add-Type -AssemblyName System.Drawing
# Montage of all 56 monster silhouettes (Alternative palette) with their numbers
# so we can hand-pick the most imposing ones for legendaries.
$root = "c:\Users\smyde\memoir\echo-valley"
$monDir = Join-Path $root "assets\raw\monsters\50+ Monsters Pack 2D\Monsters\Alternative Colors"
$cols = 8; $rows = [math]::Ceiling(56/$cols)
$cell = 64; $lh = 12
$canvas = New-Object System.Drawing.Bitmap ($cols*$cell), ($rows*($cell+$lh))
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.Clear([System.Drawing.Color]::FromArgb(255,28,24,44))
$font = New-Object System.Drawing.Font("Consolas", 8)
for ($n=1; $n -le 56; $n++){
  $i = $n - 1
  $c = $i % $cols; $r = [math]::Floor($i/$cols)
  $p = Join-Path $monDir ("Monster #$n Front Alternative Color Palette.png")
  if (Test-Path $p) {
    $t = [System.Drawing.Bitmap]::FromFile($p)
    $dstRect = New-Object System.Drawing.Rectangle ($c*$cell), ($r*($cell+$lh)), $cell, $cell
    $g.DrawImage($t, $dstRect, (New-Object System.Drawing.Rectangle 0,0,$t.Width,$t.Height), [System.Drawing.GraphicsUnit]::Pixel)
    $t.Dispose()
  }
  $g.DrawString("#$n", $font, [System.Drawing.Brushes]::Yellow, ($c*$cell)+1, ($r*($cell+$lh))+$cell-1)
}
$g.Dispose()
$out = Join-Path $root "_all_monsters.png"
$canvas.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose()
Write-Output "montage: $out"
