<# 
.Description
Opens a directory browser dialog and returns the user selected path
.Outputs
Selected directory path
#>
Function Get-Folder {
    [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.RootFolder = [System.Environment+specialfolder]::Desktop
    
    [void] $dialog.ShowDialog()
    
    return $dialog.SelectedPath
}