$script:fontRegPathMap = @{
    CurrentUser = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    AllUsers    = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
}

$script:fontFolderPathMap = @{
    'Windows' = @{
        CurrentUser = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
        AllUsers    = "$($env:windir)\Fonts"
    }
    'MacOS'   = @{
        CurrentUser = "$env:HOME/Library/Fonts"
        AllUsers    = '/Library/Fonts'
    }
    'Linux'   = @{
        CurrentUser = "$env:HOME/.fonts"
        AllUsers    = '/usr/share/fonts'
    }
}
