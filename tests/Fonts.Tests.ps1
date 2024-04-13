[CmdletBinding()]
Param(
    # Path to the module to test.
    [Parameter()]
    [string] $Path
)

Write-Verbose "Path to the module: [$Path]" -Verbose

Describe 'Fonts' {
    Context 'Function: Get-Font' {
        It 'The function should be available' {
            Get-Command -Name 'Get-Font' | Should -Not -BeNull
        }

        Context 'CurrentUser' {
            It 'Should return a list of fonts' {
                {
                    $fonts = Get-Font -Verbose
                    Write-Verbose ($fonts | Out-String) -Verbose
                } | Should -Not -Throw
            }
        }

        Context 'AllUsers' {
            It 'Should return a list of fonts' {
                {
                    $fonts = Get-Font -Scope AllUsers -Verbose
                    Write-Verbose ($fonts | Out-String) -Verbose
                } | Should -Not -Throw
            }
        }
    }

    Context 'Function: Install-Font' {
        It 'Should be available' {
            Get-Command -Name 'Install-Font' | Should -Not -BeNull
        }
        It 'Should install a font' {
            $fontPath = Join-Path -Path $PSScriptRoot -ChildPath 'Fonts/CascadiaCodePL.ttf'
            { Install-Font -Path $fontPath -Verbose } | Should -Not -Throw
            Write-Verbose "Installed font: 'CascadiaCodePL'" -Verbose
            Write-Verbose (Get-Font | Out-String) -Verbose
        }
        It "Should return the installed font 'CascadiaCodePL'" {
            $font = Get-Font -Name 'CascadiaCodePL'
            Write-Verbose ($font | Out-String) -Verbose
            $font | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Function: Uninstall-Font' {
        It 'Should be available' {
            Get-Command -Name 'Uninstall-Font' | Should -Not -BeNull
        }
        It 'Should uninstall a font' {
            { Uninstall-Font -Name 'CascadiaCodePL' -Verbose } | Should -Not -Throw
        }
        It 'Should NOT return the uninstalled font' {
            $font = Get-Font -Name 'CascadiaCodePL'
            Write-Verbose ($font | Out-String) -Verbose
            $font | Should -BeNullOrEmpty
        }
        It 'Should install and uninstall a font based on wildcard' {
            $fontPath = Join-Path -Path $PSScriptRoot -ChildPath 'Fonts/CascadiaCodePL.ttf'
            { Install-Font -Path $fontPath -Verbose } | Should -Not -Throw
            Write-Verbose "Installed font: 'CascadiaCodePL'" -Verbose
            Write-Verbose (Get-Font | Out-String) -Verbose
            { Uninstall-Font -Name 'CascadiaCode*' -Verbose } | Should -Not -Throw
            $font = Get-Font -Name 'CascadiaCodePL'
            Write-Verbose ($font | Out-String) -Verbose
            $font | Should -BeNullOrEmpty
        }
    }
}
