# video-file-info
Probe video files for their resolution and output results to host and optionally to log files

## Description
Uses ffmpeg (ffprobe) to interrogate video files and retrieve the resolution and file size.
Outputs the results to the host in 2 ordered lists, firstly by resolution and secondly by file name.

A check is made to see whether ffmpeg is installed in the environment PATH or in a C:\ffmpeg\bin directory.
If ffmpeg is not found in either location, the user will be prompted to download ffmpeg which will be saved in the 
C:\ffmpeg\bin directory.

Results can also be output to log files if the user selects an output folder for logging when prompted.
A text log file is created that is a duplicate of the results written to the host.
A json file is created with an array representation of the VideoFile class.

## Example
.\video-info.ps1
