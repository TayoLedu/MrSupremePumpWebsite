# Prepares the website image assets from the original photo sources.
Add-Type -AssemblyName System.Drawing

$root = "c:\Users\Yada\Mr Supreme\mr-supreme-pump-website"
$src  = Join-Path $root "source-media"
$out  = Join-Path $root "assets\images"
New-Item -ItemType Directory -Force -Path $out | Out-Null

# --- helpers -------------------------------------------------------------

function Get-JpegEncoder {
    [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
        Where-Object { $_.MimeType -eq 'image/jpeg' }
}

function Get-TrimBounds {
    <#
      Returns the rectangle left after removing near-black letterbox bars.
      Works by marking every row dark/not-dark and keeping the longest
      unbroken run of not-dark rows, so stray bright pixels inside a bar
      (a phone's home-indicator line, for instance) do not defeat it.
    #>
    param([System.Drawing.Bitmap]$bmp, [int]$Threshold = 26)

    $w = $bmp.Width; $h = $bmp.Height
    $xs = @(); for ($i = 0; $i -lt 9; $i++) { $xs += [int](($i + 1) * $w / 10) }

    # A row counts as "light" only if a decent share of samples are light,
    # which keeps a thin white line from rescuing an otherwise black row.
    $light = New-Object bool[] $h
    for ($y = 0; $y -lt $h; $y++) {
        $n = 0
        foreach ($x in $xs) {
            $p = $bmp.GetPixel($x, $y)
            if (($p.R + $p.G + $p.B) / 3 -gt $Threshold) { $n++ }
        }
        $light[$y] = ($n -ge 3)
    }

    $bestStart = 0; $bestLen = 0; $start = -1
    for ($y = 0; $y -lt $h; $y++) {
        if ($light[$y]) {
            if ($start -lt 0) { $start = $y }
            $len = $y - $start + 1
            if ($len -gt $bestLen) { $bestLen = $len; $bestStart = $start }
        } else {
            $start = -1
        }
    }

    if ($bestLen -lt [int]($h * 0.25)) {
        # Nothing convincing found; leave the image alone.
        return New-Object System.Drawing.Rectangle 0, 0, $w, $h
    }
    return New-Object System.Drawing.Rectangle 0, $bestStart, $w, $bestLen
}

function Get-GutterRange {
    <#
      Side-by-side collages are joined by a thin light-coloured gutter that is
      not always at the exact midpoint. Finds it by looking for the longest run
      of near-uniform light columns in the middle third of the image, so each
      panel can be cut at the real seam instead of at W/2.
      Returns @(startX, endXInclusive), or $null if there is no clear gutter.
    #>
    param([System.Drawing.Bitmap]$bmp, [int]$Light = 232)

    $w = $bmp.Width; $h = $bmp.Height
    $ys = @(); for ($i = 0; $i -lt 20; $i++) { $ys += [int](($i + 0.5) * $h / 20) }

    $from = [int]($w * 0.35); $to = [int]($w * 0.65)
    $isGutter = @{}
    for ($x = $from; $x -le $to; $x++) {
        $n = 0
        foreach ($y in $ys) {
            $p = $bmp.GetPixel($x, $y)
            if ($p.R -ge $Light -and $p.G -ge $Light -and $p.B -ge $Light) { $n++ }
        }
        $isGutter[$x] = ($n -ge 18)   # 18 of 20 sampled rows
    }

    $bestStart = -1; $bestLen = 0; $start = -1
    for ($x = $from; $x -le $to; $x++) {
        if ($isGutter[$x]) {
            if ($start -lt 0) { $start = $x }
            $len = $x - $start + 1
            if ($len -gt $bestLen) { $bestLen = $len; $bestStart = $start }
        } else {
            $start = -1
        }
    }

    if ($bestLen -lt 2) { return $null }
    return @($bestStart, ($bestStart + $bestLen - 1))
}

function Export-Asset {
    <#
      Loads a source image, optionally takes a horizontal slice of it
      (for side-by-side collages), strips black letterbox bars, scales it
      down and writes a JPEG.
    #>
    param(
        [string]$Source,
        [string]$Name,
        [ValidateSet('all', 'left', 'right')][string]$Half = 'all',
        [int]$MaxHeight = 1200,
        [int]$MaxWidth = 2000,
        [switch]$NoTrim,
        [int]$Quality = 82,
        # Optional fractional crop applied first: left, top, right, bottom as
        # fractions of the source, e.g. @(0.1, 0.19, 0.89, 0.67).
        [double[]]$Crop
    )

    $loaded = [System.Drawing.Bitmap]::FromFile($Source)
    if ($Crop) {
        $cx = [int]($loaded.Width * $Crop[0]); $cy = [int]($loaded.Height * $Crop[1])
        $cw = [int]($loaded.Width * $Crop[2]) - $cx; $ch = [int]($loaded.Height * $Crop[3]) - $cy
        $r = New-Object System.Drawing.Rectangle $cx, $cy, $cw, $ch
        $src = $loaded.Clone($r, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        $loaded.Dispose()
    } else {
        $src = $loaded
    }
    try {
        # 1. slice, cutting at the real seam between the two panels
        if ($Half -ne 'all') {
            $gutter = Get-GutterRange $src
            if ($gutter) {
                $leftEnd = $gutter[0] - 1
                $rightStart = $gutter[1] + 1
            } else {
                Write-Warning "No gutter found in $(Split-Path $Source -Leaf); falling back to the midpoint."
                $leftEnd = [int]($src.Width / 2) - 1
                $rightStart = [int]($src.Width / 2)
            }
        }
        switch ($Half) {
            'left'  { $rect = New-Object System.Drawing.Rectangle 0, 0, ($leftEnd + 1), $src.Height }
            'right' { $rect = New-Object System.Drawing.Rectangle $rightStart, 0, ($src.Width - $rightStart), $src.Height }
            default { $rect = New-Object System.Drawing.Rectangle 0, 0, $src.Width, $src.Height }
        }
        $slice = $src.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)

        # 2. strip letterbox bars
        if ($NoTrim) {
            $body = $slice
        } else {
            $b = Get-TrimBounds $slice
            if ($b.Height -lt $slice.Height) {
                $body = $slice.Clone($b, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
                $slice.Dispose()
            } else {
                $body = $slice
            }
        }

        # 3. scale down
        $scale = [Math]::Min(1.0, [Math]::Min($MaxHeight / $body.Height, $MaxWidth / $body.Width))
        $tw = [int][Math]::Round($body.Width * $scale)
        $th = [int][Math]::Round($body.Height * $scale)

        $dst = New-Object System.Drawing.Bitmap $tw, $th
        $g = [System.Drawing.Graphics]::FromImage($dst)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.DrawImage($body, (New-Object System.Drawing.Rectangle 0, 0, $tw, $th))
        $g.Dispose()

        # 4. write
        $ps = New-Object System.Drawing.Imaging.EncoderParameters 1
        $ps.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), $Quality
        $path = Join-Path $out $Name
        $dst.Save($path, (Get-JpegEncoder), $ps)

        "{0,-26} {1,4} x {2,4}  ({3:N0} KB)" -f $Name, $tw, $th, ((Get-Item $path).Length / 1KB)

        $dst.Dispose(); $body.Dispose()
    } finally {
        $src.Dispose()
    }
}

# --- brand ---------------------------------------------------------------

Export-Asset -Source "$src\hero-banner-original.jpeg" `
             -Name 'hero-banner.jpg' -NoTrim -MaxWidth 1600 -MaxHeight 1600 -Quality 86
Export-Asset -Source "$src\logo-original.jpeg" `
             -Name 'logo.jpg' -NoTrim -MaxHeight 240 -MaxWidth 400 -Quality 90
Export-Asset -Source "$src\coach-portrait-original.jpeg" `
             -Name 'coach-portrait.jpg' -MaxHeight 1200 -Quality 86
# The original is the QR card on a decorative emoji background; crop to the
# white card alone so the code is still scannable at the size it is shown.
Export-Asset -Source "$src\Instagram.jpg" -Crop @(0.108, 0.196, 0.892, 0.668) `
             -Name 'instagram-qr.jpg' -NoTrim -MaxHeight 600 -MaxWidth 600 -Quality 90

# --- transformations -----------------------------------------------------
# The collages are edge-to-edge photos, so they get no letterbox trim; each is
# cut at the light gutter between the two panels rather than at the midpoint.
#
# Dayo's collage is after | before (left is the wedding photo). Confirmed
# against DayoTransformation.jpg, where the same side-profile shot is the before.
Export-Asset -Source "$src\DayoTransformation2.jpeg" -Half right -Name 'dayo-before.jpg' -NoTrim
Export-Asset -Source "$src\DayoTransformation2.jpeg" -Half left  -Name 'dayo-after.jpg'  -NoTrim

# Glen's collage is before | after.
Export-Asset -Source "$src\GlenTransformation2.jpeg" -Half left  -Name 'glen-before.jpg' -NoTrim
Export-Asset -Source "$src\GlenTransformation2.jpeg" -Half right -Name 'glen-after.jpg'  -NoTrim

# Natalie: full-resolution originals, better than splitting her collage.
Export-Asset -Source "$src\natalie-before-original.jpeg" -Name 'natalie-before.jpg'
Export-Asset -Source "$src\natalie-after-original.jpeg"  -Name 'natalie-after.jpg'
