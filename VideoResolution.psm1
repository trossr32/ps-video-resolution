# declare some global variables
[String]$ffmpegLocalPath = "C:\ffmpeg\"
[String]$ffmpegLocalExe = "$ffmpegLocalPath\bin\ffmpeg.exe"
[String[]]$ResolutionHeader = @("","Ordered by resolution:","----------------------")
[String[]]$NameHeader = @("","Ordered by name:","----------------")
[String[]]$ResultsHeader = @("","Resolution  Size (Mb)   File","----------  ---------   ----")

function Get-VideoResolution {
    <#
    .SYNOPSIS
    Probe video files for their resolution and output results to host and optionally to log files

    .DESCRIPTION
    Uses ffmpeg (ffprobe) to interrogate video files and retrieve the resolution and file size.

    Can be run against: 
    
    > all files in an input directory supplied as an InputDirectory parameter or from a user prompt.
    > a file using the File parameter. This can be a file name in the current directory, a relative path, 
      a full path, or a file name used in conjunction with the InputDirectory parameter.
    > a collection of files piped into the module (note: this expects correct paths and won't use the InputDirectory 
      parameter).
    
    Outputs the results to the host in 2 ordered lists, firstly by resolution and secondly by file name.

    Results can also be output to log files if the user selects an output folder for logging when prompted
    or supplies a LogDirectory parameter.
    A text log file is created that is a duplicate of the results written to the host.
    A json file is created with an array representation of the VideoFile class.

    .PARAMETER InputDirectory
    Optional. If supplied this is the path used to find video files to process. If not supplied, the user will be 
    prompted to browse for and select the path to use. If used in conjunction with the File parameter then this path
    will be joined to the file provided.
    
    .PARAMETER File
    Optional. If supplied this file will be processed. Must be a file in the current directory, a relative path, a full
    path, or a filename used in conjunction with the InputDirectory parameter.
    
    .PARAMETER Files
    Optional. Accepted as piped input. If supplied all files in this string array will be processed. Each file must be 
    in the current directory, a relative path or a full path. Cannot be used in conjunction with the InputDirectory parameter.
    
    .PARAMETER LogDirectory
    Optional. If supplied this is the path used to write text and json log files. If not supplied, the user will be 
    prompted firstly whether log files should be created, and if so then prompted to browse for and select the path to use.

    .PARAMETER NoLogs
    Optional. If supplied no log files will be created. Overrides the LogDirectory parameter.
    
    .PARAMETER Quiet
    Optional. Removes verbose host output.
    
    .EXAMPLE
    All files in directory request which will prompt the user to select an input directory, whether log files should be created, and a log file directory.
    PS C:\> Get-VideoResolution
    
    .EXAMPLE
    All files in the supplied input directory, writing logs to the supplied log file directory and no verbose host output.
    PS C:\> Get-VideoResolution -InputDirectory "C:\Videos" -LogDirectory "C:\Videos\Logs" -Quiet
    
    .EXAMPLE
    Process the supplied file with no logging
    PS C:\> Get-VideoResolution -File "C:\Videos\ExampleFile.mkv" -NoLogs
    
    .EXAMPLE
    Process the supplied file using the current directory and prompt for whether log files should be created and the log file directory
    PS C:\Videos\> Get-VideoResolution -File "ExampleFile.mkv"
    
    .EXAMPLE
    Process the piped files array, writing logs to the supplied log file directory and no verbose host output.
    PS C:\> "C:\Videos\ExampleFile1.mkv","C:\Videos\ExampleFile2.mkv" | Get-VideoResolution -LogDirectory "C:\Videos\Logs" -Quiet

    .NOTES
    A check is made to see whether ffmpeg is installed in the environment PATH or in a C:\ffmpeg\bin directory.
    If ffmpeg is not found in either location, the user will be prompted to download ffmpeg which will be saved in the 
    C:\ffmpeg\bin directory.
    #>

    [CmdletBinding()]

    Param(
        [Parameter(Mandatory=$false)]
        [Alias("I")]
        [string]$InputDirectory,
        
        [Parameter(Mandatory=$false)]
        [Alias("L")]
        [string]$LogDirectory,

        [Parameter(Mandatory=$false)]
        [Alias("F")]
        [String]$File,

        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [String[]]$Files,

        [Parameter(Mandatory=$false)]
        [Alias("Q")]
        [Switch]$Quiet,

        [Parameter(Mandatory=$false)]
        [Alias("NL")]
        [Switch]$NoLogs
    )

    Begin {
        # Check to see if ffmpeg is installed and allow install if not found
        $ffmpegLoc = Search-ffmpeg -quiet $Quiet

        # Instantiate a logger
        [Logger]$logger = $null

        # Check if no logging is required
        if ($PSBoundParameters.ContainsKey('NoLogs')) {
            $logger = [Logger]::new($false);
        } else {
            # Check if a log directory was supplied
            if ($PSBoundParameters.ContainsKey('LogDirectory')) {
                # Test the log directory exists
                if (Test-Path -Path $LogDirectory) {
                    $logger = [Logger]::new($true, $LogDirectory)
                } else {
                    Write-Error("The supplied log directory does not exist.")

                    return;
                }
            } else {
                # Instantiate a Logger class and ask user if they want a log file written
                [Logger]$logger = Get-Logger -as [Logger]    
            }
        }

        $filesToProcess = @()
        $isValid = $true
    }

    Process {
        # Check if a file list was supplied
        if ($PSBoundParameters.ContainsKey('Files')) {
            # validate file exists
            if (-Not (Test-Path -Path $Files)) {
                $isValid = $false

                Write-Error("One or more of the supplied files does not exist.")

                return
            }
            
            $filesToProcess += $Files

            return
        }

        # Check if a file was supplied
        if ($PSBoundParameters.ContainsKey('File')) {
            if (Test-Path -Path $File) {
                $filesToProcess += $File

                return
            }
            
            if ($PSBoundParameters.ContainsKey('InputDirectory') -and (Test-Path -Path (Join-Path $InputDirectory $File))) {
                $filesToProcess += (Join-Path $InputDirectory $File)

                return
            }
            
            $isValid = $false

            Write-Error("The supplied file does not exist.")

            return
        }

        [String]$scanDir = ""

        # Check if an input directory was supplied
        if ($PSBoundParameters.ContainsKey('InputDirectory')) {
            # Test the input directory exists
            if (Test-Path -Path $InputDirectory) {
                $scanDir = $InputDirectory
            } else {
                $isValid = $false

                Write-Error("The supplied input directory does not exist.")

                return;
            }
        } else {
            # Prompt user to browse for the directory containing video files to be processed
            Write-Host("")

            $null = Read-Host "Specify the directory to scan, hit any key to open a directory browser"

            $scanDir = Get-Folder
        }

        Get-ChildItem $scanDir -Recurse -Include *avi,*divx,*iso,*m2ts,*m4v,*mkv,*mp4,*mpg,*x265,*wmv  | Group-Object FullName | Select-Object Name | ForEach-Object {
            $filesToProcess += $_.Name
        }
    }

    End {
        if (-Not $isValid) {
            return
        }

        # process the files
        $results = Get-Results -files $filesToProcess

        Write-Host $results

        # Write log files if specified
        Write-Files -logger $logger -results $results -quiet $Quiet

        # Write results to the host
        Write-Output -results $results -quiet $Quiet
    }
}

