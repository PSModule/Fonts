function Uninstall-Font {
    <#
        .SYNOPSIS
        Uninstalls a font from the system.

        .DESCRIPTION
        Uninstalls a font from the system. The function supports removing fonts for either the current user
        or all users. If attempting to remove a font for all users, administrative privileges are required.
        The function ensures font files are deleted, and if on Windows, it also unregisters fonts from the registry.

        .EXAMPLE
        Uninstall-Font -Name 'Courier New'

        Output:
        ```powershell
        VERBOSE: [Uninstall-Font] - [CurrentUser] - [Courier New] - Processing
        VERBOSE: [Uninstall-Font] - [CurrentUser] - [Courier New] - Removing file [C:\Windows\Fonts\cour.ttf]
        VERBOSE: [Uninstall-Font] - [CurrentUser] - [Courier New] - Unregistering font [Courier New]
        VERBOSE: [Uninstall-Font] - [CurrentUser] - [Courier New] - Done
        ```

        Uninstalls the 'Courier New' font from the system for the current user.

        .EXAMPLE
        Uninstall-Font -Name 'Courier New' -Scope AllUsers

        Output:
        ```powershell
        VERBOSE: [Uninstall-Font] - [AllUsers] - [Courier New] - Processing
        VERBOSE: [Uninstall-Font] - [AllUsers] - [Courier New] - Removing file [C:\Windows\Fonts\cour.ttf]
        VERBOSE: [Uninstall-Font] - [AllUsers] - [Courier New] - Unregistering font [Courier New]
        VERBOSE: [Uninstall-Font] - [AllUsers] - [Courier New] - Done
        ```

        Uninstalls the 'Courier New' font from the system for all users. Requires administrative privileges.

        .OUTPUTS
        None

        .NOTES
        The function does not return any objects.

        .LINK
        https://psmodule.io/Admin/Functions/Uninstall-Font/
    #>
    [Alias('Uninstall-Fonts')]
    [CmdletBinding()]
    param (
        # Name of the font to uninstall.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [SupportsWildcards()]
        [string[]] $Name,

        # Scope of the font to uninstall.
        # CurrentUser will uninstall the font for the current user.
        # AllUsers will uninstall the font so it is removed for all users.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string[]] $Scope = 'CurrentUser'
    )

    begin {
        $functionName = $MyInvocation.MyCommand.Name
        Write-Verbose "[$functionName]"

        if ($Scope -contains 'AllUsers' -and -not (IsAdmin)) {
            $errorMessage = @"
Administrator rights are required to uninstall fonts in [$($script:FontFolderPath['AllUsers'])].
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
            $nameCount = $Name.Count
            Write-Verbose "[$functionName] - [$scopeName] - Processing [$nameCount] font(s)"
            foreach ($fontName in $Name) {
                Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Processing"
                $fonts = Get-Font -Name $fontName -Scope $Scope
                Write-Verbose ($fonts | Out-String)
                foreach ($font in $fonts) {

                    $filePath = $font.Path

                    $fileExists = Test-Path -Path $filePath -ErrorAction SilentlyContinue
                    if (-not $fileExists) {
                        Write-Warning "[$functionName] - [$scopeName] - [$fontName] - File [$filePath] does not exist. Skipping."
                    } else {
                        Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Removing file [$filePath]"
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
                                    Write-Error "Failed [$retryCount/$maxRetries] - Stopping"
                                    break
                                }
                                Write-Verbose $_
                                Write-Verbose "Failed [$retryCount/$maxRetries] - Retrying in $retryIntervalSeconds seconds..."
                                #TODO: Find a way to try to unlock file here.
                                Start-Sleep -Seconds $retryIntervalSeconds
                            }
                        } while (-not $fileRemoved -and $retryCount -lt $maxRetries)

                        if (-not $fileRemoved) {
                            break  # Break to skip unregistering the font if the file could not be removed.
                        }
                    }

                    if ($script:OS -eq 'Windows') {
                        Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Searching for font in registry"
                        $keys = Get-ItemProperty -Path $script:FontRegPathMap[$scopeName]
                        $key = $keys.PSObject.Properties | Where-Object { $_.Value -eq $filePath }
                        if (-not $key) {
                            Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Font is not registered. Skipping."
                        } else {
                            $keyName = $key.Name
                            Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Unregistering font [$keyName]"
                            Remove-ItemProperty -Path $script:FontRegPathMap[$scopeName] -Name $keyName -Force -ErrorAction Stop
                        }
                    }
                    Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Done"
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
