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
