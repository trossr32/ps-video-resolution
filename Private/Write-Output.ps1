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