#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '6.1.0'; MaximumVersion = '6.*' }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Required for Pester tests'
)]
[CmdletBinding()]
param()

Describe 'Fonts' {
    Context 'Function: Get-Font' {
        It 'The function should be available' {
            Get-Command -Name 'Get-Font' | Should-NotBeNull
        }

        Context 'CurrentUser' {
            It 'Should return a list of fonts' {
                $fonts = Get-Font -Verbose
                Write-Verbose ($fonts | Out-String) -Verbose
            }
        }

        Context 'AllUsers' {
            It 'Should return a list of fonts' {
                $fonts = Get-Font -Scope AllUsers -Verbose
                Write-Verbose ($fonts | Out-String) -Verbose
            }
        }

        It 'Should return matching fonts from the configured folder' {
            $fontFolderPath = Join-Path -Path $TestDrive -ChildPath 'Get-Font'
            $null = New-Item -Path $fontFolderPath -ItemType Directory
            [System.IO.File]::WriteAllText((Join-Path -Path $fontFolderPath -ChildPath 'Alpha-Regular.ttf'), 'alpha')
            [System.IO.File]::WriteAllText((Join-Path -Path $fontFolderPath -ChildPath 'Beta-Bold.otf'), 'beta')

            InModuleScope Fonts -Parameters @{
                FontFolderPath = $fontFolderPath
            } {
                param($FontFolderPath)

                $originalOS = $script:OS
                $originalFontFolderPath = $script:FontFolderPathMap['MacOS']['CurrentUser']
                try {
                    $script:OS = 'MacOS'
                    $script:FontFolderPathMap['MacOS']['CurrentUser'] = $FontFolderPath

                    $fonts = @(Get-Font -Name 'Alpha*', 'Beta*')

                    $fonts.Count | Should-Be 2
                    @($fonts.Name | Sort-Object) | Should-BeCollection @('Alpha-Regular', 'Beta-Bold')
                    @($fonts.Scope) | Should-BeCollection @('CurrentUser', 'CurrentUser')
                } finally {
                    $script:FontFolderPathMap['MacOS']['CurrentUser'] = $originalFontFolderPath
                    $script:OS = $originalOS
                }
            }
        }

        It 'Should return no fonts when the configured folder does not exist' {
            $fontFolderPath = Join-Path -Path $TestDrive -ChildPath 'Missing'

            InModuleScope Fonts -Parameters @{
                FontFolderPath = $fontFolderPath
            } {
                param($FontFolderPath)

                $originalOS = $script:OS
                $originalFontFolderPath = $script:FontFolderPathMap['MacOS']['CurrentUser']
                try {
                    $script:OS = 'MacOS'
                    $script:FontFolderPathMap['MacOS']['CurrentUser'] = $FontFolderPath

                    @(Get-Font).Count | Should-Be 0
                } finally {
                    $script:FontFolderPathMap['MacOS']['CurrentUser'] = $originalFontFolderPath
                    $script:OS = $originalOS
                }
            }
        }
    }

    Context 'Function: Install-Font' {
        It 'Should be available' {
            Get-Command -Name 'Install-Font' | Should-NotBeNull
        }
        It 'Should install a font' {
            $fontPath = Join-Path -Path $PSScriptRoot -ChildPath 'Fonts/CascadiaCodePL.ttf'
            Install-Font -Path $fontPath -Verbose
            Write-Verbose "Installed font: 'CascadiaCodePL'" -Verbose
            Write-Verbose (Get-Font | Out-String) -Verbose
        }

        It 'Should overwrite an existing font when Force is specified' {
            $fontPath = Join-Path -Path $PSScriptRoot -ChildPath 'Fonts/CascadiaCodePL.ttf'
            $fontFolderPath = Join-Path -Path $TestDrive -ChildPath 'Fonts'

            InModuleScope Fonts -Parameters @{
                FontFolderPath = $fontFolderPath
                FontPath       = $fontPath
            } {
                param($FontFolderPath, $FontPath)

                $originalFontFolderPath = $script:FontFolderPathMap[$script:OS]['CurrentUser']
                try {
                    $script:FontFolderPathMap[$script:OS]['CurrentUser'] = $FontFolderPath
                    Mock -CommandName New-ItemProperty
                    Mock -CommandName Start-Sleep
                    if ($IsLinux) {
                        Mock -CommandName fc-cache
                    }

                    Install-Font -Path $FontPath -ErrorAction Stop
                    $installedFontPath = Join-Path -Path $FontFolderPath -ChildPath 'CascadiaCodePL.ttf'
                    [System.IO.File]::WriteAllText($installedFontPath, 'stale font data')

                    Install-Font -Path $FontPath -Force -ErrorAction Stop

                    $expectedHash = (Get-FileHash -LiteralPath $FontPath).Hash
                    $actualHash = (Get-FileHash -LiteralPath $installedFontPath).Hash
                    $actualHash | Should-Be $expectedHash
                } finally {
                    $script:FontFolderPathMap[$script:OS]['CurrentUser'] = $originalFontFolderPath
                }
            }
        }

        It 'Should install supported fonts recursively and skip unsupported files' {
            $fontPath = Join-Path -Path $PSScriptRoot -ChildPath 'Fonts/CascadiaCodePL.ttf'
            $sourceFolderPath = Join-Path -Path $TestDrive -ChildPath 'Install-Source'
            $nestedFolderPath = Join-Path -Path $sourceFolderPath -ChildPath 'Nested'
            $fontFolderPath = Join-Path -Path $TestDrive -ChildPath 'Install-Destination'
            $null = New-Item -Path $nestedFolderPath -ItemType Directory -Force
            Copy-Item -LiteralPath $fontPath -Destination (Join-Path -Path $sourceFolderPath -ChildPath 'Alpha.ttf')
            Copy-Item -LiteralPath $fontPath -Destination (Join-Path -Path $nestedFolderPath -ChildPath 'Beta.otf')
            [System.IO.File]::WriteAllText((Join-Path -Path $sourceFolderPath -ChildPath 'Readme.txt'), 'not a font')

            InModuleScope Fonts -Parameters @{
                FontFolderPath   = $fontFolderPath
                SourceFolderPath = $sourceFolderPath
            } {
                param($FontFolderPath, $SourceFolderPath)

                $originalOS = $script:OS
                $originalFontFolderPath = $script:FontFolderPathMap['MacOS']['CurrentUser']
                try {
                    $script:OS = 'MacOS'
                    $script:FontFolderPathMap['MacOS']['CurrentUser'] = $FontFolderPath

                    Install-Font -Path $SourceFolderPath -Recurse -ErrorAction Stop

                    Test-Path -LiteralPath (Join-Path -Path $FontFolderPath -ChildPath 'Alpha.ttf') | Should-BeTrue
                    Test-Path -LiteralPath (Join-Path -Path $FontFolderPath -ChildPath 'Beta.otf') | Should-BeTrue
                    Test-Path -LiteralPath (Join-Path -Path $FontFolderPath -ChildPath 'Readme.txt') | Should-BeFalse

                    $installedFontPath = Join-Path -Path $FontFolderPath -ChildPath 'Alpha.ttf'
                    [System.IO.File]::WriteAllText($installedFontPath, 'installed font remains unchanged')
                    Install-Font -Path (Join-Path -Path $SourceFolderPath -ChildPath 'Alpha.ttf') -ErrorAction Stop
                    [System.IO.File]::ReadAllText($installedFontPath) | Should-Be 'installed font remains unchanged'
                } finally {
                    $script:FontFolderPathMap['MacOS']['CurrentUser'] = $originalFontFolderPath
                    $script:OS = $originalOS
                }
            }
        }

        It 'Should report a missing source path' {
            $missingFontPath = Join-Path -Path $TestDrive -ChildPath 'Missing.ttf'
            $fontFolderPath = Join-Path -Path $TestDrive -ChildPath 'Missing-Destination'

            InModuleScope Fonts -Parameters @{
                FontFolderPath  = $fontFolderPath
                MissingFontPath = $missingFontPath
            } {
                param($FontFolderPath, $MissingFontPath)

                $originalOS = $script:OS
                $originalFontFolderPath = $script:FontFolderPathMap['MacOS']['CurrentUser']
                try {
                    $script:OS = 'MacOS'
                    $script:FontFolderPathMap['MacOS']['CurrentUser'] = $FontFolderPath
                    $errors = [System.Collections.Generic.List[object]]::new()

                    Install-Font -Path $MissingFontPath -ErrorAction SilentlyContinue -ErrorVariable '+errors'

                    $errors.Count | Should-Be 1
                    $errors[0].ToString() | Should-BeLikeString '*Path not found*'
                } finally {
                    $script:FontFolderPathMap['MacOS']['CurrentUser'] = $originalFontFolderPath
                    $script:OS = $originalOS
                }
            }
        }

        It 'Should reject an all-users install without administrator rights' {
            $fontPath = Join-Path -Path $PSScriptRoot -ChildPath 'Fonts/CascadiaCodePL.ttf'

            InModuleScope Fonts -Parameters @{
                FontPath = $fontPath
            } {
                param($FontPath)

                Mock -CommandName IsAdmin -MockWith { $false }
                $errorRecord = $null
                try {
                    Install-Font -Path $FontPath -Scope AllUsers -ErrorAction Stop
                } catch {
                    $errorRecord = $_
                }

                $errorRecord | Should-NotBeNull
                $errorRecord.Exception.Message | Should-BeLikeString '*Administrator rights are required*'
                $errorRecord.Exception.Message |
                    Should-BeLikeString "*$($script:FontFolderPathMap[$script:OS]['AllUsers'])*"
            }
        }

        It "Should return the installed font 'CascadiaCodePL'" {
            $font = Get-Font -Name 'CascadiaCodePL'
            Write-Verbose ($font | Out-String) -Verbose
            $font | Should-NotBeNull
        }
    }

    Context 'Function: Uninstall-Font' {
        It 'Should be available' {
            Get-Command -Name 'Uninstall-Font' | Should-NotBeNull
        }
        It 'Should uninstall a font' {
            Uninstall-Font -Name 'CascadiaCodePL' -Verbose
        }
        It 'Should NOT return the uninstalled font' {
            $font = Get-Font -Name 'CascadiaCodePL'
            Write-Verbose ($font | Out-String) -Verbose
            $font | Should-BeNull
        }

        It 'Should retry a file removal that initially fails' {
            $fontFolderPath = Join-Path -Path $TestDrive -ChildPath 'Uninstall-Retry'
            $null = New-Item -Path $fontFolderPath -ItemType Directory
            $installedFontPath = Join-Path -Path $fontFolderPath -ChildPath 'RetryFont.ttf'
            [System.IO.File]::WriteAllText($installedFontPath, 'font')

            InModuleScope Fonts -Parameters @{
                FontFolderPath = $fontFolderPath
            } {
                param($FontFolderPath)

                $originalOS = $script:OS
                $originalFontFolderPath = $script:FontFolderPathMap['MacOS']['CurrentUser']
                try {
                    $script:OS = 'MacOS'
                    $script:FontFolderPathMap['MacOS']['CurrentUser'] = $FontFolderPath
                    $script:removeAttemptCount = 0
                    Mock -CommandName Start-Sleep
                    Mock -CommandName Remove-Item -MockWith {
                        param($Path)

                        $script:removeAttemptCount++
                        if ($script:removeAttemptCount -eq 1) {
                            throw 'Font file is locked.'
                        }
                        [System.IO.File]::Delete($Path)
                    }

                    Uninstall-Font -Name 'RetryFont' -ErrorAction Stop

                    $script:removeAttemptCount | Should-Be 2
                    Should-Invoke -CommandName Start-Sleep -Times 1 -Exactly
                    Test-Path -LiteralPath (Join-Path -Path $FontFolderPath -ChildPath 'RetryFont.ttf') | Should-BeFalse
                } finally {
                    $script:FontFolderPathMap['MacOS']['CurrentUser'] = $originalFontFolderPath
                    $script:OS = $originalOS
                }
            }
        }

        It 'Should warn when an installed font file is already missing' {
            $missingFontPath = Join-Path -Path $TestDrive -ChildPath 'AlreadyMissing.ttf'

            InModuleScope Fonts -Parameters @{
                MissingFontPath = $missingFontPath
            } {
                param($MissingFontPath)

                $originalOS = $script:OS
                try {
                    $script:OS = 'MacOS'
                    $script:missingFontPathForTest = $MissingFontPath
                    Mock -CommandName Get-Font -MockWith {
                        [PSCustomObject]@{
                            Name  = 'AlreadyMissing'
                            Path  = $script:missingFontPathForTest
                            Scope = 'CurrentUser'
                        }
                    }
                    $warnings = [System.Collections.Generic.List[object]]::new()

                    Uninstall-Font -Name 'AlreadyMissing' -WarningVariable '+warnings'

                    $warnings.Count | Should-Be 1
                    $warnings[0].ToString() | Should-BeLikeString '*does not exist*'
                } finally {
                    Remove-Variable -Name missingFontPathForTest -Scope Script
                    $script:OS = $originalOS
                }
            }
        }

        It 'Should reject an all-users uninstall without administrator rights' {
            InModuleScope Fonts {
                Mock -CommandName IsAdmin -MockWith { $false }
                $errorRecord = $null
                try {
                    Uninstall-Font -Name 'CascadiaCodePL' -Scope AllUsers -ErrorAction Stop
                } catch {
                    $errorRecord = $_
                }

                $errorRecord | Should-NotBeNull
                $errorRecord.Exception.Message | Should-BeLikeString '*Administrator rights are required*'
                $errorRecord.Exception.Message |
                    Should-BeLikeString "*$($script:FontFolderPathMap[$script:OS]['AllUsers'])*"
            }
        }

        It 'Should install and uninstall a font based on wildcard' {
            $fontPath = Join-Path -Path $PSScriptRoot -ChildPath 'Fonts/CascadiaCodePL.ttf'
            Install-Font -Path $fontPath -Verbose
            Write-Verbose "Installed font: 'CascadiaCodePL'" -Verbose
            Write-Verbose (Get-Font | Out-String) -Verbose
            Uninstall-Font -Name 'CascadiaCode*' -Verbose
            $font = Get-Font -Name 'CascadiaCodePL'
            Write-Verbose ($font | Out-String) -Verbose
            $font | Should-BeNull
        }
    }
}
