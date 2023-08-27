<#
.SYNOPSIS
    Retrieves the installed fonts.

.DESCRIPTION
    Retrieves the installed fonts.

.EXAMPLE
    Get-Font

    Gets all the fonts installed for the current user.

.EXAMPLE
    Get-Font -Name 'Arial*'

    Gets all the fonts installed for the current user that start with 'Arial'.

.EXAMPLE
    Get-Font -Scope 'AllUsers'

    Gets all the fonts installed for all users.

.EXAMPLE
    Get-Font -Name 'Calibri' -Scope 'AllUsers'

    Gets the font with the name 'Calibri' for all users.

.OUTPUTS
    System.Management.Automation.PSCustomObject[]

#>
function Get-Font {
    [OutputType([pscustomobject[]])]
    [CmdletBinding()]
    param(
        # Specifies the name of the font to get.
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [SupportsWildcards()]
        [string[]] $Name = '*',

        # Specifies the scope of the font(s) to get.
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('ConfigScope')]
        [System.Management.Automation.Configuration.ConfigScope[]] $Scope = 'CurrentUser'
    )

    begin {
        $functionName = $MyInvocation.MyCommand.Name
        Write-Verbose "[$functionName]"

        $regPath = @{
            CurrentUser = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
            AllUsers    = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
        }
        $nameCount = $Name.Count
    }

    process {
        Write-Verbose "[$functionName] - Processing [$($Scope.Count)] scope(s)"
        foreach ($ScopeItem in $Scope) {
            $scopeName = $ScopeItem.ToString()

            Write-Verbose "[$functionName] - [$scopeName] - Getting font(s)"
            $fontRegistryPath = $regPath[$scopeName]
            $registeredFonts = (Get-ItemProperty -Path $fontRegistryPath).PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } # Remove PS* properties
            $registeredFontsCount = $($registeredFonts.Count)
            Write-Verbose "[$functionName] - [$scopeName] - Filtering from [$registeredFontsCount] font(s)"

            Write-Verbose "[$functionName] - [$scopeName] - Filtering based on [$nameCount] name pattern(s)"
            foreach ($fontFilter in $Name) {
                Write-Verbose "[$functionName] - [$scopeName] - [$fontFilter] - Filtering font(s)"
                $filteredFonts = $registeredFonts | Where-Object { $_.Name -like $fontFilter }

                foreach ($fontItem in $filteredFonts) {
                    $fontName = $fontItem.Name
                    $fontPath = $Scope -eq 'AllUsers' ? (Join-Path "$($env:windir)\Fonts" $fontItem.Value) : $fontItem.Value
                    $fontScope = $scopeName
                    Write-Verbose "[$functionName] - [$scopeName] - [$fontFilter] - Found [$fontName] at [$fontPath]"

                    [PSCustomObject]@{
                        Name  = $fontName
                        Path  = $fontPath
                        Scope = $fontScope
                    }
                }
                Write-Verbose "[$functionName] - [$scopeName] - [$fontFilter] - Done"
            }
            Write-Verbose "[$functionName] - [$scopeName] - Done"
        }
    }

    end {
        Write-Verbose "[$functionName] - Done"
    }
}

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
function Install-Font {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # File or folder path(s) to the font(s) to install.
        [Parameter(
            Mandatory,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('FullName')]
        [string[]] $Path,

        # Scope of the font installation.
        # CurrentUser will install the font for the current user only.
        # AllUsers will install the font so it is available for all users on the system.
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('ConfigScope')]
        [System.Management.Automation.Configuration.ConfigScope[]] $Scope = 'CurrentUser',

        # Recurse will install all fonts in the specified folder and subfolders.
        [Parameter()]
        [switch] $Recurse,

        # Force will overwrite existing fonts
        [Parameter()]
        [switch] $Force
    )

    begin {
        if ($Scope -eq 'AllUsers' -and -not (IsAdmin)) {
            throw "Administrator rights are required to install fonts in '$fontFolderPath'. Please run the command again with elevated rights (Run as Administrator) or provide '-Scope CurrentUser' to your command."
        }

        $fontFolderPath = $Scope -eq 'CurrentUser' ? "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" : "$($env:windir)\Fonts"
        $fontRegistryPath = $Scope -eq 'CurrentUser' ? 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' : 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    }

    process {
        foreach ($PathItem in $Path) {
            if (-not (Test-Path -Path $PathItem)) {
                Write-Error "File [$PathItem] does not exist."
                return
            }

            $Item = Get-Item -Path $PathItem -ErrorAction Stop

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
                    # Write-Warning "[$($FontFile.Name)] - Unknown font type. Skipping."
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
    }

    end {}
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
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('ConfigScope')]
        [System.Management.Automation.Configuration.ConfigScope[]] $Scope = 'CurrentUser'
    )

    DynamicParam {
        $runtimeDefinedParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

        $parameterName = 'Name'
        $parameterAliases = @('FontName', 'Font')
        $parameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $parameterAttribute.Mandatory = $true
        $parameterAttribute.Position = 1
        $parameterAttribute.HelpMessage = 'Name of the font to uninstall.'
        $parameterAttribute.ValueFromPipeline = $true
        $parameterAttribute.ValueFromPipelineByPropertyName = $true
        $attributeCollection.Add($parameterAttribute)

        foreach ($parameterAlias in $parameterAliases) {
            $parameterAttribute = New-Object System.Management.Automation.AliasAttribute($parameterAlias)
            $attributeCollection.Add($parameterAttribute)
        }

        $parameterValidateSet = switch ($Scope) {
            'AllUsers' {
                (Get-Font -Scope 'AllUsers').Name
            }
            'CurrentUser' {
                (Get-Font -Scope 'CurrentUser').Name
            }
            default {
                (Get-Font -Scope 'CurrentUser').Name + (Get-Font -Scope 'AllUsers').Name
            }
        }
        $validateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($parameterValidateSet)
        $validateSetAttribute.ErrorMessage = "The font name provided was not found in the selected scope [$Scope]."
        $attributeCollection.Add($validateSetAttribute)

        $runtimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($parameterName, [string[]], $attributeCollection)
        $runtimeDefinedParameterDictionary.Add($parameterName, $runtimeParameter)
        return $runtimeDefinedParameterDictionary
    }

    begin {
        if ($Scope -eq 'AllUsers' -and -not (IsAdmin)) {
            throw "Administrator rights are required to uninstall fonts. Please run the command again with elevated rights (Run as Administrator) or provide '-Scope CurrentUser' to your command."
        }
        $maxRetries = 10
        $retryIntervalSeconds = 1
        $fontRegistryPath = $Scope -eq 'CurrentUser' ? 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' : 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    }

    process {
        $Name = $PSBoundParameters['Name']

        foreach ($fontName in $Name) {
            Write-Verbose "[$fontName] - Uninstalling font - [$Scope]"
            $font = Get-Font -Name $fontName -Scope $Scope
            $filePath = $font.path

            $fileExists = Test-Path -Path $filePath
            if (-not $fileExists) {
                Write-Warning "[$fontName] - File [$filePath] does not exist. Skipping."
            } else {

                Write-Verbose "[$fontName] - Removing file [$filePath]"
                $retryCount = 0
                $fileRemoved = $false

                do {
                    try {
                        Remove-Item -Path $filePath -Force -ErrorAction Stop
                        $fileRemoved = $true
                    } catch {
                        # Common error; 'file in use'.
                        $retryCount++
                        if (-not $fileRemoved -and $retryCount -eq $maxRetries) {
                            Write-Error $_
                            Write-Error "[$fontName] - Removing file [$filePath] - Failed. Attempt [$retryCount/$maxRetries]. Stopping."
                            break
                        }
                        Write-Warning "[$fontName] - Removing file [$filePath] - Failed. Attempt [$retryCount/$maxRetries]. Retrying in $retryIntervalSeconds seconds..."
                        Start-Sleep -Seconds $retryIntervalSeconds
                    }
                } while (-not $fileRemoved -and $retryCount -lt $maxRetries)

                if (-not $fileRemoved) {
                    break  # Break to skip unregistering the font if the file could not be removed.
                }
            }

            $fontRegistryPathExists = Get-ItemProperty -Path $fontRegistryPath -Name $fontName -ErrorAction SilentlyContinue
            if (-not $fontRegistryPathExists) {
                Write-Warning "[$fontName] - Font is not registered. Skipping."
            } else {
                Write-Verbose "[$fontName] - Unregistering font [$fontRegistryPath]"
                Remove-ItemProperty -Path $fontRegistryPath -Name $fontName -Force -ErrorAction Stop
            }
        }
    }

    end {}
}

Export-ModuleMember -Function '*' -Alias '*' -Variable '*' -Cmdlet '*'
