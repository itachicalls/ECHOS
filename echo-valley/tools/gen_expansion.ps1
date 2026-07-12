Add-Type -AssemblyName System.Drawing
# ============================================================================
# Echo Valley EXPANSION generator.
#  * Adds 150 new Harmons (50 three-stage families) + 20 legendaries = 170.
#  * Each gets a UNIQUE sprite from the Kenney "Tiny Creatures" pack (180 art),
#    upscaled 16 -> 64 (nearest neighbour). Back sprite = horizontal flip.
#  * Emits stats, learnsets (new + existing chimes), evolutions, descriptions.
#  * Idempotent-ish: skips any echo id already present in echoes.json.
# ============================================================================

$root      = "c:\Users\smyde\memoir\echo-valley"
$echoesDir = Join-Path $root "assets\echoes"
$dataFile  = Join-Path $root "data\echoes.json"
$tcDir     = Join-Path $root "assets\raw\tiny-creatures\tiny-creatures\Tiles"

function UpscaleTile($tileNum, $dstPath, [bool]$flip) {
  $src = Join-Path $tcDir ("tile_{0:D4}.png" -f $tileNum)
  if (-not (Test-Path $src)) { Write-Warning "missing tile $tileNum"; return $false }
  $t = [System.Drawing.Bitmap]::FromFile($src)
  if ($flip) { $t.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX) }
  $bmp = New-Object System.Drawing.Bitmap 64, 64
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
  $dst = New-Object System.Drawing.Rectangle 0,0,64,64
  $g.DrawImage($t, $dst, (New-Object System.Drawing.Rectangle 0,0,$t.Width,$t.Height), [System.Drawing.GraphicsUnit]::Pixel)
  $g.Dispose()
  $bmp.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose(); $t.Dispose()
  return $true
}

function WriteSprite($id, $tileNum) {
  UpscaleTile $tileNum (Join-Path $echoesDir "$id.png") $false | Out-Null
  UpscaleTile $tileNum (Join-Path $echoesDir "${id}_back.png") $true | Out-Null
}

# --- combat identity (matches gen_roster archetypes) -------------------------
$arch = @{
  fire   = @(46,58,42,44); water  = @(52,46,52,40); grass  = @(50,50,48,44)
  rock   = @(56,46,64,26); air    = @(42,52,38,60); shadow = @(44,56,40,52)
}
$stageMul = @(1.0, 1.35, 1.78)

# learnset ladders: 5 attack moves per resonance (mix of new + existing chimes)
$mv = @{
  fire   = @('flame_dart','scorch_fang','blaze_rush','magma_ball','firestorm')
  water  = @('aqua_jet','ice_fang','torrent_wave','geyser_blast','maelstrom_surge')
  grass  = @('seed_bomb','leaf_blade','vine_whip','thorn_burst','bloom_beam')
  rock   = @('rock_slide','boulder_toss','crag_smash','quake_stomp','landslide')
  air    = @('spark_bite','shock_wave','thunder_bolt','discharge','storm_gale')
  shadow = @('shade_nip','hex_bolt','shadow_claw','doom_beam','nightmare')
}
$util = @{ fire='warm_nuzzle'; water='aqua_ring'; grass='mega_drain'; rock='harden'; air='quick_jab'; shadow='spirit_drain' }
$buff = @{ fire='focus'; water='harden'; grass='photosynth'; rock='guard_up'; air='galvanize'; shadow='focus' }

$desc = @{
  fire   = @('An ember-warm {n} that smoulders quietly.','A blazing {n} wreathed in restless heat.','A towering {n} crowned in living fire.')
  water  = @('A dewy {n} that plays in the shallows.','A tidal {n} that rides the coastal current.','A deep {n} whose song stirs the sea.')
  grass  = @('A sprouting {n} humming with green life.','A thorned {n} bound in coiling vines.','An ancient {n} rooted deep in old growth.')
  rock   = @('A pebbly {n} that dozes beneath ledges.','A craggy {n} sheathed in mossy stone.','A colossal {n} born of deep bedrock.')
  air    = @('A crackling {n} buzzing with static.','A swift {n} that races the storm front.','A thunder-born {n} that walks the gale.')
  shadow = @('A hushed {n} with softly glowing eyes.','A shrouded {n} woven from twilight.','A void-touched {n} that drinks the light.')
}

