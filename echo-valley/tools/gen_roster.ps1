Add-Type -AssemblyName System.Drawing

# ============================================================================
# Echo Valley roster generator.
#  * Keeps the original 26 hand-authored echoes untouched.
#  * Adds 42 new evolution families (126 echoes) -> 152 total.
#  * Sources art from the 50+ Monsters Pack (Normal + Alternative palettes),
#    generating clean hue-shifted recolours when the clean pool is exhausted.
#  * Emits stats, learnsets, evolution links and descriptions consistently.
# ============================================================================

$root      = "c:\Users\smyde\memoir\echo-valley"
$echoesDir = Join-Path $root "assets\echoes"
$dataFile  = Join-Path $root "data\echoes.json"
$monNorm   = Join-Path $root "assets\raw\monsters\50+ Monsters Pack 2D\Monsters\Normal Colors"
$monAlt    = Join-Path $root "assets\raw\monsters\50+ Monsters Pack 2D\Monsters\Alternative Colors"

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

# --- hue-rotation colour matrix (luminance preserving) ---
function HueMatrix([double]$deg) {
  $a = $deg * [math]::PI / 180.0
  $c = [math]::Cos($a); $s = [math]::Sin($a)
  $m = New-Object 'System.Single[,]' 5,5
  # contribution to R
  $m[0,0] = [single](0.213 + $c*0.787 - $s*0.213)
  $m[1,0] = [single](0.213 - $c*0.213 + $s*0.143)
  $m[2,0] = [single](0.213 - $c*0.213 - $s*0.787)
  # contribution to G
  $m[0,1] = [single](0.715 - $c*0.715 - $s*0.715)
  $m[1,1] = [single](0.715 + $c*0.285 + $s*0.140)
  $m[2,1] = [single](0.715 - $c*0.715 + $s*0.715)
  # contribution to B
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
  $g.Dispose()
  $bmp.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose(); $src.Dispose()
  return $true
}

function CopyPng($srcPath, $dstPath) {
  if (Test-Path $srcPath) { Copy-Item $srcPath $dstPath -Force; return $true }
  return $false
}

# ----------------------------------------------------------------------------
# design pools: normals unused by the original 26, then all alt palettes.
$usedNorm = @(23,18,36,15,3,30,5,32,27,38,17,50,55,4,8,53,25,41,14,51,47,7,22,13,45,39)
$poolClean = @()
foreach ($n in 1..56) { if ($usedNorm -notcontains $n) { $poolClean += @{p='N'; n=$n} } }
foreach ($n in 1..56) { $poolClean += @{p='A'; n=$n} }
$poolIdx = 0
$recolorSeed = 0

function NextSprite($id) {
  # returns $true on success; writes <id>.png and <id>_back.png
  $script:poolIdx
  if ($script:poolIdx -lt $poolClean.Count) {
    $spec = $poolClean[$script:poolIdx]; $script:poolIdx++
    $okF = CopyPng (SrcFront $spec.p $spec.n) (Join-Path $echoesDir "$id.png")
    $okB = CopyPng (SrcBack  $spec.p $spec.n) (Join-Path $echoesDir "${id}_back.png")
    if (-not $okB) { CopyPng (SrcFront $spec.p $spec.n) (Join-Path $echoesDir "${id}_back.png") | Out-Null }
    return $okF
  }
  # recolour path: cycle designs with varied hue
  $num = ($script:recolorSeed % 56) + 1
  $hue = 25 + (($script:recolorSeed * 47) % 300)
  $script:recolorSeed++
  $okF = SaveRecolor (SrcFront 'N' $num) (Join-Path $echoesDir "$id.png") $hue
  $okB = SaveRecolor (SrcBack  'N' $num) (Join-Path $echoesDir "${id}_back.png") $hue
  if (-not $okB) { SaveRecolor (SrcFront 'N' $num) (Join-Path $echoesDir "${id}_back.png") $hue | Out-Null }
  return $okF
}