<# 
.Description
Checks whether ffmpeg is installed in the environment PATH or in a C:\ffmpeg\bin directory.
If ffmpeg is not found in either location, the user will be prompted to download ffmpeg which will be saved in the 
C:\ffmpeg\bin directory.
.Parameter quiet 
Silence verbose writing to host
.Outputs
ffmpeg location identifier, 'path' or 'file'
#>
Function Search-ffmpeg($quiet) {
    if ($null -eq (Get-Command "ffmpeg.exe" -ErrorAction SilentlyContinue)) { 
        if ([System.IO.File]::Exists($ffmpegLocalExe)) {
            return 'local'
        }

        $header = "ffmpeg is required and could not be found in your environment path. You can either opt to download it now or install yourself (via chocolatey: choco install fmmpeg)"
        $question = "Would you like to download ffmpeg now?"

        if (Get-YesNo-As-Bool($header, $question)) {
            Add-ffmpeg -quiet $quiet
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
.Parameter quiet 
Silence verbose writing to host
#>
Function Add-ffmpeg($quiet) {
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

<# 
.Description
Opens a directory browser dialog and returns the user selected path
.Outputs
Selected directory path
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
.Parameter header
Header text to display in the Host.ChoiceDescription control
.Parameter question
Question text to display in the Host.ChoiceDescription control
.Outputs
Result of the user's yes/no choice, true if yes and false if no
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
.Outputs
Logger class
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
.Parameter logger 
The logger class instance
.Parameter results 
Processed files result ArrayList
.Parameter quiet 
Silence verbose writing to host
#>
Function Write-Files($logger, $results, $quiet) {
    # if we don't want to write logs then gtfo
    if (-Not $logger.WriteLogs) {
        return
    }

    # create the output directory
    $null = [System.IO.Directory]::CreateDirectory("$($logger.Dir)")

    # write the text log file
    if (-Not $quiet) {
        Write-Host("")
        Write-Host("Writing log file : $($logger.LogFile())")
    }

    $stream = [System.IO.StreamWriter]::new("$($logger.LogFile())")

    $ResolutionHeader | ForEach-Object{ $stream.WriteLine($_) }

    $results | Sort-Object -Property Width | ForEach-Object { $stream.WriteLine($_.ResultLine()) }

    $NameHeader | ForEach-Object{ $stream.WriteLine($_) }

    $results | Sort-Object -Property File | ForEach-Object { $stream.WriteLine($_.ResultLine()) }

    $stream.close()

    # write the json log file
    if (-Not $quiet) {
        Write-Host("")
        Write-Host("Writing json file : $($logger.LogFile())")
    }

    $results | ConvertTo-Json -Depth 4 | Out-File "$($logger.JsonFile())"
}

<# 
.Description
Write results to the host
.Parameter results 
Processed files result ArrayList
.Parameter quiet 
Silence verbose writing to host
#>
Function Write-Output($results, $quiet) {
    if (-Not $quiet) {
        Write-Host("")
        Write-Host("Finished! Here are the results:")
    }

    if ($results.Count -le 1) {
        $ResultsHeader | ForEach-Object { Write-Host($_) }

        $results | ForEach-Object { Write-Host($_.ResultLine()) }
    } else {
        $ResolutionHeader | ForEach-Object { Write-Host($_) }

        $ResultsHeader | ForEach-Object { Write-Host($_) }

        $results | Sort-Object -Property Width | ForEach-Object { Write-Host($_.ResultLine()) }

        $NameHeader | ForEach-Object { Write-Host($_) }

        $ResultsHeader | ForEach-Object { Write-Host($_) }

        $results | Sort-Object -Property File | ForEach-Object { Write-Host($_.ResultLine()) }
    }

    Write-Host("");
}

<# 
.Description
Process all files and return the results collection
.Parameter files 
Collection of files to be processed
.Outputs
Processed files result ArrayList
#>
Function Get-Results($files) {
    [System.Collections.ArrayList]$results = @()

    $writeProgress = ($files.Count -gt 1)

    for($i=0; $i -lt $files.Length; $i++) {
        # Show video processing progress
        if ($writeProgress) {
            Write-Progress -Activity 'Extracting video resolutions...' -Status "Processing file $($i + 1) of $($files.Length)" -PercentComplete ((($i + 1) / $files.Length) * 100)
        }

        $cmd = '& ' + $(if ($ffmpegLoc -eq "local") { "$ffmpegLocalPath\bin\ffprobe.exe" } else { 'ffprobe' }) + ' -v quiet -select_streams v:0 -show_entries "stream=width,height : format=size" -of json "$($files[$i])"'

        $json = Invoke-Expression $cmd

        [void]$results.Add([VideoInfo]::new("$json", $files[$i]))
    }

    return $results
}

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
        return "VideoResolution.$($this.RunDateTime)"
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

        $this.Dir = "$dir/VideoResolution-Logs.$($this.RunDateTime)"
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