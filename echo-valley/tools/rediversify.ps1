Add-Type -AssemblyName System.Drawing

# Reassign sprites for generated echoes so families use distinct monster silhouettes.
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
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $arr = HueMatrix $hue
  $cm = New-Object System.Drawing.Imaging.ColorMatrix
  $cm.Matrix00=$arr[0,0]; $cm.Matrix01=$arr[0,1]; $cm.Matrix02=$arr[0,2]
  $cm.Matrix10=$arr[1,0]; $cm.Matrix11=$arr[1,1]; $cm.Matrix12=$arr[1,2]
  $cm.Matrix20=$arr[2,0]; $cm.Matrix21=$arr[2,1]; $cm.Matrix22=$arr[2,2]
  $cm.Matrix33=1.0; $cm.Matrix44=1.0
  $ia = New-Object System.Drawing.Imaging.ImageAttributes
  $ia.SetColorMatrix($cm)
  $rect = New-Object System.Drawing.Rectangle 0,0,$src.Width,$src.Height
  $g.DrawImage($src, $rect, 0,0,$src.Width,$src.Height, [System.Drawing.GraphicsUnit]::Pixel, $ia)
  $g.Dispose(); $bmp.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose(); $src.Dispose()
  return $true
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

# Build shuffled pool: every (palette, num) pair, then hue-shifted extras.
$pool = @()
foreach ($n in 1..56) { $pool += @{p='N'; n=$n; h=0.0} }
foreach ($n in 1..56) { $pool += @{p='A'; n=$n; h=0.0} }
for ($i = 0; $i -lt 20; $i++) {
  $n = ($i * 3 % 56) + 1
  $pool += @{p='N'; n=$n; h=[double](35 + $i * 17)}
}
$rng = New-Object System.Random 42
$pool = $pool | Sort-Object { $rng.Next() }

$raw = Get-Content $dataFile -Raw
$json = $raw | ConvertFrom-Json
$byId = @{}
foreach ($e in $json) { $byId[$e.id] = $e }

# Evolution chains for generated echoes only.
$chains = @()
$childOf = @{}
foreach ($e in $json) {
  if ($e.evolve_to -and $e.evolve_to -ne '') { $childOf[$e.evolve_to] = $e.id }
}
foreach ($e in $json) {
  if ($preserve -contains $e.id) { continue }
  if ($childOf.ContainsKey($e.id)) { continue }
  $chain = @($e.id)
  $cur = $e.id
  while ($byId[$cur].evolve_to -and $byId[$cur].evolve_to -ne '') {
    $cur = $byId[$cur].evolve_to
    $chain += $cur
  }
  $chains += ,$chain
}

$poolIdx = 0
$written = 0
foreach ($chain in ($chains | Sort-Object { $_.Count })) {
  # Pick assignments with maximally different monster numbers within the chain.
  $nums = @(1..56) | Sort-Object { $rng.Next() }
  for ($st = 0; $st -lt $chain.Count; $st++) {
    $id = $chain[$st]
    if ($preserve -contains $id) { continue }
    $spec = $pool[$poolIdx % $pool.Count]
    $poolIdx++
    # Force distinct silhouette per evolution stage when possible.
    $num = $nums[$st % $nums.Count]
    $hue = $spec.h
    if ($spec.h -eq 0) {
      WriteSprite $id $spec.p $num 0 | Out-Null
    } else {
      WriteSprite $id 'N' $num $hue | Out-Null
    }
    $written++
  }
}

Write-Output "Rediversified $written echo sprites across $($chains.Count) families."
