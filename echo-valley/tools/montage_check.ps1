Add-Type -AssemblyName System.Drawing
# Quick visual montage of a sample of NEW Harmons (families + legendaries)
# so we can eyeball art quality after re-skinning.
$root = "c:\Users\smyde\memoir\echo-valley"
$dir  = Join-Path $root "assets\echoes"

$ids = @(
  # family samples across resonances / stages
  'dripling','splooze','tidalisk','shellby','fintot','coraline',
  'sparklit','voltwing','stormraptor','buzzfly','wattpup','kiteon',
  'psybud','mesmind','hypnaura','tombkin','boneling','wispire',
  'cindermol','magmapup','volcanid','torchit','sparkitten','coalkin',
  'seedpup','vinelet','fungit','cactopup','leaflit','berrybop',
  'pebblepup','gravelisk','ironnib','crystallit','claykin','dustmite',
  # legendaries
  'leviathos','maelstriden','voltmonarch','skysovereign','aeonmind','nyxarch',
  'mortarch','hallowraith','pyrothrone','solarch','sylvanking','gaialith',
  'terralossus','orogenus','tempestria','abyssareign','grimsovereign','chorusprime',
  'fracturael','primordius'
)

$cols = 10
$rows = [math]::Ceiling($ids.Count / $cols)
$cell = 64; $lh = 12
$canvas = New-Object System.Drawing.Bitmap ($cols*$cell), ($rows*($cell+$lh))
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.Clear([System.Drawing.Color]::FromArgb(255,28,24,44))
$font = New-Object System.Drawing.Font("Consolas", 6)
for ($i=0; $i -lt $ids.Count; $i++){
  $c = $i % $cols; $r = [math]::Floor($i/$cols)
  $p = Join-Path $dir ($ids[$i] + ".png")
  if (Test-Path $p) {
    $t = [System.Drawing.Bitmap]::FromFile($p)
    $dstRect = New-Object System.Drawing.Rectangle ($c*$cell), ($r*($cell+$lh)), $cell, $cell
    $g.DrawImage($t, $dstRect, (New-Object System.Drawing.Rectangle 0,0,$t.Width,$t.Height), [System.Drawing.GraphicsUnit]::Pixel)
    $t.Dispose()
  }
  $g.DrawString($ids[$i], $font, [System.Drawing.Brushes]::White, ($c*$cell)+1, ($r*($cell+$lh))+$cell-1)
}
$g.Dispose()
$out = Join-Path $root "_reskin_check.png"
$canvas.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose()
Write-Output "montage: $out"
