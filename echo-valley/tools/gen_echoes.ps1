Add-Type -AssemblyName System.Drawing

$out = "c:\Users\smyde\memoir\echo-valley\assets\echoes"
New-Item -ItemType Directory -Force -Path $out | Out-Null

function New-Color([int]$r,[int]$g,[int]$b,[int]$a=255) {
    return [System.Drawing.Color]::FromArgb($a,$r,$g,$b)
}

# Each creature: id, body color, belly color, dark outline, element feature
$creatures = @(
    @{ id="emberkit";  body=@(231,111,81);  belly=@(255,209,148); eye=@(45,32,40);  elem="fire" }
    @{ id="tideling";  body=@(76,201,240);  belly=@(202,240,248); eye=@(29,53,87);  elem="water" }
    @{ id="mossling";  body=@(82,183,136);  belly=@(216,243,220); eye=@(27,38,44);  elem="grass" }
    @{ id="pebblit";   body=@(141,153,174); belly=@(224,225,221); eye=@(43,45,66);  elem="rock" }
    @{ id="zephyr";    body=@(168,218,220); belly=@(241,250,238); eye=@(69,123,157); elem="air" }
    @{ id="duskling";  body=@(123,44,191);  belly=@(199,125,255); eye=@(255,209,102); elem="shadow" }
    # evolutions
    @{ id="flarefox";  body=@(244,162,97);  belly=@(255,224,178); eye=@(45,32,40);  elem="fire" }
    @{ id="marowl";    body=@(72,149,239);  belly=@(202,240,248); eye=@(29,53,87);  elem="water" }
    @{ id="bramblor";  body=@(64,145,108);  belly=@(200,235,205); eye=@(27,38,44);  elem="grass" }
    @{ id="craggan";   body=@(120,110,100); belly=@(200,190,175); eye=@(43,45,66);  elem="rock" }
    @{ id="gustrel";   body=@(132,196,224); belly=@(235,248,255); eye=@(52,101,164); elem="air" }
    @{ id="nocturn";   body=@(90,50,140);   belly=@(180,140,230); eye=@(255,209,102); elem="shadow" }
    # route 2 wild species
    @{ id="dewling";   body=@(100,190,210); belly=@(214,244,250); eye=@(29,63,97);  elem="water" }
    @{ id="fernkit";   body=@(96,172,110);  belly=@(214,240,214); eye=@(27,48,34);  elem="grass" }
    @{ id="cindboth";  body=@(214,96,72);   belly=@(255,200,150); eye=@(45,32,40);  elem="fire" }
)

