# Validates echoes.json + chimes.json + encounters.json: parse, counts, dup ids,
# and cross-references (learnset chimes exist, evolve_to targets exist,
# encounter ids exist, sprite files present).
$root = "c:\Users\smyde\memoir\echo-valley"
$echoesFile = Join-Path $root "data\echoes.json"
$chimesFile = Join-Path $root "data\chimes.json"
$encFile    = Join-Path $root "data\encounters.json"
$echoesDir  = Join-Path $root "assets\echoes"

$errors = 0
function Fail($msg) { Write-Output ("ERROR: " + $msg); $script:errors++ }

$echoes = Get-Content $echoesFile -Raw | ConvertFrom-Json
$chimes = Get-Content $chimesFile -Raw | ConvertFrom-Json
$enc    = Get-Content $encFile -Raw | ConvertFrom-Json

Write-Output ("echoes: " + $echoes.Count + "   chimes: " + $chimes.Count)

$chimeIds = @{}
foreach ($c in $chimes) {
  if ($chimeIds.ContainsKey($c.id)) { Fail ("dup chime id: " + $c.id) }
  $chimeIds[$c.id] = $true
}

$echoIds = @{}
foreach ($e in $echoes) {
  if ($echoIds.ContainsKey($e.id)) { Fail ("dup echo id: " + $e.id) }
  $echoIds[$e.id] = $true
}

foreach ($e in $echoes) {
  # sprite file present
  $spr = ($e.sprite -replace "res://","") -replace "/","\"
  $sprPath = Join-Path $root $spr
  if (-not (Test-Path $sprPath)) { Fail ("missing sprite for " + $e.id + ": " + $e.sprite) }
  # learnset chimes exist
  if ($e.learnset) {
    foreach ($l in $e.learnset) {
      if (-not $chimeIds.ContainsKey($l.chime)) { Fail ($e.id + " references missing chime: " + $l.chime) }
    }
  }
  # evolve target exists
  if ($e.evolve_to -and $e.evolve_to -ne "") {
    if (-not $echoIds.ContainsKey($e.evolve_to)) { Fail ($e.id + " evolves to missing id: " + $e.evolve_to) }
  }
}

# encounter ids exist
foreach ($mapKey in $enc.PSObject.Properties.Name) {
  $tbl = $enc.$mapKey
  foreach ($row in $tbl.encounters) {
    if (-not $echoIds.ContainsKey($row.id)) { Fail ("encounter table '" + $mapKey + "' references missing echo: " + $row.id) }
  }
}

if ($errors -eq 0) { Write-Output "VALIDATION OK" } else { Write-Output ("VALIDATION FAILED: " + $errors + " error(s)") }
