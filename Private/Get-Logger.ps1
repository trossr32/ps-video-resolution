<# 
.Description
Asks the user if they want to create log files and instantiates an instance of the Logger class from the response
.Outputs
Logger class
#>
Function Get-Logger() {
    $header = "Results will be written to this shell. If you'd like to create log files you will be prompted for the directory to save the files to."
    $question = "Would you also like to create a log file?"

    if (Get-YesNo-As-Bool($header, $question)) {
        $logDir = Get-Folder
        return [Logger]::new($true, $logDir)
    }
    
    return [Logger]::new($false)
}