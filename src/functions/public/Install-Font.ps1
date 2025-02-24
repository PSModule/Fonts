#Requires -Modules @{ ModuleName = 'Admin'; RequiredVersion = '1.1.5' }

function Install-Font {
    <#
        .SYNOPSIS
        Installs a font in the system.

        .DESCRIPTION
        Installs a font in the system, either for the current user or all users, depending on the specified scope.
        If the font is already installed, it can be optionally overwritten using the `-Force` parameter.
        The function supports both single file installations and batch installations via pipeline input.

        Installing fonts for all users requires administrator privileges.

        .EXAMPLE
        Install-Font -Path C:\FontFiles\Arial.ttf

        Output:
        ```powershell
        Arial.ttf installed for the current user.
        ```

        Installs the font file `Arial.ttf` for the current user.

        .EXAMPLE
        Install-Font -Path C:\FontFiles\Arial.ttf -Scope AllUsers

        Output:
        ```powershell
        Arial.ttf installed for all users.
        ```

        Installs the font file `Arial.ttf` system-wide, making it available to all users.
        This requires administrator rights.

        .EXAMPLE
        Install-Font -Path C:\FontFiles\Arial.ttf -Force

        Output:
        ```powershell
        Arial.ttf reinstalled for the current user.
        ```

        Installs the font file `Arial.ttf` for the current user. If it already exists, it will be overwritten.

        .EXAMPLE
        Install-Font -Path C:\FontFiles\Arial.ttf -Scope AllUsers -Force

        Output:
        ```powershell
        Arial.ttf reinstalled for all users.
        ```

        Installs the font file `Arial.ttf` system-wide and overwrites the existing font if present.

        .EXAMPLE
        Get-ChildItem -Path C:\FontFiles\ -Filter *.ttf | Install-Font

        Output:
        ```powershell
        Found 3 font files.
        Arial.ttf installed for the current user.
        Verdana.ttf installed for the current user.
        TimesNewRoman.ttf installed for the current user.
        ```

        Installs all `.ttf` font files found in `C:\FontFiles\` for the current user.

        .EXAMPLE
        Get-ChildItem -Path C:\FontFiles\ -Filter *.ttf | Install-Font -Scope AllUsers

        Output:
        ```powershell
        Found 3 font files.
        Arial.ttf installed for all users.
        Verdana.ttf installed for all users.
        TimesNewRoman.ttf installed for all users.
        ```

        Installs all `.ttf` font files found in `C:\FontFiles\` system-wide.
        This requires administrator rights.

        .EXAMPLE
        Get-ChildItem -Path C:\FontFiles\ -Filter *.ttf | Install-Font -Scope AllUsers -Force

        Output:
        ```powershell
        Found 3 font files.
        Arial.ttf reinstalled for all users.
        Verdana.ttf reinstalled for all users.
        TimesNewRoman.ttf reinstalled for all users.
        ```

        Installs all `.ttf` font files found in `C:\FontFiles\` system-wide, overwriting existing fonts.
        This requires administrator rights.

        .OUTPUTS
        System.String

        .NOTES
        Returns messages indicating success or failure of font installation.

        .LINK
        https://psmodule.io/Admin/Functions/Install-Font/
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
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string[]] $Scope = 'CurrentUser',

        # Recurse will install all fonts in the specified folder and subfolders.
        [Parameter()]
        [switch] $Recurse,

        # Force will overwrite existing fonts.
        [Parameter()]
        [switch] $Force
    )

    begin {
        $functionName = $MyInvocation.MyCommand.Name
        Write-Verbose "[$functionName]"

        if ($Scope -contains 'AllUsers' -and -not (IsAdmin)) {
            $errorMessage = @"
Administrator rights are required to install fonts in [$($script:FontFolderPathMap[$script:OS]['AllUsers'])].
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
        foreach ($scopeName in $Scope) {
            $fontDestinationFolderPath = $script:FontFolderPathMap[$script:OS][$scopeName]
            $pathCount = $Path.Count
            Write-Verbose "[$functionName] - [$scopeName] - Processing [$pathCount] path(s)"
            foreach ($PathItem in $Path) {
                Write-Verbose "[$functionName] - [$scopeName] - [$PathItem] - Processing"
                $pathExists = Test-Path -Path $PathItem -ErrorAction SilentlyContinue
                if (-not $pathExists) {
                    Write-Error "[$functionName] - [$scopeName] - [$PathItem] - Path not found, skipping."
                    continue
                }
                $item = Get-Item -Path $PathItem -ErrorAction Stop

                if ($item.PSIsContainer) {
                    Write-Verbose "[$functionName] - [$scopeName] - [$PathItem] - Folder found"
                    Write-Verbose "[$functionName] - [$scopeName] - [$PathItem] - Gathering font(s) to install"
                    $fontFiles = Get-ChildItem -Path $item.FullName -ErrorAction Stop -File -Recurse:$Recurse
                    Write-Verbose "[$functionName] - [$scopeName] - [$PathItem] - Found [$($fontFiles.Count)] font file(s)"
                } else {
                    Write-Verbose "[$functionName] - [$scopeName] - [$PathItem] - File found"
                    $fontFiles = $Item
                }

                foreach ($fontFile in $fontFiles) {
                    $fontFileName = $fontFile.Name
                    $fontName = $fontFile.BaseName
                    $fontFilePath = $fontFile.FullName
                    Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Processing"

                    # Check if font is supported
                    $fontExtension = $fontFile.Extension.ToLower()
                    $supportedFont = $script:SupportedFonts | Where-Object { $_.Extension -eq $fontExtension }
                    if (-not $supportedFont) {
                        Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Font type [$fontExtension] is not supported. Skipping."
                        continue
                    }

                    $folderExists = Test-Path -Path $fontDestinationFolderPath -ErrorAction SilentlyContinue
                    if (-not $folderExists) {
                        Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Creating folder [$fontDestinationFolderPath]"
                        $null = New-Item -Path $fontDestinationFolderPath -ItemType Directory -Force
                    }
                    $fontDestinationFilePath = Join-Path -Path $fontDestinationFolderPath -ChildPath $fontFileName
                    $fontFileAlreadyInstalled = Test-Path -Path $fontDestinationFilePath
                    if ($fontFileAlreadyInstalled) {
                        if ($Force) {
                            Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Already installed. Forcing install."
                        } else {
                            Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Already installed. Skipping."
                            continue
                        }
                    }

                    Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Installing font"

                    $retryCount = 0
                    $fileCopied = $false

                    do {
                        try {
                            $null = $fontFile.CopyTo($fontDestinationFilePath)
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
                    if ($script:OS -eq 'Windows') {
                        $fontType = $script:SupportedFonts | Where-Object { $_.Extension -eq $fontExtension } | Select-Object -ExpandProperty Type
                        $registeredFontName = "$fontName ($fontType)"
                        Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Registering font as [$registeredFontName]"
                        $regValue = if ('AllUsers' -eq $Scope) { $fontFileName } else { $fontDestinationFilePath }
                        $params = @{
                            Name         = $registeredFontName
                            Path         = $script:FontRegPathMap[$scopeName]
                            PropertyType = 'string'
                            Value        = $regValue
                            Force        = $true
                            ErrorAction  = 'Stop'
                        }
                        $null = New-ItemProperty @params
                    }
                    Write-Verbose "[$functionName] - [$scopeName] - [$fontFilePath] - Done"
                }
                if ($item.PSIsContainer) {
                    Write-Verbose "[$functionName] - [$scopeName] - [$PathItem] - Done"
                }
            }
            Write-Verbose "[$functionName] - [$scopeName] - Done"
        }
    }

    end {
        if ($IsLinux) {
            if ($Verbose) {
                Write-Verbose 'Refreshing font cache'
                fc-cache -fv
            } else {
                fc-cache -f
            }
        }
        Write-Verbose "[$functionName] - Done"
    }
}
