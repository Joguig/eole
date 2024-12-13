function Get-ScreenCapture
{
    param(    
    [Switch]$OfWindow        
    )

    begin {
        Add-Type -AssemblyName System.Drawing
        $jpegCodec = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | 
            Where-Object { $_.FormatDescription -eq "JPEG" }
    }
    process {
        Start-Sleep -Milliseconds 250
        if ($OfWindow) {            
            [Windows.Forms.Sendkeys]::SendWait("%{PrtSc}")
        } else {
            [Windows.Forms.Sendkeys]::SendWait("{PrtSc}")
        }
        Start-Sleep -Milliseconds 250
        $bitmap = [Windows.Forms.Clipboard]::GetImage()
        $ep = New-Object Drawing.Imaging.EncoderParameters  
        $ep.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality, [long]100)  
        $screenCapturePathBase = "$pwd\ScreenCapture"
        $c = 0
        while (Test-Path "${screenCapturePathBase}${c}.jpg")
        {
            $c++
        }
        $bitmap.Save("${screenCapturePathBase}${c}.jpg", $jpegCodec, $ep)
    }
}

function screenshot
{
    param(    
    [String]$path
    )


    begin {
        [Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
    }
    
    process {
        $width = 0;
        $height = 0;
        $workingAreaX = 0;
        $workingAreaY = 0;

        $screen = [System.Windows.Forms.Screen]::AllScreens;

        foreach ($item in $screen)
        {
            if($workingAreaX -gt $item.WorkingArea.X)
            {
                $workingAreaX = $item.WorkingArea.X;
            }

            if($workingAreaY -gt $item.WorkingArea.Y)
            {
                $workingAreaY = $item.WorkingArea.Y;
            }

            $width = $width + $item.Bounds.Width;

            if($item.Bounds.Height -gt $height)
            {
                $height = $item.Bounds.Height;
            }
        }

        $bounds = [Drawing.Rectangle]::FromLTRB($workingAreaX, $workingAreaY, $width, $height); 
        $bmp = New-Object Drawing.Bitmap $width, $height;
        $graphics = [Drawing.Graphics]::FromImage($bmp);

        $graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size);

        $bmp.Save($path);

        $graphics.Dispose();
        $bmp.Dispose();
    }
}