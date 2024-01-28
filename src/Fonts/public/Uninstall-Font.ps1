#Requires -Modules Utilities

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
        $functionName = $MyInvocation.MyCommand.Name
        Write-Verbose "[$functionName]"

        if ($Scope -contains 'AllUsers' -and -not (IsAdmin)) {
            $errorMessage = @"
Administrator rights are required to uninstall fonts in [$($script:fontFolderPath['AllUsers'])].
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
        foreach ($ScopeItem in $Scope) {
            $scopeName = $scopeItem.ToString()
            $fontDestinationRegPath = $script:fontRegPath[$scopeName]

            $nameCount = $Name.Count
            Write-Verbose "[$functionName] - [$scopeName] - Processing [$nameCount] font(s)"
            foreach ($fontName in $Name) {
                Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Processing"
                $font = Get-Font -Name $fontName -Scope $Scope -Verbose:$false
                $filePath = $font.path

                $fileExists = Test-Path -Path $filePath
                if (-not $fileExists) {
                    Write-Warning "[$fontName] - File [$filePath] does not exist. Skipping."
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

                $fontRegistryPathExists = Get-ItemProperty -Path $fontDestinationRegPath -Name $fontName -ErrorAction SilentlyContinue
                if (-not $fontRegistryPathExists) {
                    Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Font is not registered. Skipping."
                } else {
                    Write-Verbose "[$functionName] - [$scopeName] - [$fontName] - Unregistering font with path [$fontDestinationRegPath]"
                    Remove-ItemProperty -Path $fontDestinationRegPath -Name $fontName -Force -ErrorAction Stop
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
