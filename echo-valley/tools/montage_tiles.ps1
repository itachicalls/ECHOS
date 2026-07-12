Add-Type -AssemblyName System.Drawing
$dir = "c:\Users\smyde\memoir\echo-valley\assets\raw\tiny-creatures\tiny-creatures\Tiles"
$out = "c:\Users\smyde\memoir\echo-valley\assets\kenney\_legend_candidates.png"
$nums = @(2,3,4,9,31,32,33,34,35,36,37,38,39,40,45,46,47,50,55,56,66,75,104,111,112,127,128,129,163,168)
$cols = 10; $rows = [math]::Ceiling($nums.Count/$cols)
$scale = 4; $cell = 16*$scale; $lh = 14; $pad=4
$canvas = New-Object System.Drawing.Bitmap ($cols*$cell), ($rows*($cell+$lh))
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.Clear([System.Drawing.Color]::FromArgb(255,40,44,52))
$font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
for ($i=0; $i -lt $nums.Count; $i++){
  $c = $i % $cols; $r = [math]::Floor($i/$cols)
  $f = Join-Path $dir ("tile_{0:D4}.png" -f $nums[$i])
  if (Test-Path $f){
    $t = [System.Drawing.Bitmap]::FromFile($f)
    $dst = New-Object System.Drawing.Rectangle ($c*$cell), ($r*($cell+$lh)), $cell, $cell
    $g.DrawImage($t, $dst, (New-Object System.Drawing.Rectangle 0,0,$t.Width,$t.Height), [System.Drawing.GraphicsUnit]::Pixel)
    $t.Dispose()
    $g.DrawString([string]$nums[$i], $font, [System.Drawing.Brushes]::White, ($c*$cell)+1, ($r*($cell+$lh))+$cell)
  }
}
$g.Dispose(); $canvas.Save($out); $canvas.Dispose()
Write-Output "candidates -> $out"
