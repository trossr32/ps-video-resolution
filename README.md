# VideoResolution

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/VideoResolution?label=VideoResolution&logo=powershell&style=plastic)](https://www.powershellgallery.com/packages/VideoResolution)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/VideoResolution?style=plastic)](https://www.powershellgallery.com/packages/VideoResolution)

A Powershell module that probes video files for their resolution and output results to host and optionally to log files.

Available in the [Powershell Gallery](https://www.powershellgallery.com/packages/VideoResolution)

## Description
Uses ffmpeg (ffprobe) to interrogate video files and retrieve the resolution and file size.

Can be run against: 

* all files in an input directory supplied as an InputDirectory parameter or from a user prompt.
* a file using the File parameter. This can be a file name in the current directory, a relative path, a full path, or a file name used in conjunction with the InputDirectory parameter.
* a collection of files piped into the module (note: this expects correct paths and won't use the InputDirectory parameter).

If there is more than one result the module outputs the results to the host in 2 ordered lists, firstly by resolution and secondly by file name.

Results can also be output to log files if the user selects an output folder for logging when prompted or supplies a LogDirectory parameter.
A text log file is created that is a duplicate of the results written to the host.
A json file is created with an array representation of the VideoFile class.

## Installation

```powershell
Install-Module VideoResolution
```

## Parameters

#### -InputDirectory (alias -I)
*Optional*. If supplied this is the path used to find video files to process. If not supplied, the user will be 
prompted to browse for and select the path to use. If used in conjunction with the File parameter then this path
will be joined to the file provided.

#### -File (alias -F)
*Optional*. If supplied this file will be processed. Must be a file in the current directory, a relative path, a full
path, or a filename used in conjunction with the InputDirectory parameter.

#### -Files
*Optional*. Accepted as piped input. If supplied all files in this string array will be processed. Each file must be 
in the current directory, a relative path or a full path. Cannot be used in conjunction with the InputDirectory parameter.

#### -LogDirectory (alias -L)
*Optional*. If supplied this is the path used to write text and json log files. If not supplied, the user will be 
prompted firstly whether log files should be created, and if so then prompted to browse for and select the path to use.

#### -NoLogs (alias -NL)
*Optional*. If supplied no log files will be created. Overrides the LogDirectory parameter.

#### -Quiet (alias -Q)
*Optional*. Removes verbose host output.

## Examples

All files in directory request which will prompt the user to select an input directory, whether log files should be created, and a log file directory:

```powershell
PS C:\> Get-VideoResolution
```

All files in the supplied input directory, writing logs to the supplied log file directory and no verbose host output:

```powershell
PS C:\> Get-VideoResolution -InputDirectory "C:\Videos" -LogDirectory "C:\Videos\Logs" -Quiet
```

Process the supplied file with no logging:

```powershell
PS C:\> Get-VideoResolution -File "C:\Videos\ExampleFile.mkv" -NoLogs
```

Process the supplied file using the current directory and prompt for whether log files should be created and the log file directory:

```powershell
PS C:\Videos\> Get-VideoResolution -File "ExampleFile.mkv"
```

Process the piped files array, writing logs to the supplied log file directory and no verbose host output:

```powershell
PS C:\> "C:\Videos\ExampleFile1.mkv","C:\Videos\ExampleFile2.mkv" | Get-VideoResolution -LogDirectory "C:\Videos\Logs" -Quiet
```

## Notes
A check is made to see whether ffmpeg is installed in the environment PATH or in a C:\ffmpeg\bin directory.
If ffmpeg is not found in either location, the user will be prompted to download ffmpeg which will be saved in the 
C:\ffmpeg\bin directory.
