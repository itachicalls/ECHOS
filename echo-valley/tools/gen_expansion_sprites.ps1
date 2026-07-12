Add-Type -AssemblyName System.Drawing
# ============================================================================
# Re-skin the 170 expansion Harmons with the SAME high-quality art as the
# originals: the "50+ Monsters Pack 2D" (detailed 64x64 front/back sprites),
# replacing the blocky upscaled tiny-creature art.
#
#  * 56 silhouettes x 2 authored palettes (Normal/Alternative) = 112 base looks.
#  * We need 170 unique images, so overflow gets a deterministic hue rotation
#    (authored colours preserved for the first pass; families/legends spread
#    so evolution stages never share an image).
#  * Only overwrites PNGs under assets/echoes — echoes.json already points here,
#    so NO data changes are needed.
#  * Run dedupe_sprites.ps1 -Apply afterwards to guarantee zero collisions with
#    the original roster.
# ============================================================================

$root      = "c:\Users\smyde\memoir\echo-valley"
$echoesDir = Join-Path $root "assets\echoes"
$monDir    = Join-Path $root "assets\raw\monsters\50+ Monsters Pack 2D\Monsters"

# ---- the 170 new ids, in the SAME family/legend order gen_expansion used -----
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

$legends = @(
  'Leviathos','Maelstriden','Voltmonarch','Skysovereign','Aeonmind','Nyxarch',
  'Mortarch','Hallowraith','Pyrothrone','Solarch','Sylvanking','Gaialith',
  'Terralossus','Orogenus','Tempestria','Abyssareign','Grimsovereign','Chorusprime',
  'Fracturael','Primordius'
)

# resonance -> hue nudge (degrees) so re-tinted overflow reads on-type
$resTint = @{ water=205; air=52; shadow=280; fire=8; grass=110; rock=32 }

# ---- build ordered list of family ids with their resonance -------------------
$famList = @()   # each: @{ id=..; res=..; stage=.. }
foreach ($type in $famOrder) {
  foreach ($tri in $families[$type]) {
    for ($st = 0; $st -lt 3; $st++) {
      $famList += @{ id = $tri[$st].ToLower(); res = $type; stage = $st }
    }
  }
}

# ---- monster silhouette pool: (num, palette) --------------------------------
$bases = @()
for ($n = 1; $n -le 56; $n++) { $bases += @{ n = $n; pal = 'Normal' } }
for ($n = 1; $n -le 56; $n++) { $bases += @{ n = $n; pal = 'Alternative' } }

# deterministic shuffle (fixed seed for reproducibility)
$rand = New-Object System.Random 20260712
for ($i = $bases.Count - 1; $i -gt 0; $i--) {
  $j = $rand.Next(0, $i + 1)
  $tmp = $bases[$i]; $bases[$i] = $bases[$j]; $bases[$j] = $tmp
}

# hue rings for overflow beyond 112 base looks
$hueRing = @(0, 155, 300)

# ---- helpers ----------------------------------------------------------------
function MonPath($n, $pal, $face) {
  return Join-Path $monDir ("{0} Colors\Monster #{1} {2} {0} Color Palette.png" -f $pal, $n, $face)
}

function RotateHue([System.Drawing.Bitmap]$bmp, [double]$deg) {
  if ($deg -eq 0) { return }
  $w = $bmp.Width; $h = $bmp.Height
  $rect = New-Object System.Drawing.Rectangle 0,0,$w,$h
  $bd = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $bytes = $w * $h * 4
  $buf = New-Object byte[] $bytes
  [System.Runtime.InteropServices.Marshal]::Copy($bd.Scan0, $buf, 0, $bytes)
  $rad = $deg * [Math]::PI / 180.0
  $cos = [Math]::Cos($rad); $sin = [Math]::Sin($rad)
  for ($i = 0; $i -lt $bytes; $i += 4) {
    $b = $buf[$i]; $g = $buf[$i+1]; $r = $buf[$i+2]; $a = $buf[$i+3]
    if ($a -eq 0) { continue }
    $rr = $r/255.0; $gg = $g/255.0; $bb = $b/255.0
    $nr = (0.299 + 0.701*$cos + 0.168*$sin)*$rr + (0.587 - 0.587*$cos + 0.330*$sin)*$gg + (0.114 - 0.114*$cos - 0.497*$sin)*$bb
    $ng = (0.299 - 0.299*$cos - 0.328*$sin)*$rr + (0.587 + 0.413*$cos + 0.035*$sin)*$gg + (0.114 - 0.114*$cos + 0.292*$sin)*$bb
    $nb = (0.299 - 0.300*$cos + 1.250*$sin)*$rr + (0.587 - 0.588*$cos - 1.050*$sin)*$gg + (0.114 + 0.886*$cos - 0.203*$sin)*$bb
    $buf[$i]   = [byte][Math]::Max(0,[Math]::Min(255,[Math]::Round($nb*255)))
    $buf[$i+1] = [byte][Math]::Max(0,[Math]::Min(255,[Math]::Round($ng*255)))
    $buf[$i+2] = [byte][Math]::Max(0,[Math]::Min(255,[Math]::Round($nr*255)))
  }
  [System.Runtime.InteropServices.Marshal]::Copy($buf, 0, $bd.Scan0, $bytes)
  $bmp.UnlockBits($bd)
}

