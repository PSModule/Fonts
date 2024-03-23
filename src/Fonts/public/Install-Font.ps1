#Requires -Modules Utilities

function Install-Font {
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

            Installs the font file 'C:\FontFiles\Arial.ttf' so it is available for all users.
            This requires administrator rights.

        .EXAMPLE
            Install-Font -Path C:\FontFiles\Arial.ttf -Force

            Installs the font file 'C:\FontFiles\Arial.ttf' to the current user profile.
            If the font already exists, it will be overwritten.

        .EXAMPLE
            Install-Font -Path C:\FontFiles\Arial.ttf -Scope AllUsers -Force

            Installs the font file 'C:\FontFiles\Arial.ttf' so it is available for all users.
            This requires administrator rights. If the font already exists, it will be overwritten.

        .EXAMPLE
            Get-ChildItem -Path C:\FontFiles\ -Filter *.ttf | Install-Font

            Gets all font files in the folder 'C:\FontFiles\' and installs them to the current user profile.

        .EXAMPLE
            Get-ChildItem -Path C:\FontFiles\ -Filter *.ttf | Install-Font -Scope AllUsers

            Gets all font files in the folder 'C:\FontFiles\' and installs them so it is available for all users.
            This requires administrator rights.

        .EXAMPLE
            Get-ChildItem -Path C:\FontFiles\ -Filter *.ttf | Install-Font -Force

            Gets all font files in the folder 'C:\FontFiles\' and installs them to the current user profile.
            If the font already exists, it will be overwritten.

        .EXAMPLE
            Get-ChildItem -Path C:\FontFiles\ -Filter *.ttf | Install-Font -Scope AllUsers -Force

            Gets all font files in the folder 'C:\FontFiles\' and installs them so it is available for all users.
            This requires administrator rights. If the font already exists, it will be overwritten.
    #>
    [Alias('Install-Fonts')]
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # File or folder path(s) to the font(s) to install.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
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
        $functionName = $MyInvocation.MyCommand.Name
        Write-Verbose "[$functionName]"

        if ($Scope -contains 'AllUsers' -and -not (IsAdmin)) {
            $errorMessage = @"
Administrator rights are required to install fonts in [$($script:fontFolderPath['AllUsers'])].
Please run the command again with elevated rights (Run as Administrator) or provide '-Scope CurrentUser' to your command.
"@
            throw $errorMessage
        }

        $maxRetries = 10
        $retryIntervalSeconds = 1
    }

    process {
        $scopeCount = $Scope.Count
        Write-Verbose "[$functionName] - Processing [$scopeCount] scopes(s)"
        foreach ($scopeItem in $Scope) {
            $scopeName = $scopeItem.ToString()
            $fontDestinationFolderPath = $script:fontFolderPath[$scopeName]
            $fontDestinationRegPath = $script:fontRegPath[$scopeName]

            $pathCount = $Path.Count
            Write-Verbose "[$functionName] - [$scopeName] - Processing [$pathCount] path(s)"
            foreach ($PathItem in $Path) {
                Write-Verbose "[$functionName] - [$scopeName] - [$PathItem] - Processing"

                $pathExists = Test-Path -Path $PathItem
                if (-not $pathExists) {
                    Write-Error "[$functionName] - [$scopeName] - [$PathItem] - Path not found, skipping."
                    continue
                }
                $item = Get-Item -Path $PathItem -ErrorAction Stop

                if ($item.PSIsContainer) {
                    Write-Verbose "[$functionName] - [$scopeName] - [$PathItem] - Folder found"
                    Write-Verbose "[$functionName] - [$scopeName] - [$PathItem] - Gathering font(s) to install"
                    $fontFiles = Get-ChildItem -Path $item.FullName -ErrorAction Stop -File -Recurse:$Recurse
                    Write-Verbose "[$functionName] - [$scopeName] - [$PathItem] - Found [$($FontFiles.Count)] font file(s)"
                } else {
                    Write-Verbose "[$functionName] - [$scopeName] - [$PathItem] - File found"
                    $FontFiles = $Item
                }

                foreach ($fontFile in $fontFiles) {
                    $fontFileName = $fontFile.Name
                    $fontName = $fontFile.BaseName
                    $fontFilePath = $fontFile.FullName
                    Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Processing"

                    $fontFileDestinationPath = Join-Path $fontDestinationFolderPath $fontFileName
                    $fontFileAlreadyInstalled = Test-Path -Path $fontFileDestinationPath
                    if ($fontFileAlreadyInstalled) {
                        if ($Force) {
                            Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Already installed. Forcing install."
                        } else {
                            Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Already installed. Skipping."
                            continue
                        }
                    }

                    $fontType = switch ($fontFile.Extension) {
                        '.ttf' { 'TrueType' }                 # TrueType Font
                        '.otf' { 'OpenType' }                 # OpenType Font
                        '.ttc' { 'TrueType' }                 # TrueType Font Collection
                        '.pfb' { 'PostScript Type 1' }        # PostScript Type 1 Font
                        '.pfm' { 'PostScript Type 1' }        # PostScript Type 1 Outline Font
                        '.woff' { 'Web Open Font Format' }    # Web Open Font Format
                        '.woff2' { 'Web Open Font Format 2' } # Web Open Font Format 2
                    }

                    if ($null -eq $fontType) {
                        # Write-Warning "[$fontFileName] - Unknown font type. Skipping."
                        continue
                    }

                    Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Installing font"

                    $retryCount = 0
                    $fileCopied = $false

                    do {
                        try {
                            $fontFile.CopyTo($fontFileDestinationPath, $true)
                            $fileCopied = $true
                        } catch {
                            $retryCount++
                            if (-not $fileRemoved -and $retryCount -eq $maxRetries) {
                                Write-Error $_
                                Write-Error "Failed [$retryCount/$maxRetries] - Stopping"
                                break
                            }
                            Write-Verbose "Failed [$retryCount/$maxRetries] - Retrying in $retryIntervalSeconds seconds..."
                            Start-Sleep -Seconds $retryIntervalSeconds
                        }
                    } while (-not $fileCopied -and $retryCount -lt $maxRetries)

                    if (-not $fileCopied) {
                        continue
                    }
                    $registeredFontName = "$fontName ($fontType)"
                    Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Registering font as [$registeredFontName]"
                    $regValue = 'AllUsers' -eq $Scope ? $fontFileName : $fontFileDestinationPath
                    $params = @{
                        Name         = $registeredFontName
                        Path         = $fontDestinationRegPath
                        PropertyType = 'string'
                        Value        = $regValue
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }
                    New-ItemProperty @params | Out-Null
                    Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Done"
                }
                Write-Verbose "[$functionName] - [$scopeName] - [$PathItem] - Done"
            }
            Write-Verbose "[$functionName] - [$scopeName] - Done"
        }
    }

    end {
        Write-Verbose "[$functionName] - Done"
    }
}
