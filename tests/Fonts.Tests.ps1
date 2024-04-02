[CmdletBinding()]
Param(
    # Path to the module to test.
    [Parameter()]
    [string] $Path
)

Write-Verbose "Path to the module: [$Path]" -Verbose

Describe 'Fonts' {
    Context 'Module' {
        It 'The module should be available' {
            Get-Module -Name 'Fonts' -ListAvailable | Should -Not -BeNullOrEmpty
            Write-Verbose (Get-Module -Name 'Fonts' -ListAvailable | Out-String) -Verbose
        }
        It 'The module should be imported' {
            { Import-Module -Name 'Fonts' -Verbose -RequiredVersion 999.0.0 -Force } | Should -Not -Throw
        }
    }

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
        }
        It 'Should return the installed fonts' {
            {
                $fonts = Get-Font
                Write-Verbose ($fonts | Out-String) -Verbose
            } | Should -Not -Throw
        }
    }

    # Context 'Function: Uninstall-Font' {
    #     It 'The function should be available' {
    #         Get-Command -Name 'Uninstall-Font' | Should -Not -BeNull
    #     }
    #     It 'The function should uninstall a font' {
    #         { Uninstall-Font -Name 'Cascadia Code PL' -Scope AllUsers -Verbose } | Should -Not -Throw
    #     }
    # }
}
