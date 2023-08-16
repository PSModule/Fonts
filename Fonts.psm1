<#
.SYNOPSIS
    Installs a font in the system

.DESCRIPTION
    Installs a font in the system

.PARAMETER Force
    Force will overwrite existing fonts

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
function Install-Font {
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
}

<#
.SYNOPSIS
    Retrieves the installed fonts.

.DESCRIPTION
    Retrieves the installed fonts.

.EXAMPLE
    Get-InstalledFont

    Gets all the fonts installed for the current user.

.EXAMPLE
    Get-InstalledFont -Name 'Arial*'

    Gets all the fonts installed for the current user that start with 'Arial'.

.EXAMPLE
    Get-InstalledFont -Scope 'AllUsers'

    Gets all the fonts installed for all users.

.EXAMPLE
    Get-InstalledFont -Name 'Calibri' -Scope 'AllUsers'

    Gets the font with the name 'Calibri' for all users.

.OUTPUTS
    System.Management.Automation.PSCustomObject[]

#>
function Get-InstalledFont {
    [OutputType([pscustomobject[]])]
    [CmdletBinding()]
    param(
        # Specifies the name of the font to get.
        [Parameter()]
        [SupportsWildcards()]
        [string] $Name = '*',

        # Specifies the scope of the font(s) to get.
        [Parameter()]
        [validateSet('CurrentUser', 'AllUsers')]
        [string] $Scope = 'CurrentUser'
    )

    $fontRegistryPath = $Scope -eq 'CurrentUser' ? 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' : 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

    $fontProperties = Get-ItemProperty -Path $fontRegistryPath
    $filteredFontProperties = $fontProperties.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' -and $_.Name -like $Name }
    $fonts = @()
    foreach ($fontProperty in $filteredFontProperties) {
        $font = [PSCustomObject]@{
            Name  = $fontProperty.Name
            Path  = $Scope -eq 'AllUsers' ? (Join-Path "$($env:windir)\Fonts" $fontProperty.Value) : $fontProperty.Value
            Scope = $Scope
        }
        $fonts += $font
    }

    return $fonts
}

<#
.SYNOPSIS
    Uninstalls a font from the system.

.DESCRIPTION
    Uninstalls a font from the system.

.EXAMPLE
    Uninstall-Font -Name 'Courier New'

    Uninstalls the 'Courier New' font from the system for the current user.

.EXAMPLE
    Uninstall-Font -Name 'Courier New' -Scope AllUsers

    Uninstalls the Courier New font from the system for all users.

.OUTPUTS
    None
#>
function Uninstall-Font {
    [CmdletBinding()]
    param (
        # Scope of the font to uninstall.
        # CurrentUser will uninstall the font for the current user.
        # AllUsers will uninstall the font so it is removed for all users.
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string] $Scope = 'CurrentUser'
    )

    DynamicParam {
        $runtimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

        $parameterName = 'Name'
        $parameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $parameterAttribute.Mandatory = $true
        $parameterAttribute.Position = 1
        $parameterAttribute.HelpMessage = 'Name of the font to uninstall.'
        $parameterAttribute.ValueFromPipeline = $true
        $parameterAttribute.ValueFromPipelineByPropertyName = $true
        $attributeCollection.Add($parameterAttribute)
        $parameterValidateSet = (Get-InstalledFont -Scope $Scope).Name
        $validateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($parameterValidateSet)
        $attributeCollection.Add($validateSetAttribute)
        $runtimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($parameterName, [string], $attributeCollection)
        $runtimeParameterDictionary.Add($parameterName, $runtimeParameter)
        return $runtimeParameterDictionary
    }

    begin {}

    process {
        if ($Scope -eq 'AllUsers' -and -not (Test-Administrator)) {
            throw "Administrator rights are required to uninstall fonts. Please run the command again with elevated rights (Run as Administrator) or provide '-Scope CurrentUser' to your command."
        }

        $Name = $PSBoundParameters['Name']

        Write-Verbose "[$Name] - Uninstalling font - [$Scope]"
        $font = Get-InstalledFont -Name $Name -Scope $Scope
        $filePath = $font.path

        Write-Verbose "[$Name] - Removing file [$filePath]"

        $maxRetries = 10
        $retryIntervalSeconds = 1
        $retryCount = 0
        $fileRemoved = $false

        do {
            try {
                # Try to remove the file
                Remove-Item -Path $filePath -Force -ErrorAction Stop
                $fileRemoved = $true
            } catch {
                # Handle any exceptions here (e.g., file in use)
                $retryCount++
                if (-not $fileRemoved -and $retryCount -eq $maxRetries) {
                    Write-Error $_
                    Write-Error "[$Name] - Removing file [$filePath] - Failed. Attempt [$retryCount/$maxRetries]. Stopping."
                    break
                }
                Write-Warning "[$Name] - Removing file [$filePath] - Failed. Attempt [$retryCount/$maxRetries]. Retrying in $retryIntervalSeconds seconds..."
                Start-Sleep -Seconds $retryIntervalSeconds
            }
        } while (-not $fileRemoved -and $retryCount -lt $maxRetries)

        if (-not $fileRemoved) {
            return
        }

        $fontRegistryPath = $Scope -eq 'CurrentUser' ? 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' : 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
        Write-Verbose "[$Name] - Unregistering font [$fontRegistryPath]"
        Remove-ItemProperty -Path $fontRegistryPath -Name $Name -Force -ErrorAction Stop
    }
}

<#
.SYNOPSIS
    Test if the current user is an administrator.
.DESCRIPTION
    Test if the current user is an administrator.
.OUTPUTS
    Boolean
.EXAMPLE
    Test-Administrator

    Returns true if the current user is an administrator.
#>
function Test-Administrator {
    [OutputType([Boolean])]
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    return $isAdmin
}
