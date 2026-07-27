Add-Type -AssemblyName System.Drawing
# Wave 2 Harmons from Pixel Pack #2 (unique art) + Kenney Monster Builder composites.
$ErrorActionPreference = "Stop"
$root = "c:\Users\smyde\memoir\echo-valley"
$echoDir = Join-Path $root "assets\echoes"
$echoJson = Join-Path $root "data\echoes.json"
$nv = Join-Path $root "assets\raw\monsters\pixel_pack_2\Monsters\New Versions"
$kenney = Join-Path $root "assets\raw\monsters\kenney_monster_builder\PNG\Default"

function Scale-Nearest([System.Drawing.Bitmap]$src, [int]$size) {
  $dst = New-Object System.Drawing.Bitmap $size, $size
  $dst.SetResolution(96, 96)
  $g = [System.Drawing.Graphics]::FromImage($dst)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
  $g.Clear([System.Drawing.Color]::Transparent)
  # fit into square with padding
  $scale = [Math]::Min($size / [double]$src.Width, $size / [double]$src.Height) * 0.92
  $w = [int]($src.Width * $scale)
  $h = [int]($src.Height * $scale)
  $x = [int](($size - $w) / 2)
  $y = [int](($size - $h) / 2)
  $g.DrawImage($src, $x, $y, $w, $h)
  $g.Dispose()
  return $dst
}

$script:EyePool = @(Get-ChildItem $kenney -Filter "eye_*.png" | ForEach-Object { $_.Name })
$script:MouthPool = @(Get-ChildItem $kenney -Filter "mouth_*.png" | ForEach-Object { $_.Name })
$script:DetailPool = @(Get-ChildItem $kenney -Filter "detail_*.png" | ForEach-Object { $_.Name })

function Compose-Kenney([string]$color, [string]$bodyL, [string]$armL, [int]$seed) {
  $rng = New-Object System.Random $seed
  $canvas = New-Object System.Drawing.Bitmap 200, 200
  $g = [System.Drawing.Graphics]::FromImage($canvas)
  $g.Clear([System.Drawing.Color]::Transparent)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $eye = $script:EyePool[$rng.Next(0, $script:EyePool.Count)]
  $mouth = $script:MouthPool[$rng.Next(0, $script:MouthPool.Count)]
  $detail = $null
  $colorDetails = @($script:DetailPool | Where-Object { $_ -like "detail_${color}_*" })
  if ($colorDetails.Count -gt 0) { $detail = $colorDetails[$rng.Next(0, $colorDetails.Count)] }
  $parts = [System.Collections.ArrayList]@(
    @{ f = "body_${color}${bodyL}.png"; ox = 18; oy = 28 },
    @{ f = "leg_${color}${bodyL}.png"; ox = 50; oy = 118 },
    @{ f = "arm_${color}${armL}.png"; ox = 0; oy = 50 },
    @{ f = "arm_${color}${armL}.png"; ox = 130; oy = 50; flip = $true },
    @{ f = $mouth; ox = 70; oy = 85 },
    @{ f = $eye; ox = 62; oy = 48 }
  )
  if ($detail) { [void]$parts.Add(@{ f = $detail; ox = 70; oy = 10 }) }
  foreach ($p in $parts) {
    $path = Join-Path $kenney $p.f
    if (-not (Test-Path $path)) { continue }
    $bmp = [System.Drawing.Bitmap]::FromFile($path)
    if ($p.flip) {
      $tmp = $bmp.Clone()
      $tmp.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)
      $bmp.Dispose(); $bmp = $tmp
    }
    # scale large parts down a bit onto canvas
    $dw = [Math]::Min($bmp.Width, 90)
    $dh = [Math]::Min($bmp.Height, 90)
    if ($p.f -like "body_*") { $dw = 120; $dh = 120 }
    if ($p.f -like "arm_*") { $dw = 55; $dh = 90 }
    if ($p.f -like "leg_*") { $dw = 70; $dh = 70 }
    if ($p.f -like "eye_*" -or $p.f -like "mouth_*") { $dw = 50; $dh = 40 }
    if ($p.f -like "detail_*") { $dw = 45; $dh = 45 }
    $g.DrawImage($bmp, [int]$p.ox, [int]$p.oy, $dw, $dh)
    $bmp.Dispose()
  }
  $g.Dispose()
  $out = Scale-Nearest $canvas 64
  $canvas.Dispose()
  return $out
}