$S = 64
foreach ($c in $creatures) {
    $bmp = New-Object System.Drawing.Bitmap $S, $S
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $g.Clear([System.Drawing.Color]::Transparent)

    $body = New-Color $c.body[0] $c.body[1] $c.body[2]
    $belly = New-Color $c.belly[0] $c.belly[1] $c.belly[2]
    $eye = New-Color $c.eye[0] $c.eye[1] $c.eye[2]
    $dark = New-Color ([int]($c.body[0]*0.55)) ([int]($c.body[1]*0.55)) ([int]($c.body[2]*0.55))
    $outline = New-Color 26 22 28
    $white = New-Color 255 255 255

    $brBody = New-Object System.Drawing.SolidBrush $body
    $brBelly = New-Object System.Drawing.SolidBrush $belly
    $brEye = New-Object System.Drawing.SolidBrush $eye
    $brDark = New-Object System.Drawing.SolidBrush $dark
    $brOut = New-Object System.Drawing.SolidBrush $outline
    $brWhite = New-Object System.Drawing.SolidBrush $white

    # shadow on ground
    $brShadow = New-Object System.Drawing.SolidBrush (New-Color 0 0 0 60)
    $g.FillEllipse($brShadow, 14, 52, 36, 8)

    # feet
    $g.FillEllipse($brDark, 20, 46, 10, 8)
    $g.FillEllipse($brDark, 34, 46, 10, 8)

    # outline body (slightly larger, dark)
    $g.FillEllipse($brOut, 13, 13, 38, 40)
    # body
    $g.FillEllipse($brBody, 15, 15, 34, 36)
    # belly
    $g.FillEllipse($brBelly, 23, 30, 18, 18)

    # element feature on head/back
    switch ($c.elem) {
        "fire" {
            $flame = New-Color 255 190 60
            $flame2 = New-Color 255 120 40
            $brF = New-Object System.Drawing.SolidBrush $flame
            $brF2 = New-Object System.Drawing.SolidBrush $flame2
            $pts = @(
                (New-Object System.Drawing.Point 32,2),
                (New-Object System.Drawing.Point 26,16),
                (New-Object System.Drawing.Point 38,16)
            )
            $g.FillPolygon($brF2, $pts)
            $pts2 = @(
                (New-Object System.Drawing.Point 32,6),
                (New-Object System.Drawing.Point 29,15),
                (New-Object System.Drawing.Point 35,15)
            )
            $g.FillPolygon($brF, $pts2)
            # ears
            $g.FillEllipse($brBody, 16, 12, 10, 12)
            $g.FillEllipse($brBody, 38, 12, 10, 12)
        }
        "water" {
            $fin = New-Color 173 232 244
            $brFin = New-Object System.Drawing.SolidBrush $fin
            $pts = @(
                (New-Object System.Drawing.Point 32,2),
                (New-Object System.Drawing.Point 27,14),
                (New-Object System.Drawing.Point 37,14)
            )
            $g.FillPolygon($brFin, $pts)
            # side fins
            $g.FillEllipse($brFin, 10, 28, 10, 8)
            $g.FillEllipse($brFin, 44, 28, 10, 8)
        }
        "grass" {
            $leaf = New-Color 116 198 157
            $stem = New-Color 90 140 80
            $brLeaf = New-Object System.Drawing.SolidBrush $leaf
            $brStem = New-Object System.Drawing.SolidBrush $stem
            $g.FillRectangle($brStem, 31, 4, 2, 12)
            $g.FillEllipse($brLeaf, 24, 2, 10, 8)
            $g.FillEllipse($brLeaf, 32, 4, 10, 8)
        }
        "rock" {
            $g.FillPolygon($brDark, @(
                (New-Object System.Drawing.Point 20,14),
                (New-Object System.Drawing.Point 26,4),
                (New-Object System.Drawing.Point 30,14)))
            $g.FillPolygon($brDark, @(
                (New-Object System.Drawing.Point 34,14),
                (New-Object System.Drawing.Point 40,6),
                (New-Object System.Drawing.Point 44,14)))
        }
        "air" {
            $wing = New-Color 241 250 238
            $brW = New-Object System.Drawing.SolidBrush $wing
            $g.FillEllipse($brW, 6, 22, 12, 10)
            $g.FillEllipse($brW, 46, 22, 12, 10)
        }
        "shadow" {
            $brH = New-Object System.Drawing.SolidBrush $dark
            $g.FillPolygon($brH, @(
                (New-Object System.Drawing.Point 18,16),
                (New-Object System.Drawing.Point 14,2),
                (New-Object System.Drawing.Point 24,14)))
            $g.FillPolygon($brH, @(
                (New-Object System.Drawing.Point 46,16),
                (New-Object System.Drawing.Point 50,2),
                (New-Object System.Drawing.Point 40,14)))
        }
    }

    # eyes
    $g.FillEllipse($brWhite, 23, 26, 8, 9)
    $g.FillEllipse($brWhite, 33, 26, 8, 9)
    $g.FillEllipse($brEye, 25, 28, 4, 5)
    $g.FillEllipse($brEye, 35, 28, 4, 5)
    # eye highlights
    $g.FillRectangle($brWhite, 26, 29, 1, 1)
    $g.FillRectangle($brWhite, 36, 29, 1, 1)

    # cheeks / mouth
    $g.FillEllipse($brDark, 31, 37, 3, 2)

    $g.Dispose()
    $bmp.Save("$out\$($c.id).png")
    $bmp.Dispose()
    Write-Output "generated $($c.id).png"
}

# --- Echo Charm (the capture device) ---
$cs = 32
$charm = New-Object System.Drawing.Bitmap $cs, $cs
$cg = [System.Drawing.Graphics]::FromImage($charm)
$cg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$cg.Clear([System.Drawing.Color]::Transparent)
$outline = New-Color 26 22 28
$brOut = New-Object System.Drawing.SolidBrush $outline
# ball outline
$cg.FillEllipse($brOut, 4, 4, 24, 24)
# top half (warm)
$topClip = New-Object System.Drawing.Region (New-Object System.Drawing.Rectangle 5,5,22,11)
$cg.Clip = $topClip
$cg.FillEllipse((New-Object System.Drawing.SolidBrush (New-Color 231 111 81)), 5, 5, 22, 22)
$cg.ResetClip()
# bottom half (cream)
$botClip = New-Object System.Drawing.Region (New-Object System.Drawing.Rectangle 5,16,22,11)
$cg.Clip = $botClip
$cg.FillEllipse((New-Object System.Drawing.SolidBrush (New-Color 245 240 225)), 5, 5, 22, 22)
$cg.ResetClip()
# center band + button
$cg.FillRectangle($brOut, 5, 15, 22, 2)
$cg.FillEllipse($brOut, 12, 12, 8, 8)
$cg.FillEllipse((New-Object System.Drawing.SolidBrush (New-Color 255 255 255)), 14, 14, 4, 4)
# shine
$cg.FillEllipse((New-Object System.Drawing.SolidBrush (New-Color 255 255 255 160)), 9, 8, 4, 4)
$cg.Dispose()
$charm.Save("$out\echo_charm.png")
$charm.Dispose()
Write-Output "generated echo_charm.png"

Write-Output "DONE"
