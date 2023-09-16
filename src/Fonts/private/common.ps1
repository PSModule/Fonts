$script:fontRegPath = @{
    CurrentUser = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    AllUsers    = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
}

$script:fontFolderPath = @{
    CurrentUser = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    AllUsers    = "$($env:windir)\Fonts"
}
