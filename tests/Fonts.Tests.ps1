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
