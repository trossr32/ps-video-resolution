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
        $ffmpegLoc = Search-FFmpeg -quiet $Quiet

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