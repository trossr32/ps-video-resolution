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