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