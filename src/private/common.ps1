$script:FontRegPathMap = @{
    CurrentUser = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    AllUsers    = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
}

$script:FontFolderPathMap = @{
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

$script:OS = if ([System.Environment]::OSVersion.Platform -eq 'Win32NT') {
    'Windows'
} elseif ($IsLinux) {
    'Linux'
} elseif ($IsMacOS) {
    'MacOS'
} else {
    throw 'Unsupported OS'
}
