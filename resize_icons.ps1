Add-Type -AssemblyName System.Drawing

$srcPath = 'c:\controle_pharma\icon.png'
$src = [System.Drawing.Image]::FromFile($srcPath)

$sizes = @{
    'mipmap-mdpi' = 48
    'mipmap-hdpi' = 72
    'mipmap-xhdpi' = 96
    'mipmap-xxhdpi' = 144
    'mipmap-xxxhdpi' = 192
}

foreach ($entry in $sizes.GetEnumerator()) {
    $dir = "c:\controle_pharma\android\app\src\main\res\$($entry.Key)"
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force }
    $outPath = Join-Path $dir 'ic_launcher.png'
    $size = $entry.Value
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.DrawImage($src, 0, 0, $size, $size)
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "Generated: $outPath - ${size}x${size}"
}
$src.Dispose()
Write-Host 'All Android icons generated!'