# ---- 50 families (3 stages) --------------------------------------------------
$families = @{
  water = @(
    @('Dripling','Splooze','Tidalisk'), @('Shellby','Caraspine','Fortclaw'),
    @('Pearlet','Nacreef','Abysshell'), @('Fintot','Sharkling','Megalodrift'),
    @('Coraline','Reefspire','Atollus'), @('Mistkoi','Rainkoi','Monsoong'),
    @('Puddlepaw','Ottersurge','Hydranox'), @('Kelplet','Weedwhirl','Sargasso'),
    @('Frostdew','Snowmelt','Glacierra'))
  air = @(
    @('Sparklit','Voltwing','Stormraptor'), @('Buzzfly','Zaptenna','Tesloom'),
    @('Wattpup','Amperewolf','Voltcanine'), @('Statikit','Chargewisp','Plasmind'),
    @('Kiteon','Glidewatt','Thunderoc'), @('Ionling','Dynamo','Galvanix'),
    @('Breezik','Squallow','Cyclonimbus'), @('Feathervolt','Arcwing','Skytalon'),
    @('Zephyrl','Galewhisk','Tempestwing'))
  shadow = @(
    @('Psybud','Mesmind','Hypnaura'), @('Dreamlet','Lullabye','Somnarch'),
    @('Runelet','Sigilix','Arcanexus'), @('Orbitot','Astralynx','Cosmindra'),
    @('Blinkit','Warppaw','Telephase'), @('Willowick','Foxfyre','Mindflare'),
    @('Tombkin','Cryptid','Sarcolord'), @('Boneling','Rattlejaw','Ossuary'),
    @('Wispire','Shroudmoth','Reaperwing'), @('Gravemoss','Wraithvine','Tombthorn'),
    @('Candleflit','Lanternox','Pyrewraith'), @('Ghastling','Poltergeist','Banshee'))
  fire = @(
    @('Cindermol','Magmapup','Volcanid'), @('Torchit','Flambeau','Infernost'),
    @('Ashwing','Cinderavian','Phoenixar'), @('Embertoad','Lavaleap','Calderoad'),
    @('Sparkitten','Flarecat','Pyrelynx'), @('Coalkin','Charhound','Hellhoof'))
  grass = @(
    @('Seedpup','Sprouthound','Bloomastiff'), @('Buddle','Petallure','Floradiance'),
    @('Vinelet','Thornwhip','Bramblejaw'), @('Fungit','Sporewalk','Mycelith'),
    @('Cactopup','Needloom','Saguaroth'), @('Mosskit','Lichenous','Verdammoth'),
    @('Leaflit','Frondancer','Canopyre'), @('Berrybop','Orchardon','Harvestide'))
  rock = @(
    @('Pebblepup','Cobbleton','Bastioth'), @('Gravelisk','Quarrywyrm','Tectonyx'),
    @('Dustmite','Sandwurm','Dunecrag'), @('Ironnib','Steelplate','Magnetron'),
    @('Crystallit','Geodon','Prismshard'), @('Claykin','Terracottus','Golemith'))
}
$famOrder = @('water','air','shadow','fire','grass','rock')

# ---- 20 legendaries ----------------------------------------------------------
$legends = @(
  @{n='Leviathos';    r='water'},  @{n='Maelstriden';  r='water'},
  @{n='Voltmonarch';  r='air'},    @{n='Skysovereign'; r='air'},
  @{n='Aeonmind';     r='shadow'}, @{n='Nyxarch';      r='shadow'},
  @{n='Mortarch';     r='shadow'}, @{n='Hallowraith';  r='shadow'},
  @{n='Pyrothrone';   r='fire'},   @{n='Solarch';      r='fire'},
  @{n='Sylvanking';   r='grass'},  @{n='Gaialith';     r='grass'},
  @{n='Terralossus';  r='rock'},   @{n='Orogenus';     r='rock'},
  @{n='Tempestria';   r='air'},    @{n='Abyssareign';  r='water'},
  @{n='Grimsovereign';r='shadow'}, @{n='Chorusprime';  r='air'},
  @{n='Fracturael';   r='rock'},   @{n='Primordius';   r='shadow'}
)

# ---- tile assignment ---------------------------------------------------------
$nonCreature = @(81,82,83,86)
# epic tiles hand-picked per legendary (same order as $legends below):
# Leviathos=sea-dragon, Maelstriden=water-elem, Voltmonarch=griffin, Skysovereign=winged,
# Aeonmind=wizard, Nyxarch=vampire, Mortarch=skeleton, Hallowraith=devil, Pyrothrone=fire-elem,
# Solarch=sun-skull, Sylvanking=hydra, Gaialith=hydra, Terralossus=golem, Orogenus=golem,
# Tempestria=blue-dragon, Abyssareign=ice-crystal, Grimsovereign=dragon, Chorusprime=angel,
# Fracturael=cracked-golem, Primordius=great-dragon
$legendTiles = @(9,47,33,31,66,3,2,39,46,4,111,112,127,128,32,50,34,37,129,35)
$famPool = @()
for ($i = 1; $i -le 180; $i++) {
  if ($nonCreature -contains $i) { continue }
  if ($legendTiles -contains $i) { continue }
  $famPool += $i
}
$famIdx = 0

