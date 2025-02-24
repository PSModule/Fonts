[CmdletBinding()]
param()
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
$script:PSModuleInfo = Test-ModuleManifest -Path "$PSScriptRoot\$baseName.psd1"
$script:PSModuleInfo | Format-List | Out-String -Stream | ForEach-Object { Write-Debug $_ }
$scriptName = $script:PSModuleInfo.Name
Write-Debug "[$scriptName] - Importing module"
#region    [functions] - [public]
Write-Debug "[$scriptName] - [functions] - [public] - Processing folder"
#region    [functions] - [public] - [Test-Admin]
Write-Debug "[$scriptName] - [functions] - [public] - [Test-Admin] - Importing"
function Test-Admin {
    <#
        .SYNOPSIS
        Test if the current context is running as a specified role.

        .EXAMPLE
        Test-Role

        Test if the current context is running as an Administrator.

        .LINK
        https://psmodule.io/Admin/Functions/Test-Admin/
    #>
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    [Alias('Test-Administrator', 'IsAdmin', 'IsAdministrator')]
    param()

    $IsUnix = $PSVersionTable.Platform -eq 'Unix'
    if ($IsUnix) {
        Write-Verbose "Running on Unix, checking if user is root."
        $whoAmI = $(whoami)
        Write-Verbose "whoami: $whoAmI"
        $IsRoot = $whoAmI -eq 'root'
        Write-Verbose "IsRoot: $IsRoot"
        $IsRoot
    } else {
        Write-Verbose "Running on Windows, checking if user is an Administrator."
        $user = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($user)
        $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        Write-Verbose "IsAdmin: $isAdmin"
        $isAdmin
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Test-Admin] - Done"
#endregion [functions] - [public] - [Test-Admin]
Write-Debug "[$scriptName] - [functions] - [public] - Done"
#endregion [functions] - [public]

#region    Member exporter
$exports = @{
    Alias    = '*'
    Cmdlet   = ''
    Function = 'Test-Admin'
    Variable = ''
}
Export-ModuleMember @exports
#endregion Member exporter

