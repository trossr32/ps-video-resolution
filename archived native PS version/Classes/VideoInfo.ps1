<#
.DESCRIPTION
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