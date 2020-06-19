Function Get-Folder {
    <# 
    .DESCRIPTION
    Opens a directory browser dialog and returns the user selected path
    .OUTPUTS
    Selected directory path
    #>

    [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.RootFolder = [System.Environment+specialfolder]::Desktop
    
    [void] $dialog.ShowDialog()
    
    return $dialog.SelectedPath
}