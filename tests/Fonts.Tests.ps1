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

    Context 'Install-Font' {
        It 'Install a font for current user' {
            $fontFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'fonts/CascadiaCodePL.ttf'
            Install-Font -Path $fontFilePath | Should -Not -Throw
        }

        It 'Install a font for all users' {
            $fontFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'fonts/CascadiaCodePL.ttf'
            Install-Font -Path $fontFilePath -Scope 'AllUsers' | Should -Not -Throw
        }

        It 'Install fonts in a folder for current user' {
            $fontsFolderPath = Join-Path -Path $PSScriptRoot -ChildPath 'fonts'
            Install-Font -Path $fontsFolderPath -Recurse | Should -Not -Throw
        }

        It 'Install fonts in a folder for all users' {
            $fontsFolderPath = Join-Path -Path $PSScriptRoot -ChildPath 'fonts'
            Install-Font -Path $fontsFolderPath -Recurse -Scope 'AllUsers' | Should -Not -Throw
        }

        It 'Install fonts in a folder for all users (forcefully)' {
            $fontsFolderPath = Join-Path -Path $PSScriptRoot -ChildPath 'fonts'
            Install-Font -Path $fontsFolderPath -Recurse -Scope 'AllUsers' -Force | Should -Not -Throw
        }
    }
}
