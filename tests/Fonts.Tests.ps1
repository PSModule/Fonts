[CmdletBinding()]
Param(
    # Path to the module to test.
    [Parameter()]
    [string] $Path
)

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
}