# ----------------------------------------------------------------------------
# per-type combat identity
$arch = @{
  fire   = @(46,58,42,44); water  = @(52,46,52,40); grass  = @(50,50,48,44)
  rock   = @(56,46,64,26); air    = @(42,52,38,60); shadow = @(44,56,40,52)
}
$stageMul = @(1.0, 1.35, 1.78)
$moves = @{
  fire   = @('ember_spark','fire_fang','flame_wave','inferno')
  water  = @('tide_slap','surge_tail','aqua_pulse','tsunami')
  grass  = @('leaf_dart','vine_lash','canopy_crash','solar_bloom')
  rock   = @('pebble_tap','rock_throw','boulder_bash','stone_edge')
  air    = @('gust_tickle','air_slash','gale_slash','cyclone')
  shadow = @('shade_nip','shadow_claw','night_veil','eclipse')
}
$util = @{ fire='warm_nuzzle'; water='bubble_hug'; grass='leech_seed'; rock='harden'; air='quick_jab'; shadow='shade_drain' }
$buff = @{ fire='focus'; water='harden'; grass='harden'; rock='harden'; air='focus'; shadow='focus' }

$desc = @{
  fire   = @('A spark-tempered {n} that naps in warm ash.','A blazing {n} whose mane crackles with heat.','A towering {n} crowned in roaring flame.')
  water  = @('A dewy {n} that giggles in tidepools.','A tidal {n} that rides the river current.','A deep {n} whose call stirs the sea.')
  grass  = @('A sprouting {n} that hums to the sun.','A thorned {n} wrapped in living vines.','An ancient {n} rooted in old-growth wood.')
  rock   = @('A pebbly {n} that dozes under ledges.','A craggy {n} armored in mossy stone.','A colossal {n} of the deep bedrock.')
  air    = @('A breezy {n} that darts on the wind.','A swift {n} that races the clouds.','A storm-born {n} that walks on gales.')
  shadow = @('A dusky {n} with glimmering eyes.','A shrouded {n} woven from midnight.','A void-touched {n} that swallows light.')
}

# family lists: 7 per type, each 3 stages
$families = @{
  fire = @(
    @('Charby','Charflare','Pyroclast'), @('Kindle','Blazehound','Cerberflame'),
    @('Sparklet','Flintaur','Magmoth'), @('Wickit','Candelu','Inferngeist'),
    @('Ashfoal','Cindersteed','Embermare'), @('Coalpup','Slagfang','Volcanine'),
    @('Fumelet','Scorchid','Solmaw'))
  water = @(
    @('Puddlet','Rippletide','Torrentag'), @('Brooklet','Streamare','Riverwyrm'),
    @('Frostfin','Glacielle','Cryoleth'), @('Snaptide','Shellgar','Fortclam'),
    @('Mistpup','Foghound','Nimburos'), @('Coralet','Reefang','Abyssaw'),
    @('Splashkin','Geysero','Maelstrom'))
  grass = @(
    @('Sproutle','Thornvine','Verdantaur'), @('Budkin','Blossaur','Floralux'),
    @('Acornel','Oakthorn','Timberwood'), @('Sporeling','Myconid','Fungourd'),
    @('Cactling','Prickspan','Sahuaro'), @('Ivylet','Creepvine','Stranglor'),
    @('Petalpup','Bloomhound','Floravore'))
  rock = @(
    @('Cobblit','Bouldrake','Monolith'), @('Shardling','Graniteor','Bedrockus'),
    @('Flintling','Quartzid','Geodrake'), @('Sandnib','Dunejaw','Sarcophage'),
    @('Clayling','Terracor','Colossite'), @('Ironrust','Magnetox','Ferronox'),
    @('Gravelo','Cragmaul','Avalanther'))
  air = @(
    @('Breezle','Zephyro','Tempestrix'), @('Fluffet','Cloudris','Stratoson'),
    @('Kitelet','Glideon','Aeroquil'), @('Chirpwing','Falconox','Skyranger'),
    @('Draftling','Windrik','Cyclonch'), @('Featherkit','Plumeria','Aviarch'),
    @('Sprytefly','Voltbreeze','Thundrift'))
  shadow = @(
    @('Shadelet','Umbrapaw','Nyxeclipse'), @('Gloomkin','Duskmaw','Voidmonarch'),
    @('Hexling','Wraithorn','Banshroud'), @('Murklet','Nocthorn','Tenebris'),
    @('Phantling','Spectron','Reaphowl'), @('Inkspot','Blotusk','Obsidraith'),
    @('Creeple','Grimfang','Mortifume'))
}

