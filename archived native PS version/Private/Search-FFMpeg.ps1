Function Search-FFmpeg($quiet) {
    <# 
    .DESCRIPTION
    Checks whether ffmpeg is installed in the environment PATH or in a C:\ffmpeg\bin directory.
    If ffmpeg is not found in either location, the user will be prompted to download ffmpeg which will be saved in the 
    C:\ffmpeg\bin directory.
    .PARAMETER quiet 
    Silence verbose writing to host
    .OUTPUTS
    ffmpeg location identifier, 'path' or 'file'
    #>

    if ($null -eq (Get-Command "ffmpeg.exe" -ErrorAction SilentlyContinue)) { 
        if ([System.IO.File]::Exists($ffmpegLocalExe)) {
            return 'local'
        }

        $header = "ffmpeg is required and could not be found in your environment path. You can either opt to download it now or install yourself (via chocolatey: choco install fmmpeg)"
        $question = "Would you like to download ffmpeg now?"

        if (Get-YesNo-As-Bool($header, $question)) {
            Add-FFmpeg -quiet $quiet
        } else {
            exit
        }

        return 'local'
    }

    return 'path'
}