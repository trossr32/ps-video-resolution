Function Write-Output($results, $quiet) {
    <# 
    .DESCRIPTION
    Write results to the host
    .PARAMETER results 
    Processed files result ArrayList
    .PARAMETER quiet 
    Silence verbose writing to host
    #>
    
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