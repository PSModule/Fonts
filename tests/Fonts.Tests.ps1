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
        It 'The function should return a list of fonts' {
            { Get-Font -Verbose } | Should -Not -Throw
        }

        It 'The function should return a list of fonts for all users' {
            { Get-Font -Scope AllUsers -Verbose } | Should -Not -Throw
        }

        It 'The function should return a list of fonts for the current user' {
            { Get-Font -Scope CurrentUser -Verbose } | Should -Not -Throw
        }
    }

    # Context 'Function: Install-Font' {
    #     It 'The function should be available' {
    #         Get-Command -Name 'Install-Font' | Should -Not -BeNull
    #     }
    #     It 'The function should install a font' {
    #         $fontPath = Join-Path -Path $PSScriptRoot -ChildPath 'Fonts/CascadiaCodePL.ttf'
    #         { Install-Font -Path $fontPath -Verbose } | Should -Not -Throw
    #     }
    #     It 'Getting the font should return the installed font' {
    #         Write-Verbose (Get-Font | Out-String) -Verbose
    #         { Get-Font } | Should -Not -Throw
    #     }
    # }

    # Context 'Function: Uninstall-Font' {
    #     It 'The function should be available' {
    #         Get-Command -Name 'Uninstall-Font' | Should -Not -BeNull
    #     }
    #     It 'The function should uninstall a font' {
    #         { Uninstall-Font -Name 'Cascadia Code PL' -Scope AllUsers -Verbose } | Should -Not -Throw
    #     }
    # }
}
