Add-Type -AssemblyName System.Drawing
$dir = "c:\Users\smyde\memoir\echo-valley\assets\echoes"
$out = "c:\Users\smyde\memoir\echo-valley\assets\kenney\_expansion_check.png"
$ids = @('dripling','tidalisk','sharkling','megalodrift','glacierra',
  'sparklit','stormraptor','voltcanine','plasmind','tempestwing',
  'psybud','hypnaura','somnarch','arcanexus','banshee','poltergeist','pyrewraith',
  'cindermol','volcanid','phoenixar','pyrelynx',
  'seedpup','bloomastiff','mycelith','canopyre',
  'pebblepup','bastioth','magnetron','prismshard','golemith',
  'leviathos','voltmonarch','aeonmind','mortarch','pyrothrone','sylvanking','terralossus','chorusprime','fracturael','primordius')
$cols = 8; $rows = [math]::Ceiling($ids.Count/$cols)
$scale = 2; $cell = 64*$scale; $lh = 16
$canvas = New-Object System.Drawing.Bitmap ($cols*$cell), ($rows*($cell+$lh))
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.Clear([System.Drawing.Color]::FromArgb(255,40,44,52))
$font = New-Object System.Drawing.Font("Consolas", 8)
for ($i=0; $i -lt $ids.Count; $i++){
  $c = $i % $cols; $r = [math]::Floor($i/$cols)
  $f = Join-Path $dir "$($ids[$i]).png"
  if (Test-Path $f) {
    $t = [System.Drawing.Bitmap]::FromFile($f)
    $dst = New-Object System.Drawing.Rectangle ($c*$cell), ($r*($cell+$lh)), $cell, $cell
    $g.DrawImage($t, $dst, (New-Object System.Drawing.Rectangle 0,0,$t.Width,$t.Height), [System.Drawing.GraphicsUnit]::Pixel)
    $t.Dispose()
    $g.DrawString($ids[$i], $font, [System.Drawing.Brushes]::White, ($c*$cell)+1, ($r*($cell+$lh))+$cell)
  }
}
$g.Dispose(); $canvas.Save($out); $canvas.Dispose()
Write-Output "montage -> $out"
