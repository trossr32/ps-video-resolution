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