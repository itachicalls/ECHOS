Add-Type -AssemblyName System.Drawing

# Reassign generated Harmon sprites so each species gets a unique silhouette
# from the 112 clean Normal+Alternative monster fronts before any hue-shift.
$root      = "c:\Users\smyde\memoir\echo-valley"
$echoesDir = Join-Path $root "assets\echoes"
$dataFile  = Join-Path $root "data\echoes.json"
$monNorm   = Join-Path $root "assets\raw\monsters\50+ Monsters Pack 2D\Monsters\Normal Colors"
$monAlt    = Join-Path $root "assets\raw\monsters\50+ Monsters Pack 2D\Monsters\Alternative Colors"

$preserve = @('emberkit','flarefox','infernix','cindboth','tideling','marowl','leviaqua',
  'dewling','naiaqua','aquari','mossling','bramblor','eldertree','fernkit','frondex',
  'pebblit','craggan','titanag','zephyr','gustrel','cyclora','boltmoth','duskling',
  'nocturn','umbrix','wispurr')

function SrcFront($palette, $num) {
  $dir = if ($palette -eq 'A') { $monAlt } else { $monNorm }
  $pal = if ($palette -eq 'A') { 'Alternative' } else { 'Normal' }
  return (Join-Path $dir "Monster #$num Front $pal Color Palette.png")
}
function SrcBack($palette, $num) {
  $dir = if ($palette -eq 'A') { $monAlt } else { $monNorm }
  $pal = if ($palette -eq 'A') { 'Alternative' } else { 'Normal' }
  return (Join-Path $dir "Monster #$num Back $pal Color Palette.png")
}

function HueMatrix([double]$deg) {
  $a = $deg * [math]::PI / 180.0
  $c = [math]::Cos($a); $s = [math]::Sin($a)
  $m = New-Object 'System.Single[,]' 5,5
  $m[0,0] = [single](0.213 + $c*0.787 - $s*0.213)
  $m[1,0] = [single](0.213 - $c*0.213 + $s*0.143)
  $m[2,0] = [single](0.213 - $c*0.213 - $s*0.787)
  $m[0,1] = [single](0.715 - $c*0.715 - $s*0.715)
  $m[1,1] = [single](0.715 + $c*0.285 + $s*0.140)
  $m[2,1] = [single](0.715 - $c*0.715 + $s*0.715)
  $m[0,2] = [single](0.072 - $c*0.072 + $s*0.928)
  $m[1,2] = [single](0.072 - $c*0.072 - $s*0.283)
  $m[2,2] = [single](0.072 + $c*0.928 + $s*0.072)
  $m[3,3] = [single]1.0
  $m[4,4] = [single]1.0
  return $m
}

function SaveRecolor($srcPath, $dstPath, [double]$hue) {
  if (-not (Test-Path $srcPath)) { return $false }
  $src = [System.Drawing.Bitmap]::FromFile($srcPath)
  $bmp = New-Object System.Drawing.Bitmap $src.Width, $src.Height
  for ($y = 0; $y -lt $src.Height; $y++) {
    for ($x = 0; $x -lt $src.Width; $x++) {
      $c = $src.GetPixel($x, $y)
      if ($c.A -lt 8) {
        $bmp.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
        continue
      }
      $h = $c.GetHue()
      $s = $c.GetSaturation()
      $b = $c.GetBrightness()
      $nh = ($h + $hue) % 360.0
      if ($nh -lt 0) { $nh += 360.0 }
      $bmp.SetPixel($x, $y, (HsbToColor $nh $s $b $c.A))
    }
  }
  $bmp.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose(); $src.Dispose()
  return $true
}

function HsbToColor([double]$h, [double]$s, [double]$br, [int]$a) {
  if ($s -le 0.0001) {
    $v = [int][Math]::Round($br * 255.0)
    return [System.Drawing.Color]::FromArgb($a, $v, $v, $v)
  }
  $hh = $h / 60.0
  $i = [int][Math]::Floor($hh)
  $f = $hh - $i
  $p = $br * (1.0 - $s)
  $q = $br * (1.0 - $s * $f)
  $t = $br * (1.0 - $s * (1.0 - $f))
  switch ($i % 6) {
    0 { $r=$br; $g=$t; $b=$p }
    1 { $r=$q; $g=$br; $b=$p }
    2 { $r=$p; $g=$br; $b=$t }
    3 { $r=$p; $g=$q; $b=$br }
    4 { $r=$t; $g=$p; $b=$br }
    default { $r=$br; $g=$p; $b=$q }
  }
  return [System.Drawing.Color]::FromArgb($a,
    [int][Math]::Round([Math]::Min(255,$r*255)),
    [int][Math]::Round([Math]::Min(255,$g*255)),
    [int][Math]::Round([Math]::Min(255,$b*255)))
}

