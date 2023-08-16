
<#PSScriptInfo

.VERSION 0.1.0

.GUID 350222de-538e-4e49-93fd-c6a9fe9fa783

.AUTHOR Marius Storhaug

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<#

.DESCRIPTION
 Install a font on a Windows system

#>
<#
.SYNOPSIS
    Installs a font in the system

.DESCRIPTION
    Installs a font in the system

.EXAMPLE
    Install-Font -Path C:\FontFiles\Arial.ttf

    Installs the font file 'C:\FontFiles\Arial.ttf' to the current user profile.

.EXAMPLE
    Install-Font -Path C:\FontFiles\Arial.ttf -Scope AllUsers

    Installs the font file 'C:\FontFiles\Arial.ttf' so it is available for all users. This requires administrator rights.

.EXAMPLE
    Install-Font -Path C:\FontFiles\Arial.ttf -Force

    Installs the font file 'C:\FontFiles\Arial.ttf' to the current user profile. If the font already exists, it will be overwritten.

.EXAMPLE
    Install-Font -Path C:\FontFiles\Arial.ttf -Scope AllUsers -Force

    Installs the font file 'C:\FontFiles\Arial.ttf' so it is available for all users. This requires administrator rights. If the font already exists, it will be overwritten.

.EXAMPLE
    Get-ChildItem -Path C:\FontFiles\ -Filter *.ttf | Install-Font

    Gets all font files in the folder 'C:\FontFiles\' and installs them to the current user profile.

.EXAMPLE
    Get-ChildItem -Path C:\FontFiles\ -Filter *.ttf | Install-Font -Scope AllUsers

    Gets all font files in the folder 'C:\FontFiles\' and installs them so it is available for all users. This requires administrator rights.

.EXAMPLE
    Get-ChildItem -Path C:\FontFiles\ -Filter *.ttf | Install-Font -Force

    Gets all font files in the folder 'C:\FontFiles\' and installs them to the current user profile. If the font already exists, it will be overwritten.

.EXAMPLE
    Get-ChildItem -Path C:\FontFiles\ -Filter *.ttf | Install-Font -Scope AllUsers -Force

    Gets all font files in the folder 'C:\FontFiles\' and installs them so it is available for all users. This requires administrator rights. If the font already exists, it will be overwritten.
#>
[CmdletBinding()]
param (
    # File or folder path(s) to the font(s) to install.
    [Parameter(
        Mandatory,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [Alias('FullName')]
    [string] $Path,

    # Scope of the font installation.
    # CurrentUser will install the font for the current user only.
    # AllUsers will install the font so it is available for all users on the system.
    [Parameter()]
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string] $Scope = 'CurrentUser',

    # Recurse will install all fonts in the specified folder and subfolders.
    [Parameter()]
    [switch]$Recurse,

    # Force will overwrite existing fonts
    [Parameter()]
    [switch]$Force
)

begin {
    $fontFolderPath = $Scope -eq 'CurrentUser' ? "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" : "$($env:windir)\Fonts"
    $fontRegistryPath = $Scope -eq 'CurrentUser' ? 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' : 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

    if ($Scope -eq 'AllUsers' -and -not (Test-Administrator)) {
        throw "Administrator rights are required to install fonts in '$fontFolderPath'. Please run the command again with elevated rights (Run as Administrator) or provide '-Scope CurrentUser' to your command."
    }
}

process {
    if (-not (Test-Path -Path $Path)) {
        Write-Error "File [$Path] does not exist."
        return
    }

    $Item = Get-Item -Path $Path -ErrorAction Stop

    if ($Item.PSIsContainer) {
        Write-Verbose "[$($Item.FullName)] - Gathering font(s) to install."
        $FontFiles = Get-ChildItem -Path $Item.FullName -ErrorAction Stop -File -Recurse:$Recurse
        Write-Verbose "[$($Item.FullName)] - Gathering font(s) to install. - [$($FontFiles.Count)] font(s) found."
    } else {
        $FontFiles = $Item
    }

    $shell = New-Object -ComObject Shell.Application

    foreach ($FontFile in $FontFiles) {
        $fontFileDestinationPath = Join-Path $fontFolderPath $FontFile.Name
        $fontFileAlreadyInstalled = Test-Path -Path $fontFileDestinationPath
        if ($fontFileAlreadyInstalled) {
            if ($Force) {
                Write-Verbose "[$($FontFile.Name)] - Already installed. Forcing install."
            } else {
                Write-Verbose "[$($FontFile.Name)] - Already installed. Skipping."
                continue
            }
        }

        $fontType = switch ($FontFile.Extension) {
            '.ttf' { 'TrueType' } # TrueType Font
            '.otf' { 'OpenType' } # OpenType Font
            '.ttc' { 'TrueType' } # TrueType Font Collection
            '.pfb' { 'PostScript Type 1' } # PostScript Type 1 Font
            '.pfm' { 'PostScript Type 1' } # PostScript Type 1 Outline Font
            '.woff' { 'Web Open Font Format' } # Web Open Font Format
            '.woff2' { 'Web Open Font Format 2' } # Web Open Font Format 2
        }

        if ($null -eq $fontType) {
            Write-Warning "[$($FontFile.Name)] - Unknown font type. Skipping."
            continue
        }

        Write-Verbose "[$($FontFile.Name)] - Installing font - [$Scope]"

        $shellFolder = $shell.Namespace($FontFile.Directory.FullName)
        $shellFile = $shellFolder.ParseName($FontFile.name)
        $fontName = $shellFolder.GetDetailsOf($shellFile, 21)



        Write-Verbose "[$($FontFile.Name)] - Installing font - [$fontName]"

        $maxRetries = 10
        $retryIntervalSeconds = 1
        $retryCount = 0
        $fileCopied = $false

        do {
            try {
                $destinationFilePath = Join-Path $fontFolderPath $FontFile.Name
                Copy-Item -Path $FontFile.FullName -Destination $destinationFilePath -Force -ErrorAction Stop
                $fileCopied = $true
            } catch {
                $retryCount++
                if (-not $fileRemoved -and $retryCount -eq $maxRetries) {
                    Write-Error $_
                    Write-Error "[$($FontFile.Name)] - Installing font - [$fontName] - Failed. Attempt [$retryCount/$maxRetries]. Stopping."
                    break
                }
                Write-Warning "[$($FontFile.Name)] - Installing font - [$fontName] - Failed. Attempt [$retryCount/$maxRetries]. Retrying in $retryIntervalSeconds seconds..."
                Start-Sleep -Seconds $retryIntervalSeconds
            }
        } while (-not $fileCopied -and $retryCount -lt $maxRetries)

        if (-not $fileCopied) {
            continue
        }
        $registeredFontName = "$fontName ($fontType)"
        Write-Verbose "[$($FontFile.Name)] - Registering font as [$registeredFontName]"
        $regValue = $Scope -eq 'AllUsers' ? $FontFile.Name : $destinationFilePath
        New-ItemProperty -Name "$fontName ($fontType)" -Path $fontRegistryPath -PropertyType string -Value $regValue -Force -ErrorAction stop | Out-Null
    }
}

end {}
