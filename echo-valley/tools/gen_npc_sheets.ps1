# Generates player-resolution (16x32, hero-layout 64x128) NPC/trainer sheets by
# exact-palette recoloring the hero. Exact source->target color maps mean no
# anti-aliasing artifacts: every NPC matches the hero silhouette & resolution.
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$heroPath = Join-Path $root "assets\sprites\hero.png"
$outDir = Join-Path $root "assets\sprites\npc"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

# --- hero source palette (measured) ---
$HAIR_L = @(106,72,52);  $HAIR_D = @(67,46,39)
$SKIN_L = @(232,212,178); $SKIN_D = @(191,167,135)
$SHIRT_L = @(196,60,60); $SHIRT_M = @(136,46,46); $SHIRT_D = @(104,28,28)
$PANTS_D = @(42,42,52);  $PANTS_H = @(101,101,155)
$ACCENT  = @(85,134,185)

function Key($c) { "{0},{1},{2}" -f $c[0],$c[1],$c[2] }
function Shade($base, $f) {
  @([Math]::Min(255,[int]($base[0]*$f)), [Math]::Min(255,[int]($base[1]*$f)), [Math]::Min(255,[int]($base[2]*$f)))
}

# Build a source->target remap for a scheme.
# shirt/hair/pants are base colors; skin optional (null = keep hero skin).
function Build-Map($shirt, $hair, $pants, $skin, $accent) {
  $m = @{}
  $m[(Key $SHIRT_L)] = (Shade $shirt 1.15)
  $m[(Key $SHIRT_M)] = (Shade $shirt 0.78)
  $m[(Key $SHIRT_D)] = (Shade $shirt 0.50)
  $m[(Key $HAIR_L)]  = $hair
  $m[(Key $HAIR_D)]  = (Shade $hair 0.62)
  $m[(Key $PANTS_D)] = $pants
  $m[(Key $PANTS_H)] = (Shade $pants 1.7)
  if ($accent) { $m[(Key $ACCENT)] = $accent }
  if ($skin) {
    $m[(Key $SKIN_L)] = $skin
    $m[(Key $SKIN_D)] = (Shade $skin 0.82)
  }
  return $m
}

# name = shirt, hair, pants, skin(null=keep), accent(null=keep)
$schemes = @(
  @{ n="npc_aqua";   shirt=@(46,160,160);  hair=@(34,34,42);    pants=@(36,44,72);  skin=$null;          accent=@(230,210,120) }
  @{ n="npc_violet"; shirt=@(140,72,180);  hair=@(220,220,232); pants=@(52,44,66);  skin=$null;          accent=@(120,90,190) }
  @{ n="npc_forest"; shirt=@(70,150,70);   hair=@(120,80,40);   pants=@(112,92,60); skin=$null;          accent=@(200,180,90) }
  @{ n="npc_gold";   shirt=@(212,180,60);  hair=@(46,36,30);    pants=@(94,68,46);  skin=$null;          accent=@(150,110,40) }
  @{ n="npc_orange"; shirt=@(220,120,40);  hair=@(170,70,40);   pants=@(54,42,42);  skin=@(210,160,120); accent=@(240,200,120) }
  @{ n="npc_steel";  shirt=@(96,116,146);  hair=@(30,30,36);    pants=@(42,46,58);  skin=$null;          accent=@(190,200,215) }
  @{ n="npc_rose";   shirt=@(222,112,152); hair=@(228,196,112); pants=@(74,74,86);  skin=$null;          accent=@(250,220,150) }
  @{ n="npc_mint";   shirt=@(120,200,140); hair=@(40,120,120);  pants=@(42,72,52);  skin=$null;          accent=@(220,240,210) }
  @{ n="npc_sand";   shirt=@(200,170,120); hair=@(90,60,36);    pants=@(96,96,54);  skin=@(168,120,84);  accent=@(120,90,50) }
  @{ n="npc_night";  shirt=@(74,74,132);   hair=@(26,26,32);    pants=@(30,30,40);  skin=@(150,108,80);  accent=@(120,120,200) }
  # medical: white coat, pink hair, red accent
  @{ n="nurse";      shirt=@(238,238,244); hair=@(236,150,178); pants=@(220,220,228); skin=$null;        accent=@(210,60,60) }
)

$hero = [System.Drawing.Bitmap]::FromFile($heroPath)
$W = $hero.Width; $H = $hero.Height
foreach ($s in $schemes) {
  $map = Build-Map $s.shirt $s.hair $s.pants $s.skin $s.accent
  $out = New-Object System.Drawing.Bitmap($W, $H)
  for ($y=0; $y -lt $H; $y++) {
    for ($x=0; $x -lt $W; $x++) {
      $c = $hero.GetPixel($x,$y)
      if ($c.A -lt 20) { $out.SetPixel($x,$y,[System.Drawing.Color]::FromArgb(0,0,0,0)); continue }
      $k = "{0},{1},{2}" -f $c.R,$c.G,$c.B
      if ($map.ContainsKey($k)) {
        $t = $map[$k]
        $out.SetPixel($x,$y,[System.Drawing.Color]::FromArgb($c.A,$t[0],$t[1],$t[2]))
      } else {
        $out.SetPixel($x,$y,$c)
      }
    }
  }
  $dest = Join-Path $outDir ($s.n + ".png")
  $out.Save($dest, [System.Drawing.Imaging.ImageFormat]::Png)
  $out.Dispose()
  Write-Host "wrote $dest"
}
$hero.Dispose()
Write-Host "done"
