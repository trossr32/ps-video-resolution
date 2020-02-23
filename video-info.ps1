<#
.SYNOPSIS
Probe video files for their resolution and output results to host and optionally to log files

.DESCRIPTION
Uses ffmpeg (ffprobe) to interrogate video files and retrieve the resolution and file size.
Outputs the results to the host in 2 ordered lists, firstly by resolution and secondly by file name.

Results can also be output to log files if the user selects an output folder for logging when prompted.
A text log file is created that is a duplicate of the results written to the host.
A json file is created with an array representation of the VideoFile class.

.EXAMPLE
.\video-info.ps1

.NOTES
A check is made to see whether ffmpeg is installed in the environment PATH or in a C:\ffmpeg\bin directory.
If ffmpeg is not found in either location, the user will be prompted to download ffmpeg which will be saved in the 
C:\ffmpeg\bin directory.
#>

# declare some global variables
[String]$ffmpegLocalPath = "C:\ffmpeg\"
[String]$ffmpegLocalExe = "$ffmpegLocalPath\bin\ffmpeg.exe"
[String[]]$ResolutionHeader = @("","Ordered by resolution:","----------------------","","Resolution  Size (Mb)   File","----------  ---------   ----")
[String[]]$NameHeader = @("","Ordered by name:","----------------","","Resolution  Size (Mb)   File","----------  ---------   ----")

<# 
.Description
Checks whether ffmpeg is installed in the environment PATH or in a C:\ffmpeg\bin directory.
If ffmpeg is not found in either location, the user will be prompted to download ffmpeg which will be saved in the 
C:\ffmpeg\bin directory.
#>
Function Search-ffmpeg {
    if ($null -eq (Get-Command "ffmpeg.exe" -ErrorAction SilentlyContinue)) 
    { 
        if ([System.IO.File]::Exists($ffmpegLocalExe)) {
            return 'local'
        }

        $header = "ffmpeg is required and could not be found in your environment path. You can either opt to download it now or install yourself (via chocolatey: choco install fmmpeg)"
        $question = "Would you like to download ffmpeg now?"

        if (Get-YesNo-As-Bool($header, $question)) {
            Add-ffmpeg
        } else {
            exit
        }

        return 'local'
    }

    return 'path'
}

<# 
.Description
Download a built version of ffmpeg in aa zip archive for the appropriate CPU architecture.
Extract the archive, save ffmpeg files to directory C:\ffmpeg\bin, then clean up the archive.
#>
Function Add-ffmpeg {
    [string]$Architecture = ""
    
    $SaveFFMPEGTempLocation = $ffmpegLocalPath + "ffmpeg-update.zip"
    $ExtractFFMPEGTempLocation = $ffmpegLocalPath + "ffmpeg-update"

    if ([Environment]::Is64BitOperatingSystem) {
        $Architecture = '64'
    } else {
        $Architecture = '32'
    }

    Write-Host("Installing ffmpeg...")

    $Request = Invoke-WebRequest -Uri ("https://ffmpeg.zeranoe.com/builds/win" + $Architecture + "/static/?C=M&O=D")	

    $DownloadFFMPEGStatic = ("https://ffmpeg.zeranoe.com/builds/win" + $Architecture + "/static/" + (($Request.Links | Select-Object -ExpandProperty href | Where-Object Length -eq 29)[0]).ToString())

    $ExtractedFFMPEGTempLocation = $ffmpegLocalPath + "ffmpeg-update\" + ($DownloadFFMPEGStatic.Split('/')[-1].Replace('.zip', '')) + "\"

    #Check if the FFMPEG Path in C:\ exists if not create it
    Write-Host "Detecting if FFMPEG directory already exists"
    
    if (-Not (Test-Path $ffmpegLocalPath)) {
        Write-Host "Creating FFMPEG directory"

        New-Item -Path $ffmpegLocalPath -ItemType Directory | Out-Null
    } else {
        Get-ChildItem $ffmpegLocalPath | Remove-item -Recurse -Confirm:$false
    }

    # Download based on the channel input which ffmpeg download you want
    Write-Host "Downloading the selected FFMPEG application zip"

    Invoke-WebRequest $DownloadFFMPEGStatic -OutFile $SaveFFMPEGTempLocation

    # Unzip the downloaded archive to a temp location
    Write-Host "Expanding the downloaded FFMPEG application zip"
    
    Expand-Archive $SaveFFMPEGTempLocation -DestinationPath $ExtractFFMPEGTempLocation

    # Copy from temp location to $ffmpegLocalPath
    Write-Host "Retrieving and installing new FFMPEG files"
    
    Get-ChildItem $ExtractedFFMPEGTempLocation | Copy-Item -Destination $ffmpegLocalPath -Recurse -Force

    # Clean up of files that were used
    Write-Host "Clean up of the downloaded FFMPEG zip package"
    
    if (Test-Path ($SaveFFMPEGTempLocation)) {
        Remove-Item $SaveFFMPEGTempLocation -Confirm:$false
    }
    
    Write-Host "Clean up of the expanded FFMPEG zip package"
    
    if (Test-Path ($ExtractFFMPEGTempLocation)) {
        Remove-Item $ExtractFFMPEGTempLocation -Recurse -Confirm:$false
    }
}

