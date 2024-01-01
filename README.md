# VideoResolution

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/VideoResolution?label=VideoResolution&logo=powershell&style=plastic)](https://www.powershellgallery.com/packages/VideoResolution)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/VideoResolution?style=plastic)](https://www.powershellgallery.com/packages/VideoResolution)

A Powershell module that probes video files for their resolution and output results to host and optionally to log files.

Available in the [Powershell Gallery](https://www.powershellgallery.com/packages/VideoResolution)

## Description
Uses ffmpeg (ffprobe) to interrogate video files and retrieve the resolution and file size.

> [!NOTE]
> ffmpeg must be installed for this module to work. It can be installed using [chocolatey](https://chocolatey.org/packages/ffmpeg) or [scoop](https://scoop.sh/) or downloaded from [ffmpeg.org](https://ffmpeg.org/download.html).

Can be run against: 

* all files in an input directory supplied as an `-InputDirectory` parameter.
* a file using the `-File` parameter. This can be a file name in the current directory, a relative path, a full path, or a file name used in conjunction with the `-InputDirectory` parameter.
* a collection of files piped into the module (note: this expects correct paths and won't use the `-InputDirectory` parameter).

If there is more than one result the module outputs the results to the host in 2 ordered lists, firstly by resolution and secondly by file name.

Results can also be output to log and json files if an `-OutputDirectory` parameter is supplied.
A text log file is created that is a duplicate of the results written to the host.
A json file is created with an array representation of the `VideoInfo` class.

Alternatively return results as json using the `-Json` parameter, or as an object using the `-PSObject` parameter.

## Installation

```powershell
Install-Module VideoResolution
```

## Parameters

#### `-InputDirectory`
*Optional*. If supplied this is the path used to find video files to process. If used in conjunction with the File
parameter then this path will be joined to the file provided.

#### `-OutputDirectory`
*Optional*. If supplied this is the path used to write text and json data files.

#### `-File`
*Optional*. If supplied, this file will be processed. Must be a file in the current directory, a relative path, a full
path, or a filename used in conjunction with the InputDirectory parameter.

#### `-Files`
*Optional*. Accepted as piped input. If supplied, all files in this string array will be processed. Each file must be
in the current directory, a relative path, or a full path. Will be ignored if used in conjunction with the
InputDirectory parameter.

#### `-Recursive`
*Optional*. If supplied along with an input directory, all sub-directories will also be searched for video files.

#### `-Json`
*Optional*. If supplied json will be returned instead of the standard output.

#### `-PSObject`
*Optional*. If supplied a PsObject will be returned instead of the standard output.

## Examples

Process the supplied file using the current directory

```powershell
PS C:\Videos\> Get-VideoResolution -File "ExampleFile.mkv"
```

All files in the supplied input directory, writing json and log files to the supplied output directory.

```powershell
PS C:\> Get-VideoResolution -InputDirectory "C:\Videos" -OutputDirectory "C:\Videos\Logs"
```

Process the supplied file using the supplied input directory

```powershell
PS C:\Videos\> Get-VideoResolution -File "ExampleFile.mkv" -InputDirectory "C:\Videos"
```

Process the supplied file with path

```powershell
PS C:\Videos\> Get-VideoResolution -File "C:\Videos\ExampleFile.mkv"
```

Process the supplied file and return json

```powershell
PS C:\Videos\> Get-VideoResolution -File "C:\Videos\ExampleFile.mkv" -Json
```

Process the supplied file and return a PSObject

```powershell
PS C:\Videos\> Get-VideoResolution -File "C:\Videos\ExampleFile.mkv" -PSObject
```

Process the piped files array, writing json and log files to the supplied output directory.

```powershell
PS C:\> "C:\Videos\ExampleFile1.mkv","C:\Videos\ExampleFile2.mkv" | Get-VideoResolution -OutputDirectory "C:\Videos\Logs"

## Contribute

Please raise an issue if you find a bug or want to request a new feature, or create a pull request to contribute.

<a href='https://ko-fi.com/K3K22CEIT' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi4.png?v=2' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