function CopyPng($srcPath, $dstPath) {
  if (Test-Path $srcPath) { Copy-Item $srcPath $dstPath -Force; return $true }
  return $false
}

function WriteSprite($id, $palette, $num, [double]$hue = 0) {
  $dstF = Join-Path $echoesDir "$id.png"
  $dstB = Join-Path $echoesDir "${id}_back.png"
  if ($hue -eq 0) {
    $okF = CopyPng (SrcFront $palette $num) $dstF
    $okB = CopyPng (SrcBack  $palette $num) $dstB
    if (-not $okB) { CopyPng (SrcFront $palette $num) $dstB | Out-Null }
    return $okF
  }
  $okF = SaveRecolor (SrcFront 'N' $num) $dstF $hue
  $okB = SaveRecolor (SrcBack  'N' $num) $dstB $hue
  if (-not $okB) { SaveRecolor (SrcFront 'N' $num) $dstB $hue | Out-Null }
  return $okF
}

# Unique clean pool first (112), then distinct hue-shifted leftovers.
$pool = [System.Collections.Generic.List[object]]::new()
foreach ($n in 1..56) { $pool.Add(@{p='N'; n=$n; h=0.0}) }
foreach ($n in 1..56) { $pool.Add(@{p='A'; n=$n; h=0.0}) }
# Extra unique-looking hues for overflow beyond 112
$extraHues = @(28,55,82,110,140,168,195,225,255,285,318,348,42,70)
for ($i = 0; $i -lt $extraHues.Count; $i++) {
  $n = (($i * 7) % 56) + 1
  $pool.Add(@{p='N'; n=$n; h=[double]$extraHues[$i]})
}

$rng = New-Object System.Random 77
$shuffled = $pool | Sort-Object { $rng.Next() }

$raw = Get-Content $dataFile -Raw
$json = $raw | ConvertFrom-Json

# Build generated-only evolution chains (roots first).
$byId = @{}
foreach ($e in $json) { $byId[$e.id] = $e }
$childOf = @{}
foreach ($e in $json) {
  if ($e.evolve_to -and $e.evolve_to -ne '') { $childOf[$e.evolve_to] = $e.id }
}
$chains = @()
foreach ($e in $json) {
  if ($preserve -contains $e.id) { continue }
  if ($childOf.ContainsKey($e.id)) { continue }
  $chain = @($e.id)
  $cur = $e.id
  while ($byId[$cur].evolve_to -and $byId[$cur].evolve_to -ne '') {
    $cur = $byId[$cur].evolve_to
    if ($preserve -contains $cur) { break }
    $chain += $cur
  }
  $chains += ,$chain
}

# Flatten generated ids in chain order, assign unique pool entries sequentially.
$ids = @()
foreach ($chain in ($chains | Sort-Object { $_.Count })) {
  foreach ($id in $chain) {
    if ($preserve -contains $id) { continue }
    $ids += $id
  }
}

$written = 0
$usedKeys = @{}
$poolIdx = 0
foreach ($id in $ids) {
  $spec = $null
  while ($poolIdx -lt $shuffled.Count) {
    $cand = $shuffled[$poolIdx]
    $poolIdx++
    $key = "{0}:{1}:{2}" -f $cand.p, $cand.n, [int]$cand.h
    if (-not $usedKeys.ContainsKey($key)) {
      $usedKeys[$key] = $true
      $spec = $cand
      break
    }
  }
  if ($null -eq $spec) {
    $n = ($written % 56) + 1
    $spec = @{p='N'; n=$n; h=[double](20 + ($written * 23) % 320)}
  }
  if ($spec.h -eq 0) {
    WriteSprite $id $spec.p $spec.n 0 | Out-Null
  } else {
    WriteSprite $id 'N' $spec.n $spec.h | Out-Null
  }
  $written++
}

Write-Output "Rediversified $written Harmon sprites (unique pool keys: $($usedKeys.Count))."