function Mirror-Back([System.Drawing.Bitmap]$front) {
  $back = $front.Clone()
  $back.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)
  return $back
}

$existing = (Get-Content $echoJson -Raw | ConvertFrom-Json)
$existIds = [System.Collections.Generic.HashSet[string]]::new()
foreach ($e in $existing) { [void]$existIds.Add([string]$e.id) }

$newEntries = @()

# --- Pixel Pack 2 unique monsters ---
$ppMap = @(
  @{ src='zoonami_burrlock'; id='burrlock'; name='Burrlock'; res='grass'; hp=48; pow=52; grd=55; sw=40; desc='A burred shell-beast that rolls through thickets.' },
  @{ src='zoonami_chickadee'; id='chirplet'; name='Chirplet'; res='air'; hp=40; pow=48; grd=36; sw=62; desc='A tiny songbird Harmon with needle-sharp notes.' },
  @{ src='zoonami_fuzall'; id='fuzall'; name='Fuzall'; res='rock'; hp=55; pow=50; grd=58; sw=35; desc='A fuzzy boulder that shrugs off blows.' },
  @{ src='zoonami_grimlit'; id='grimlit'; name='Grimlit'; res='shadow'; hp=44; pow=58; grd=40; sw=50; desc='A lantern-eyed shade that feeds on hush.' },
  @{ src='zoonami_howler'; id='howler'; name='Howler'; res='shadow'; hp=50; pow=60; grd=42; sw=48; desc='Its cry rattles the Fracture itself.' },
  @{ src='zoonami_kackaburr'; id='kackaburr'; name='Kackaburr'; res='air'; hp=46; pow=54; grd=40; sw=58; desc='A laughing sky-beast with storm-feather wings.' },
  @{ src='zoonami_maluga'; id='maluga'; name='Maluga'; res='water'; hp=62; pow=55; grd=50; sw=38; desc='A deep-sea bulk that surfaces only for battles.' },
  @{ src='zoonami_merin'; id='merin'; name='Merin'; res='water'; hp=48; pow=50; grd=45; sw=55; desc='A sleek tide-dancer with pearl-bright fins.' },
  @{ src='zoonami_ruffalo'; id='ruffalo'; name='Ruffalo'; res='rock'; hp=60; pow=58; grd=52; sw=36; desc='A shaggy cliff-beast with iron horns.' },
  @{ src='zoonami_scallapod'; id='scallapod'; name='Scallapod'; res='water'; hp=42; pow=46; grd=60; sw=44; desc='A shell-pod Harmon that snaps shut like armor.' },
  @{ src='zoonami_spaero'; id='spaero'; name='Spaero'; res='electric'; hp=45; pow=56; grd=40; sw=60; desc='A hovering orb crackling with static song.' }
)

$learnByRes = @{
  fire = @(@{l=1;c='tackle'},@{l=1;c='ember_spark'},@{l=8;c='fire_fang'},@{l=16;c='flame_wave'},@{l=28;c='inferno_pulse'},@{l=40;c='wildfire_nova'},@{l=55;c='phoenix_dive'},@{l=70;c='solar_cataclysm'})
  water = @(@{l=1;c='tackle'},@{l=1;c='bubble_pop'},@{l=8;c='aqua_slash'},@{l=16;c='tide_surge'},@{l=28;c='geyser_burst'},@{l=40;c='maelstrom_spin'},@{l=55;c='abyss_pressure'},@{l=70;c='ocean_collapse'})
  grass = @(@{l=1;c='tackle'},@{l=1;c='leaf_cut'},@{l=8;c='vine_lash'},@{l=16;c='spore_cloud'},@{l=28;c='canopy_crash'},@{l=40;c='bloom_barrage'},@{l=55;c='verdant_judgment'},@{l=70;c='gaia_rupture'})
  rock = @(@{l=1;c='tackle'},@{l=1;c='pebble_toss'},@{l=8;c='stone_bash'},@{l=16;c='quake_stomp'},@{l=28;c='boulder_crash'},@{l=40;c='tectonic_slam'},@{l=55;c='mountain_fall'},@{l=70;c='world_fracture'})
  air = @(@{l=1;c='tackle'},@{l=1;c='gust'},@{l=8;c='wing_slash'},@{l=16;c='gale_force'},@{l=28;c='sky_dive'},@{l=40;c='cyclone_spin'},@{l=55;c='tempest_crown'},@{l=70;c='sky_sovereign_blow'})
  shadow = @(@{l=1;c='tackle'},@{l=1;c='shadow_nip'},@{l=8;c='hex_bolt'},@{l=16;c='night_slash'},@{l=28;c='curse_wail'},@{l=40;c='void_rift'},@{l=55;c='reaper_scythe'},@{l=70;c='eclipse_finale'})
  electric = @(@{l=1;c='tackle'},@{l=1;c='spark_bite'},@{l=8;c='thunder_bolt'},@{l=16;c='shock_wave'},@{l=28;c='volt_tackle'},@{l=40;c='plasma_lance'},@{l=55;c='storm_monarch'},@{l=70;c='zero_point_arc'})
  psychic = @(@{l=1;c='tackle'},@{l=1;c='psy_nudge'},@{l=8;c='psy_beam'},@{l=16;c='mind_crush'},@{l=28;c='psi_pulse'},@{l=40;c='astral_gaze'},@{l=55;c='dream_collapse'},@{l=70;c='chorus_singularity'})
}

