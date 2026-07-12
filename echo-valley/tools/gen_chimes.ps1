# ============================================================================
# Echo Valley chime (attack) expansion generator.
#  * Adds 150 new attacks/moves to data/chimes.json (keeps the original 38).
#  * Move NAMES are chosen to trigger battle.gd animation styles (keyword-based),
#    including the new styles: storm, psy, curse, geyser, ice, spore, meteor.
#  * Idempotent: skips any id already present in chimes.json.
# ============================================================================

$root     = "c:\Users\smyde\memoir\echo-valley"
$dataFile = Join-Path $root "data\chimes.json"

# --- move name pools per resonance (names carry animation keywords) ----------
$pools = [ordered]@{
  fire = @('Flame Dart','Cinder Toss','Scorch Fang','Blaze Rush','Magma Ball',
    'Lava Bomb','Flare Burst','Meteor Dive','Wildfire Wave','Inferno Lance',
    'Ember Claw','Heat Slash','Pyre Bite','Coal Smash','Molten Edge',
    'Sunflare Beam','Blaze Nuzzle','Firestorm','Cinder Spark','Ashen Gale',
    'Volcano Crash','Phoenix Dive')
  water = @('Aqua Jet','Bubble Beam','Splash Crash','Torrent Wave','Geyser Blast',
    'Whirlpool','Hydro Pulse','Frost Shard','Ice Fang','Blizzard',
    'Glacier Smash','Tide Claw','Coral Slash','Foam Burst','Rain Dance',
    'Cascade','Maelstrom Surge','Deluge Beam','Snow Veil','Frostbite',
    'Aqua Ring','Riptide Whip','Pearl Splash','Abyss Dive')
  grass = @('Seed Bomb','Petal Storm','Spore Cloud','Pollen Puff','Leaf Blade',
    'Vine Whip','Thorn Burst','Bloom Beam','Razor Frond','Root Slam',
    'Grass Knot','Solar Petal','Mega Drain','Leech Vine','Needle Rush',
    'Bramble Bash','Ivy Claw','Blossom Wave','Sap Bite','Timber Crash',
    'Verdant Pulse','Photosynth')
  rock = @('Rock Slide','Boulder Toss','Boulder Wreck','Crag Smash','Quake Stomp',
    'Sand Blast','Dust Storm','Iron Tail','Steel Claw','Magnet Pulse',
    'Crystal Beam','Gravel Shot','Tremor Wave','Pebble Rush','Fossil Crush',
    'Bedrock Bash','Spike Fang','Dune Slash','Geode Burst','Landslide')
  air = @('Thunder Bolt','Volt Tackle','Spark Bite','Shock Wave','Zap Cannon',
    'Discharge','Static Slam','Plasma Beam','Arc Slash','Lightning Dive',
    'Storm Gale','Thunderclap','Charge Beam','Voltage Rush','Electro Claw',
    'Ion Blast','Gust Cutter','Aero Slash','Storm Dive','Tempest Wave',
    'Wind Nip','Feather Storm','Cyclone Spin','Galvanize','Overcharge','Thunder Fang')
  shadow = @('Psy Beam','Mind Crush','Hypno Wave','Dream Eater','Confusion',
    'Mystic Blast','Aura Sphere','Telekinesis','Cosmic Pulse','Astral Slash',
    'Rune Burst','Mind Slap','Psywave','Mystic Nip','Warp Strike',
    'Grave Curse','Hex Bolt','Haunt Claw','Doom Beam','Spirit Drain',
    'Phantom Slash','Wail Wave','Tomb Smash','Soul Bite','Dread Pulse',
    'Shadow Sneak','Nightmare','Bone Rush','Wraith Fang','Reaper Slash')
  none = @('Power Slam','Body Rush','Guard Up','Swift Strike','Focus Chant','Recover')
}

