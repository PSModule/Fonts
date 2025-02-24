@{
    RootModule            = 'Admin.psm1'
    ModuleVersion         = '999.0.0'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = '3b2c3c7d-13be-4fea-806a-d384ad5fd7b9'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module working with the admin role.'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = 'Test-Admin'
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @(
        'IsAdmin'
        'IsAdministrator'
        'Test-Administrator'
    )
    ModuleList            = @()
    FileList              = 'Admin.psm1'
    PrivateData           = @{
        PSData = @{
            Tags       = @(
                'isadmin'
                'Linux'
                'MacOS'
                'powershell'
                'powershell-module'
                'PSEdition_Core'
                'PSEdition_Desktop'
                'sudo'
                'Windows'
            )
            LicenseUri = 'https://github.com/PSModule/Admin/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/Admin'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/Admin/main/icon/icon.png'
        }
    }
}

