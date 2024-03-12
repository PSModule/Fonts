Describe 'Fonts' {
    Context 'Module' {
        It 'The module should be available' {
            Get-Module -Name 'Fonts' -ListAvailable | Should -Not -BeNullOrEmpty
            Write-Verbose (Get-Module -Name 'Fonts' -ListAvailable | Out-String) -Verbose
        }
        It 'The module should be imported' {
            { Import-Module -Name 'Fonts' } | Should -Not -Throw
        }
    }
}