foreach ($m in $ppMap) {
  if ($existIds.Contains($m.id)) { Write-Host "skip existing $($m.id)"; continue }
  $frontSrc = Join-Path $nv ($m.src + "_front.png")
  $backSrc = Join-Path $nv ($m.src + "_back.png")
  if (-not (Test-Path $frontSrc)) { Write-Host "missing $frontSrc"; continue }
  $fb = [System.Drawing.Bitmap]::FromFile($frontSrc)
  $front = Scale-Nearest $fb 64
  $fb.Dispose()
  $front.Save((Join-Path $echoDir ($m.id + ".png")), [System.Drawing.Imaging.ImageFormat]::Png)
  if (Test-Path $backSrc) {
    $bb = [System.Drawing.Bitmap]::FromFile($backSrc)
    $back = Scale-Nearest $bb 64
    $bb.Dispose()
  } else {
    $back = Mirror-Back $front
  }
  $back.Save((Join-Path $echoDir ($m.id + "_back.png")), [System.Drawing.Imaging.ImageFormat]::Png)
  $front.Dispose(); $back.Dispose()
  $ls = @()
  foreach ($e in $learnByRes[$m.res]) { $ls += @{ level = $e.l; chime = $e.c } }
  $newEntries += [ordered]@{
    id = $m.id; name = $m.name; resonance = $m.res
    base_stats = @{ hp = $m.hp; power = $m.pow; guard = $m.grd; swift = $m.sw }
    learnset = $ls; catch_rate = 0.28
    sprite = "res://assets/echoes/$($m.id).png"
    sprite_back = "res://assets/echoes/$($m.id)_back.png"
    description = $m.desc
  }
  [void]$existIds.Add($m.id)
  Write-Host "PP2 $($m.id)"
}