# ---- helpers ----------------------------------------------------------------
function MkLearn($entries) {
  $parts = @()
  foreach ($e in $entries) { $parts += ('{{"level":{0},"chime":"{1}"}}' -f $e[0], $e[1]) }
  return '[ ' + ($parts -join ', ') + ' ]'
}
function BuildLearnset($type, $stage) {
  $m = $mv[$type]; $u = $util[$type]; $b = $buff[$type]
  switch ($stage) {
    0 { return MkLearn @(@(1,'tackle'), @(1,$m[0]), @(5,$u), @(9,$m[1]), @(13,$m[2])) }
    1 { return MkLearn @(@(1,'tackle'), @(1,$m[0]), @(1,$m[1]), @(16,$m[2]), @(22,$b), @(28,$m[3])) }
    default { return MkLearn @(@(1,$m[1]), @(1,$m[2]), @(1,$m[3]), @(32,$u), @(36,$m[4])) }
  }
}
function LegendLearn($type) {
  $m = $mv[$type]; $b = $buff[$type]
  return MkLearn @(@(1,$m[2]), @(1,$m[3]), @(1,$m[4]), @(1,$b), @(45,$m[4]))
}

# existing echo ids (never regenerate / never collide)
$existingJson = Get-Content $dataFile -Raw | ConvertFrom-Json
$seen = @{}
foreach ($e in $existingJson) { $seen[$e.id] = $true }

$evolveLv = @(16, 34)
$catch = @(0.35, 0.12, 0.05)
$newEntries = @()
$spriteCount = 0; $echoCount = 0

foreach ($type in $famOrder) {
  foreach ($tri in $families[$type]) {
    $ids = @(); foreach ($nm in $tri) { $ids += $nm.ToLower() }
    for ($st = 0; $st -lt 3; $st++) {
      $id = $ids[$st]
      if ($seen.ContainsKey($id)) { Write-Warning "dup id $id skipped"; continue }
      $seen[$id] = $true
      $nm = $tri[$st]
      $tile = $famPool[$famIdx]; $famIdx++
      WriteSprite $id $tile; $spriteCount++
      $a = $arch[$type]; $mul = $stageMul[$st]
      $hp = [int][math]::Round($a[0]*$mul); $pw = [int][math]::Round($a[1]*$mul)
      $gd = [int][math]::Round($a[2]*$mul); $sw = [int][math]::Round($a[3]*$mul)
      $evoTo = ''; $evoLv = 0
      if ($st -lt 2) { $evoTo = $ids[$st+1]; $evoLv = $evolveLv[$st] }
      $ls = BuildLearnset $type $st
      $d = ($desc[$type][$st] -replace '\{n\}', $nm.ToLower())
      $newEntries += @"
  {
    "id": "$id", "name": "$nm", "resonance": "$type",
    "base_stats": { "hp": $hp, "power": $pw, "guard": $gd, "swift": $sw },
    "learnset": $ls,
    "evolve_to": "$evoTo", "evolve_level": $evoLv, "catch_rate": $($catch[$st]),
    "sprite": "res://assets/echoes/$id.png",
    "description": "$d"
  }
"@
      $echoCount++
    }
  }
}

# legendaries
$legIdx = 0
foreach ($L in $legends) {
  $id = $L.n.ToLower(); $type = $L.r
  if ($seen.ContainsKey($id)) { Write-Warning "dup legendary $id skipped"; continue }
  $seen[$id] = $true
  $tile = $legendTiles[$legIdx]; $legIdx++
  WriteSprite $id $tile; $spriteCount++
  # legendary flat high stats, biased by resonance archetype shape
  $a = $arch[$type]
  $hp = [int][math]::Round($a[0]*1.95 + 6);  $pw = [int][math]::Round($a[1]*1.95 + 6)
  $gd = [int][math]::Round($a[2]*1.95 + 6);  $sw = [int][math]::Round($a[3]*1.95 + 6)
  $ls = LegendLearn $type
  $newEntries += @"
  {
    "id": "$id", "name": "$($L.n)", "resonance": "$type",
    "base_stats": { "hp": $hp, "power": $pw, "guard": $gd, "swift": $sw },
    "learnset": $ls,
    "evolve_to": "", "evolve_level": 0, "catch_rate": 0.02,
    "sprite": "res://assets/echoes/$id.png",
    "description": "A legendary $type Harmon spoken of only in old resonance-songs."
  }
"@
  $echoCount++
}

# merge before final ]
$orig = Get-Content $dataFile -Raw
$orig = $orig.TrimEnd()
$orig = $orig.Substring(0, $orig.LastIndexOf(']')).TrimEnd().TrimEnd(',')
$merged = $orig + ",`n" + ($newEntries -join ",`n") + "`n]`n"
Set-Content -Path $dataFile -Value $merged -Encoding UTF8

Write-Output "New echoes: $echoCount   sprites: $spriteCount   family tiles used: $famIdx / $($famPool.Count)   legendaries: $legIdx"
