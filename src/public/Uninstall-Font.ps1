#Requires -Modules Admin, DynamicParams

function Uninstall-Font {
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
    [Alias('Uninstall-Fonts')]
    [CmdletBinding()]
    param (
        # Scope of the font to uninstall.
        # CurrentUser will uninstall the font for the current user.
        # AllUsers will uninstall the font so it is removed for all users.
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Scope[]] $Scope = 'CurrentUser'
    )

    DynamicParam {
        $paramDictionary = New-DynamicParamDictionary

        $dynName = @{
            Name                            = 'Name'
            Type                            = [string[]]
            Alias                           = @('FontName', 'Font')
            Mandatory                       = $true
            HelpMessage                     = 'Name of the font to uninstall.'
            ValueFromPipeline               = $true
            ValueFromPipelineByPropertyName = $true
            ValidationErrorMessage          = "The font name provided was not found in the selected scope [$Scope]."
            ValidateSet                     = if ([string]::IsNullOrEmpty($Scope)) {
                (Get-Font -Scope 'CurrentUser' -Verbose:$false).Name
            } else {
                (Get-Font -Scope $Scope -Verbose:$false).Name
            }
            DynamicParamDictionary          = $paramDictionary
        }
        New-DynamicParam @dynName

        return $paramDictionary
    }

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
        $Name = $PSBoundParameters['Name']

        $scopeCount = $Scope.Count
        Write-Verbose "[$functionName] - Processing [$scopeCount] scopes(s)"
        foreach ($scopeItem in $Scope) {
            $scopeName = $scopeItem.ToString()

            $nameCount = $Name.Count
            Write-Verbose "[$functionName] - [$scopeName] - Processing [$nameCount] font(s)"
            foreach ($fontName in $Name) {
                Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Processing"
                $font = Get-Font -Name $fontName -Scope $Scope
                Write-Verbose ($font | Out-String) -Verbose
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
                            # Common error; 'file in use'. Usually VSCode or any web browser.
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
                    $key = $keys.PSObject.Properties | Where-Object { $_.Value -eq $filePath } | Select-Object -ExpandProperty Name
                    if (-not $key) {
                        Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Font is not registered. Skipping."
                    } else {
                        Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Unregistering font"
                        $key | Remove-ItemProperty -Force -ErrorAction Stop
                    }
                }
                Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Done"
            }
            Write-Verbose "[$functionName] - [$scopeName] - Done"
        }
    }

    end {
        Write-Verbose "[$functionName] - Done"
    }
}
