Add-Type -AssemblyName System.Drawing

$out = "c:\Users\smyde\memoir\echo-valley\assets\sprites"
New-Item -ItemType Directory -Force -Path $out | Out-Null

function C([int]$r,[int]$g,[int]$b,[int]$a=255) { return [System.Drawing.Color]::FromArgb($a,$r,$g,$b) }

# hair, skin, shirt, pants, shoe
$looks = @(
    @{ hair=@(90,60,40);   skin=@(244,200,160); shirt=@(210,70,60);   pants=@(40,55,90);  shoe=@(30,30,40) }
    @{ hair=@(30,30,35);   skin=@(220,175,140); shirt=@(70,120,200);  pants=@(80,85,95);  shoe=@(40,40,45) }
    @{ hair=@(225,190,90);  skin=@(248,208,170); shirt=@(80,170,110);  pants=@(120,85,55); shoe=@(60,40,30) }
    @{ hair=@(190,80,50);   skin=@(250,215,185); shirt=@(150,90,190);  pants=@(35,35,40);  shoe=@(25,25,30) }
    @{ hair=@(50,35,25);    skin=@(160,110,80);  shirt=@(235,200,90);  pants=@(40,120,120); shoe=@(30,50,50) }
    @{ hair=@(210,215,220); skin=@(244,200,160); shirt=@(60,160,160);  pants=@(120,50,60); shoe=@(45,25,30) }
)

$i = 0
foreach ($lk in $looks) {
    $bmp = New-Object System.Drawing.Bitmap 16, 32
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $g.Clear([System.Drawing.Color]::Transparent)

    $hair = C $lk.hair[0] $lk.hair[1] $lk.hair[2]
    $skin = C $lk.skin[0] $lk.skin[1] $lk.skin[2]
    $shirt = C $lk.shirt[0] $lk.shirt[1] $lk.shirt[2]
    $shirtD = C ([int]($lk.shirt[0]*0.7)) ([int]($lk.shirt[1]*0.7)) ([int]($lk.shirt[2]*0.7))
    $pants = C $lk.pants[0] $lk.pants[1] $lk.pants[2]
    $shoe = C $lk.shoe[0] $lk.shoe[1] $lk.shoe[2]
    $eye = C 30 25 30

    $bShadow = New-Object System.Drawing.SolidBrush (C 0 0 0 70)
    $bHair = New-Object System.Drawing.SolidBrush $hair
    $bSkin = New-Object System.Drawing.SolidBrush $skin
    $bShirt = New-Object System.Drawing.SolidBrush $shirt
    $bShirtD = New-Object System.Drawing.SolidBrush $shirtD
    $bPants = New-Object System.Drawing.SolidBrush $pants
    $bShoe = New-Object System.Drawing.SolidBrush $shoe
    $bEye = New-Object System.Drawing.SolidBrush $eye

    # ground shadow
    $g.FillEllipse($bShadow, 3, 28, 10, 3)
    # legs
    $g.FillRectangle($bPants, 5, 23, 2, 5)
    $g.FillRectangle($bPants, 9, 23, 2, 5)
    # shoes
    $g.FillRectangle($bShoe, 4, 28, 3, 2)
    $g.FillRectangle($bShoe, 9, 28, 3, 2)
    # body / shirt
    $g.FillRectangle($bShirt, 4, 15, 8, 9)
    $g.FillRectangle($bShirtD, 4, 22, 8, 2)
    # arms
    $g.FillRectangle($bShirt, 2, 16, 2, 6)
    $g.FillRectangle($bShirt, 12, 16, 2, 6)
    $g.FillRectangle($bSkin, 2, 21, 2, 2)
    $g.FillRectangle($bSkin, 12, 21, 2, 2)
    # head
    $g.FillRectangle($bSkin, 4, 7, 8, 8)
    # hair (top + sides)
    $g.FillRectangle($bHair, 3, 4, 10, 4)
    $g.FillRectangle($bHair, 3, 7, 2, 3)
    $g.FillRectangle($bHair, 11, 7, 2, 3)
    # bangs variation by index
    if ($i % 2 -eq 0) { $g.FillRectangle($bHair, 5, 7, 2, 1) } else { $g.FillRectangle($bHair, 9, 7, 2, 1) }
    # eyes
    $g.FillRectangle($bEye, 6, 10, 1, 2)
    $g.FillRectangle($bEye, 9, 10, 1, 2)

    $g.Dispose()
    $bmp.Save("$out\trainer_$i.png")
    $bmp.Dispose()
    Write-Output "generated trainer_$i.png"
    $i++
}
Write-Output "DONE"