# --- Kenney composed families (tri-stage) ---
$colors = @('red','blue','green','yellow','dark','white')
$resForColor = @{ red='fire'; blue='water'; green='grass'; yellow='electric'; dark='shadow'; white='air' }
$letters = @('A','B','C','D','E')
$families = @(
  @{ base='scrapkit'; mid='junkjaw'; fin='scraplord'; res='rock'; names=@('Scrapkit','Junkjaw','Scraplord'); descs=@('A junkpile pup.','A scrap-jaw scavenger.','A walking scrapyard sovereign.') },
  @{ base='boltkit'; mid='coilfox'; fin='voltforge'; res='electric'; names=@('Boltkit','Coilfox','Voltforge'); descs=@('A buzzing kit.','A coil-tailed fox.','A forge of living voltage.') },
  @{ base='mistpup'; mid='foghound'; fin='nimbrawl'; res='air'; names=@('Mistpup','Foghound','Nimbrawl'); descs=@('A fog-born pup.','A hound of low clouds.','A brawling thunderhead.') },
  @{ base='glimbit'; mid='shadecap'; fin='voidhelm'; res='shadow'; names=@('Glimbit','Shadecap','Voidhelm'); descs=@('A glinting shade.','A capped dusk-walker.','A helm of the void.') },
  @{ base='pebbit'; mid='cragbit'; fin='bastionox'; res='rock'; names=@('Pebbit','Cragbit','Bastionox'); descs=@('A pebble bit.','A crag-bit bruiser.','An ox of living bastion.') },
  @{ base='siphon'; mid='draingest'; fin='leechrex'; res='psychic'; names=@('Siphon','Draingest','Leechrex'); descs=@('A mind siphon.','A gestating drain.','A leeching psychic tyrant.') },
  @{ base='bubkit'; mid='foamjaw'; fin='brinetitan'; res='water'; names=@('Bubkit','Foamjaw','Brinetitan'); descs=@('A bubble kit.','A foam-jaw swimmer.','A titan of brine.') },
  @{ base='seedbit'; mid='thorncap'; fin='briarthorn'; res='grass'; names=@('Seedbit','Thorncap','Briarthorn'); descs=@('A seed bit.','A thorn-capped sprout.','A briar-thorn juggernaut.') },
  @{ base='cindbit'; mid='flarebit'; fin='ashcoloss'; res='fire'; names=@('Cindbit','Flarebit','Ashcoloss'); descs=@('A cinder bit.','A flare-bit spark.','An ash colossus.') },
  @{ base='psybit'; mid='orbkit'; fin='mindforge'; res='psychic'; names=@('Psybit','Orbkit','Mindforge'); descs=@('A psychic bit.','An orbiting kit.','A forge of pure mind.') }
)

$rand = New-Object System.Random 20260726
$fi = 0
foreach ($fam in $families) {
  $color = $colors[$fi % $colors.Count]
  if ($fam.res -eq 'electric') { $color = 'yellow' }
  elseif ($fam.res -eq 'fire') { $color = 'red' }
  elseif ($fam.res -eq 'water') { $color = 'blue' }
  elseif ($fam.res -eq 'grass') { $color = 'green' }
  elseif ($fam.res -eq 'shadow') { $color = 'dark' }
  elseif ($fam.res -eq 'air') { $color = 'white' }
  elseif ($fam.res -eq 'rock') { $color = 'dark' }
  elseif ($fam.res -eq 'psychic') { $color = 'white' }
  for ($st = 0; $st -lt 3; $st++) {
    $id = $fam[@('base','mid','fin')[$st]]
    if ($existIds.Contains($id)) { continue }
    $bodyL = $letters[$rand.Next(0,5)]
    $armL = $letters[$rand.Next(0,5)]
    $front = Compose-Kenney $color $bodyL $armL ($fi * 17 + $st * 3 + 11)
    $back = Mirror-Back $front
    $front.Save((Join-Path $echoDir ($id + ".png")), [System.Drawing.Imaging.ImageFormat]::Png)
    $back.Save((Join-Path $echoDir ($id + "_back.png")), [System.Drawing.Imaging.ImageFormat]::Png)
    $front.Dispose(); $back.Dispose()
    $mult = 1.0 + $st * 0.28
    $ls = @()
    foreach ($e in $learnByRes[$fam.res]) { $ls += @{ level = $e.l; chime = $e.c } }
    $evolve = if ($st -lt 2) { $fam[@('base','mid','fin')[$st+1]] } else { "" }
    $evolvl = if ($st -eq 0) { 18 } elseif ($st -eq 1) { 36 } else { 0 }
    $entry = [ordered]@{
      id = $id; name = $fam.names[$st]; resonance = $fam.res
      base_stats = @{
        hp = [int](40 * $mult); power = [int](48 * $mult)
        guard = [int](42 * $mult); swift = [int](45 * $mult)
      }
      learnset = $ls; catch_rate = (0.35 - $st * 0.1)
      sprite = "res://assets/echoes/$id.png"
      sprite_back = "res://assets/echoes/${id}_back.png"
      description = $fam.descs[$st]
    }
    if ($evolve -ne "") { $entry.evolve_to = $evolve; $entry.evolve_level = $evolvl }
    $newEntries += $entry
    [void]$existIds.Add($id)
    Write-Host "KENNEY $id"
  }
  $fi++
}

# Write fragment for Python merge (avoid PowerShell ConvertTo-Json quirks)
$fragPath = Join-Path $root "tools\wave2_entries.json"
$frag = $newEntries | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText($fragPath, $frag)
Write-Host "Wrote $($newEntries.Count) entries to $fragPath"
