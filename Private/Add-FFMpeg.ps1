<# 
.Description
Download a built version of ffmpeg in aa zip archive for the appropriate CPU architecture.
Extract the archive, save ffmpeg files to directory C:\ffmpeg\bin, then clean up the archive.
.Parameter quiet 
Silence verbose writing to host
#>
Function Add-FFmpeg($quiet) {
    [string]$Architecture = ""
    
    $SaveFFMPEGTempLocation = $ffmpegLocalPath + "ffmpeg-update.zip"
    $ExtractFFMPEGTempLocation = $ffmpegLocalPath + "ffmpeg-update"

    if ([Environment]::Is64BitOperatingSystem) {
        $Architecture = '64'
    } else {
        $Architecture = '32'
    }
    
    if (-Not $quiet) {
        Write-Host("Installing ffmpeg...")
    }

    $Request = Invoke-WebRequest -Uri ("https://ffmpeg.zeranoe.com/builds/win" + $Architecture + "/static/?C=M&O=D")	

    $DownloadFFMPEGStatic = ("https://ffmpeg.zeranoe.com/builds/win" + $Architecture + "/static/" + (($Request.Links | Select-Object -ExpandProperty href | Where-Object Length -eq 29)[0]).ToString())

    $ExtractedFFMPEGTempLocation = $ffmpegLocalPath + "ffmpeg-update\" + ($DownloadFFMPEGStatic.Split('/')[-1].Replace('.zip', '')) + "\"

    #Check if the FFMPEG Path in C:\ exists if not create it
    if (-Not $quiet) {
        Write-Host "Detecting if FFMPEG directory already exists"
    }
    
    if (-Not (Test-Path $ffmpegLocalPath)) {
        if (-Not $quiet) {
            Write-Host "Creating FFMPEG directory"
        }

        New-Item -Path $ffmpegLocalPath -ItemType Directory | Out-Null
    } else {
        Get-ChildItem $ffmpegLocalPath | Remove-item -Recurse -Confirm:$false
    }

    # Download based on the channel input which ffmpeg download you want
    if (-Not $quiet) {
        Write-Host "Downloading the selected FFMPEG application zip"
    }

    Invoke-WebRequest $DownloadFFMPEGStatic -OutFile $SaveFFMPEGTempLocation

    # Unzip the downloaded archive to a temp location
    if (-Not $quiet) {
        Write-Host "Expanding the downloaded FFMPEG application zip"
    }
    
    Expand-Archive $SaveFFMPEGTempLocation -DestinationPath $ExtractFFMPEGTempLocation

    # Copy from temp location to $ffmpegLocalPath
    if (-Not $quiet) {
        Write-Host "Retrieving and installing new FFMPEG files"
    }
    
    Get-ChildItem $ExtractedFFMPEGTempLocation | Copy-Item -Destination $ffmpegLocalPath -Recurse -Force

    # Clean up of files that were used
    if (-Not $quiet) {
        Write-Host "Clean up of the downloaded FFMPEG zip package"
    }
    
    if (Test-Path ($SaveFFMPEGTempLocation)) {
        Remove-Item $SaveFFMPEGTempLocation -Confirm:$false
    }
    
    if (-Not $quiet) {
        Write-Host "Clean up of the expanded FFMPEG zip package"
    }
    
    if (Test-Path ($ExtractFFMPEGTempLocation)) {
        Remove-Item $ExtractFFMPEGTempLocation -Recurse -Confirm:$false
    }
}