function WriteMon($srcPath, $dstPath, $deg) {
  if (-not (Test-Path $srcPath)) { Write-Warning "missing $srcPath"; return $false }
  $img = [System.Drawing.Bitmap]::FromFile($srcPath)
  $bmp = New-Object System.Drawing.Bitmap $img.Width, $img.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.DrawImage($img, 0, 0, $img.Width, $img.Height)
  $g.Dispose(); $img.Dispose()
  RotateHue $bmp $deg
  $bmp.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  return $true
}

# ---- assign families --------------------------------------------------------
$written = 0
for ($i = 0; $i -lt $famList.Count; $i++) {
  $entry = $famList[$i]
  $base = $bases[$i % $bases.Count]
  $ring = $hueRing[[Math]::Floor($i / $bases.Count)]
  # blend a light resonance tint into overflow rings only (keep authored colours on ring 0)
  $deg = $ring
  if ($ring -ne 0) { $deg = ($ring + $resTint[$entry.res]) % 360 }
  $front = MonPath $base.n $base.pal 'Front'
  $back  = MonPath $base.n $base.pal 'Back'
  WriteMon $front (Join-Path $echoesDir ("{0}.png" -f $entry.id)) $deg | Out-Null
  if (Test-Path $back) { WriteMon $back (Join-Path $echoesDir ("{0}_back.png" -f $entry.id)) $deg | Out-Null }
  else { WriteMon $front (Join-Path $echoesDir ("{0}_back.png" -f $entry.id)) $deg | Out-Null }
  $written++
}

# ---- assign legendaries: hand-picked IMPOSING silhouettes + signature hue -----
# Silhouettes chosen from the pack montage for size/menace (same order as $legends):
# Leviathos=orca#30, Maelstriden=serpent#27, Voltmonarch=owl#24, Skysovereign=raptor#34,
# Aeonmind=mystic-hydra#28, Nyxarch=dark-serpent#26, Mortarch=golem#33, Hallowraith=beast#43,
# Pyrothrone=dragon#44, Solarch=gold-golem#41, Sylvanking=gator#35, Gaialith=titan-dino#5,
# Terralossus=rhino#36, Orogenus=crab#13, Tempestria=dragon#54, Abyssareign=beast#46,
# Grimsovereign=wolf#42, Chorusprime=raccoon-beast#48, Fracturael=scorpion#47, Primordius=great-dragon#55
$legMon = @(30, 27, 24, 34, 28, 26, 33, 43, 44, 41, 35, 5, 36, 13, 54, 46, 42, 48, 47, 55)
$legHue = @(200, 188, 48, 42, 275, 288, 258, 305, 6, 40, 112, 100, 28, 20, 202, 214, 292, 52, 32, 278)
for ($k = 0; $k -lt $legends.Count; $k++) {
  $id = $legends[$k].ToLower()
  $n = $legMon[$k]
  $front = MonPath $n 'Alternative' 'Front'
  $back  = MonPath $n 'Alternative' 'Back'
  $deg = $legHue[$k]
  WriteMon $front (Join-Path $echoesDir ("{0}.png" -f $id)) $deg | Out-Null
  if (Test-Path $back) { WriteMon $back (Join-Path $echoesDir ("{0}_back.png" -f $id)) $deg | Out-Null }
  else { WriteMon $front (Join-Path $echoesDir ("{0}_back.png" -f $id)) $deg | Out-Null }
  $written++
}

Write-Output ("Re-skinned $written Harmons from the 50+ Monsters Pack (families: " + $famList.Count + ", legends: " + $legends.Count + ").")