<# 
.Description
Opens a directory browser dialog and returns the user selected path
#>
Function Get-Folder {
    [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.RootFolder = [System.Environment+specialfolder]::Desktop
    
    [void] $dialog.ShowDialog()
    
    return $dialog.SelectedPath
}

<# 
.Description
Prompts the user with a yes/no option and returns the result as a boolean where 'yes' equals true
#>
Function Get-YesNo-As-Bool($header, $question) {
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&yes"
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&no"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($header, $question, $options, 0) 

    switch ($result) {
        0 { return $true }
        1 { return $false }
    }
}

<# 
.Description
Asks the user if they want to create log files and instantiates an instance of the Logger class from the response
#>
Function Get-Logger() {
    $header = "Results will be written to this shell. If you'd like to create log files you will be prompted for the directory to save the files to."
    $question = "Would you also like to create a log file?"

    if (Get-YesNo-As-Bool($header, $question)) {
        $logDir = Get-Folder
        return [Logger]::new($true, $logDir)
    }
    
    return [Logger]::new($false)
}

<# 
.Description
Interrogates the logger class. If log files should be written, then create them according to the Logger config
#>
Function Write-Files($logger, $results) {
    # if we don't want to write logs then gtfo
    if (-Not $logger.WriteLogs) {
        return
    }

    # create the output directory
    $null = [System.IO.Directory]::CreateDirectory("$($logger.Dir)")

    # write the text log file
    Write-Host("")
    Write-Host("Writing log file : $($logger.LogFile())")

    $stream = [System.IO.StreamWriter]::new("$($logger.LogFile())")

    $ResolutionHeader | ForEach-Object{ $stream.WriteLine($_) }

    $results | Sort-Object -Property Width | ForEach-Object { $stream.WriteLine($_.ResultLine()) }

    $NameHeader | ForEach-Object{ $stream.WriteLine($_) }

    $results | Sort-Object -Property File | ForEach-Object { $stream.WriteLine($_.ResultLine()) }

    $stream.close()

    # write the json log file
    Write-Host("")
    Write-Host("Writing json file : $($logger.LogFile())")

    $results | ConvertTo-Json -Depth 4 | Out-File "$($logger.JsonFile())"
}

# Check to see if ffmpeg is installed and allow install if not found
$ffmpegLoc = Search-ffmpeg

# Prompt user to browse for the directory containing video files to be processed
Write-Host("")

$null = Read-Host "Specify the directory to scan, hit any key to open a directory browser"

$scanDir = Get-Folder

# Instantiate a Logger class and ask user if they want a log file written
[Logger]$logger = Get-Logger -as [Logger]

# Process the videos
Write-Host("")
Write-Host("Building filtered file list for the following file types: avi, divx, iso, m2ts, m4v, mkv, mp4, mpg, x265, wmv...")
Write-Host("")

$files = Get-ChildItem $scanDir -Recurse -Include *avi,*divx,*iso,*m2ts,*m4v,*mkv,*mp4,*mpg,*x265,*wmv  | Group-Object FullName | Select-Object Name

[System.Collections.ArrayList]$results = @()

for($i=0; $i -lt $files.Length; $i++) {
    # Show video processing progress
    Write-Progress -Activity 'Extracting video resolutions...' -Status "Processing file $($i + 1) of $($files.Length)" -PercentComplete ((($i + 1) / $files.Length) * 100)
    
    $cmd = '& ' + $(if ($ffmpegLoc -eq "local") { "$ffmpegLocalPath\bin\ffprobe.exe" } else { 'ffprobe' }) + ' -v quiet -select_streams v:0 -show_entries "stream=width,height : format=size" -of json "$($files[$i].Name)"'

    $json = Invoke-Expression $cmd

    [void]$results.Add([VideoInfo]::new("$json", $files[$i].Name))
}

# Write log files if specified
Write-Files -logger $logger -results $results

# Write results to the host
Write-Host("")
Write-Host("Finished! Here are the results:")

$ResolutionHeader | ForEach-Object { Write-Host($_) }

$results | Sort-Object -Property Width | ForEach-Object { Write-Host($_.ResultLine()) }

$NameHeader | ForEach-Object { Write-Host($_) }

$results | Sort-Object -Property File | ForEach-Object { Write-Host($_.ResultLine()) }

Write-Host("");

<#
.Description
Logger class containing config for writing log files

.Example
[Logger]::new({switch to specify whether logs are to be written}, {log file output directory})
[Logger]::new({switch to specify whether logs are to be written})
#>
class Logger {
    [bool]$WriteLogs
    [string]$Dir
    [string]$RunDateTime

    [string]BaseFileName() {
        return "video-info.$($this.RunDateTime)"
    }

    [string]LogFile() { return "$($this.Dir)\$($this.BaseFileName()).log" }
    [string]JsonFile() { return "$($this.Dir)\$($this.BaseFileName()).json" }

    Logger([bool]$writeLogs) {
        $this.WriteLogs = $writeLogs
    }

    Logger([bool]$writeLogs, [string]$dir) {
        $this.WriteLogs = $writeLogs

        $d = Get-Date
        $this.RunDateTime = $d.ToString("yyyyMMdd_HHmmss")

        $this.Dir = "$dir/video-info-logs.$($this.RunDateTime)"
    }
}

<#
.Description
VideoInfo class containing resolution and file size information retrieved from ffprobe

.Example
[VideoInfo]::new({json string returned from ffprobe}, {file path and name})
#>
class VideoInfo {
    [string]$File
    [int]$Width
    [int]$Height
    [int]$SizeInBytes
    [double]$SizeInMb
    [double]$SizeInGb

    [string]Resolution() {
        return "$($this.Width)x$($this.Height)"
    }

    [string]ResultLine() {
        $res = ("$($this.Resolution())").PadRight(10)
        $mb = ("$($this.SizeInMb)Mb").PadRight(10)

        return "$res  $mb  $($this.File)"
    }

    VideoInfo([string]$json, [string]$file) {
        $info = ConvertFrom-Json $json

        $this.File = $file
        $this.Width = $info.streams[0].width -as [int]
        $this.Height = $info.streams[0].height -as [int]
        $this.SizeInBytes = $info.format.size -as [int]

        $this.SizeInMb = [System.Math]::Round(($info.format.size -as [double]) / 1024 / 1024, 2)
        $this.SizeInGb = [System.Math]::Round(($info.format.size -as [double]) / 1024 / 1024 / 1000, 2)
    }
}