# existing ids (never regenerate their sprites / entries)
$existing = @('emberkit','flarefox','infernix','cindboth','tideling','marowl','leviaqua',
  'dewling','naiaqua','aquari','mossling','bramblor','eldertree','fernkit','frondex',
  'pebblit','craggan','titanag','zephyr','gustrel','cyclora','boltmoth','duskling',
  'nocturn','umbrix','wispurr')

$evolveLv = @(16, 34)
$catch = @(0.3, 0.1, 0.04)
$seen = @{}
foreach ($e in $existing) { $seen[$e] = $true }

function MkLearn($entries) {
  $parts = @()
  foreach ($e in $entries) { $parts += ('{{"level":{0},"chime":"{1}"}}' -f $e[0], $e[1]) }
  return '[ ' + ($parts -join ', ') + ' ]'
}

function BuildLearnset($type, $stage) {
  $mv = $moves[$type]; $u = $util[$type]; $b = $buff[$type]
  switch ($stage) {
    0 { return MkLearn @(@(1,'tackle'), @(1,$mv[0]), @(5,$u), @(9,$mv[1]), @(13,$mv[2])) }
    1 { return MkLearn @(@(1,'tackle'), @(1,$mv[0]), @(1,$mv[1]), @(16,$mv[2]), @(22,$b), @(28,$mv[3])) }
    default { return MkLearn @(@(1,$mv[1]), @(1,$mv[2]), @(1,$mv[3]), @(32,$u), @(36,$b)) }
  }
}

$order = @('fire','water','grass','rock','air','shadow')
$newEntries = @()
$spriteCount = 0
$echoCount = 0

foreach ($type in $order) {
  $fam = $families[$type]
  foreach ($tri in $fam) {
    $ids = @()
    foreach ($nm in $tri) { $ids += $nm.ToLower() }
    for ($st = 0; $st -lt 3; $st++) {
      $id = $ids[$st]
      if ($seen.ContainsKey($id)) { Write-Warning "dup id $id skipped"; continue }
      $seen[$id] = $true
      $nm = $tri[$st]
      # sprite
      if (NextSprite $id) { $spriteCount++ }
      # stats
      $a = $arch[$type]; $mul = $stageMul[$st]
      $hp = [int][math]::Round($a[0]*$mul); $pw = [int][math]::Round($a[1]*$mul)
      $gd = [int][math]::Round($a[2]*$mul); $sw = [int][math]::Round($a[3]*$mul)
      # evolution
      $evoTo = ''; $evoLv = 0
      if ($st -lt 2) { $evoTo = $ids[$st+1]; $evoLv = $evolveLv[$st] }
      $ls = BuildLearnset $type $st
      $d = ($desc[$type][$st] -replace '\{n\}', $nm.ToLower())
      $entry = @"
  {
    "id": "$id", "name": "$nm", "resonance": "$type",
    "base_stats": { "hp": $hp, "power": $pw, "guard": $gd, "swift": $sw },
    "learnset": $ls,
    "evolve_to": "$evoTo", "evolve_level": $evoLv, "catch_rate": $($catch[$st]),
    "sprite": "res://assets/echoes/$id.png",
    "description": "$d"
  }
"@
      $newEntries += $entry
      $echoCount++
    }
  }
}

# ----------------------------------------------------------------------------
# merge: keep original file verbatim, append new entries before the final ]
$orig = Get-Content $dataFile -Raw
$orig = $orig.TrimEnd()
$orig = $orig.Substring(0, $orig.LastIndexOf(']')).TrimEnd()
$orig = $orig.TrimEnd(',')
$merged = $orig + ",`n" + ($newEntries -join ",`n") + "`n]`n"
Set-Content -Path $dataFile -Value $merged -Encoding UTF8

Write-Output "New echoes: $echoCount   sprites written: $spriteCount   clean pool used: $poolIdx / $($poolClean.Count)   recolors: $recolorSeed"
Write-Output "echoes.json updated -> $dataFile"