# explicit utility / support moves (name -> spec)
$utility = @{
  'Rain Dance'  = @{ cat='buff'; stat='swift'; stages=1; desc='A ritual dance that quickens the body.' }
  'Aqua Ring'   = @{ cat='heal'; heal=0.35; desc='A veil of water that mends wounds.' }
  'Photosynth'  = @{ cat='heal'; heal=0.4;  desc='Draws on sunlight to restore health.' }
  'Galvanize'   = @{ cat='buff'; stat='power'; stages=1; desc='Charges the muscles with raw current.' }
  'Overcharge'  = @{ cat='buff'; stat='swift'; stages=1; desc='Floods the body with static speed.' }
  'Guard Up'    = @{ cat='buff'; stat='guard'; stages=1; desc='Braces for incoming blows.' }
  'Focus Chant' = @{ cat='buff'; stat='power'; stages=1; desc='A focusing chant that sharpens strikes.' }
  'Recover'     = @{ cat='heal'; heal=0.5;  desc='Concentrates to knit wounds closed.' }
}
$drain = @{ 'Mega Drain'=0.5; 'Leech Vine'=0.4; 'Dream Eater'=0.6; 'Spirit Drain'=0.5 }

function IdOf($name) {
  return ($name.ToLower() -replace "[^a-z0-9]+","_").Trim('_')
}

# power / accuracy ladder cycled across each pool for variety
$pw  = @(48, 60, 72, 55, 84, 66, 92, 58, 78, 70)
$acc = @(1.0, 0.97, 0.95, 1.0, 0.88, 0.95, 0.85, 1.0, 0.9, 0.95)

$raw = Get-Content $dataFile -Raw
$existing = @{}
foreach ($m in ($raw | ConvertFrom-Json)) { $existing[$m.id] = $true }

$entries = @()
$count = 0
foreach ($res in $pools.Keys) {
  $i = 0
  foreach ($name in $pools[$res]) {
    $id = IdOf $name
    $i++
    if ($existing.ContainsKey($id)) { continue }
    $existing[$id] = $true
    if ($utility.ContainsKey($name)) {
      $u = $utility[$name]
      if ($u.cat -eq 'heal') {
        $entries += ('  {{ "id": "{0}", "name": "{1}", "resonance": "{2}", "category": "heal", "power": 0, "accuracy": 1.0, "heal_pct": {3}, "description": "{4}" }}' -f $id,$name,$res,$u.heal,$u.desc)
      } else {
        $entries += ('  {{ "id": "{0}", "name": "{1}", "resonance": "{2}", "category": "buff", "power": 0, "accuracy": 1.0, "stat": "{3}", "stages": {4}, "description": "{5}" }}' -f $id,$name,$res,$u.stat,$u.stages,$u.desc)
      }
    } elseif ($drain.ContainsKey($name)) {
      $p = $pw[$i % $pw.Count]; $a = $acc[$i % $acc.Count]
      $entries += ('  {{ "id": "{0}", "name": "{1}", "resonance": "{2}", "category": "attack", "power": {3}, "accuracy": {4}, "lifesteal": {5}, "description": "Drains vitality from the foe." }}' -f $id,$name,$res,$p,$a,$drain[$name])
    } else {
      $p = $pw[$i % $pw.Count]; $a = $acc[$i % $acc.Count]
      $entries += ('  {{ "id": "{0}", "name": "{1}", "resonance": "{2}", "category": "attack", "power": {3}, "accuracy": {4}, "description": "A {2}-attuned strike." }}' -f $id,$name,$res,$p,$a)
    }
    $count++
  }
}

# merge before final ]
$orig = $raw.TrimEnd()
$orig = $orig.Substring(0, $orig.LastIndexOf(']')).TrimEnd().TrimEnd(',')
$merged = $orig + ",`n" + ($entries -join ",`n") + "`n]`n"
Set-Content -Path $dataFile -Value $merged -Encoding UTF8
Write-Output "Added $count new chimes -> $dataFile"
