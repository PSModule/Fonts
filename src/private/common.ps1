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

$script:OS = if ($IsWindows) {
    'Windows'
} elseif ($IsLinux) {
    'Linux'
} elseif ($IsMacOS) {
    'MacOS'
} else {
    throw 'Unsupported OS'
}

$script:SupportedFonts = @(
    [pscustomobject]@{
        Extension   = '.ttf'
        Type        = 'TrueType'
        Description = 'TrueType Font'
    }
    [pscustomobject]@{
        Extension   = '.otf'
        Type        = 'OpenType'
        Description = 'OpenType Font'
    }
    [pscustomobject]@{
        Extension   = '.ttc'
        Type        = 'TrueType'
        Description = 'TrueType Font Collection'
    }
    [pscustomobject]@{
        Extension   = '.pfb'
        Type        = 'PostScript Type 1'
        Description = 'PostScript Type 1 Font'
    }
    [pscustomobject]@{
        Extension   = '.pfm'
        Type        = 'PostScript Type 1'
        Description = 'PostScript Type 1 Outline Font'
    }
    [pscustomobject]@{
        Extension   = '.woff'
        Type        = 'Web Open Font Format'
        Description = 'Web Open Font Format'
    }
    [pscustomobject]@{
        Extension   = '.woff2'
        Type        = 'Web Open Font Format 2'
        Description = 'Web Open Font Format 2'
    }
)
