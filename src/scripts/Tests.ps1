function Get-FileDetails {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $shell = New-Object -ComObject Shell.Application
    $shellFolder = $shell.Namespace($FontFile.Directory.FullName)
    $shellFile = $shellFolder.ParseName($FontFile.name)

    $fileDetails = New-Object pscustomobject

    foreach ($i in 0..1000) {
        $propertyName = $shellfolder.GetDetailsOf($null, $i)
        $propertyValue = $shellfolder.GetDetailsOf($shellfile, $i)
        if (-not [string]::IsNullOrEmpty($propertyValue)) {
            Write-Verbose "[$propertyName] - [$propertyValue]"
            $fileDetails | Add-Member -MemberType NoteProperty -Name $propertyName -Value $propertyValue
        }
    }
    return $fileDetails
}


$Path = 'C:\Users\AD08640\Downloads\Hack\HackNerdFont-Regular.ttf'
Install-Font -Path $Path -Verbose
Install-Font -Path $Path -Verbose -Scope AllUsers -Force
Install-Font -Path $Path -Verbose -Force

$Path | Install-Font -Verbose
$Path | Install-Font -Verbose -Force

$FontFile = Get-Item -Path $Path
Install-Font -Path $FontFile -Verbose
Install-Font -Path $FontFile -Verbose -Force

$FontFile | Install-Font -Verbose
$FontFile | Install-Font -Verbose -Force

$Files = Get-ChildItem -Path 'C:\Users\AD08640\Downloads\Hack\'
$Files | Install-Font -Verbose
$Files | Install-Font -Verbose -Force
$Files | Install-Font -Verbose -Scope AllUsers
$Files | Install-Font -Verbose -Scope AllUsers -Force


'C:\Users\AD08640\Downloads\CascadiaCode-2111\ttf\' | Install-Font -Verbose
'C:\Users\AD08640\Downloads\CascadiaCode-2111\ttf\' | Install-Font -Verbose -Force
'C:\Users\AD08640\Downloads\CascadiaCode-2111\ttf\' | Install-Font -Verbose -Scope AllUsers
'C:\Users\AD08640\Downloads\CascadiaCode-2111\ttf\' | Install-Font -Verbose -Scope AllUsers -Force

Get-InstalledFont -Name 'Casc*'
Get-InstalledFont -Name 'Casc*' | Uninstall-Font -Verbose

Get-InstalledFont -Name 'Casc*' -Scope AllUsers
Get-InstalledFont -Name 'Casc*' -Scope AllUsers | Uninstall-Font -Verbose

Get-InstalledFont -Name 'Hack Nerd Font*'
Get-InstalledFont -Name 'Hack Nerd Font*' | Uninstall-Font -Verbose

Get-InstalledFont -Name 'Hack Nerd Font*' -Scope AllUsers
Get-InstalledFont -Name 'Hack Nerd Font*' -Scope AllUsers | Uninstall-Font -Verbose

Get-InstalledFont
Get-InstalledFont | Uninstall-Font -Verbose

Get-InstalledFont -Scope AllUsers
Get-InstalledFont -Scope AllUsers | Uninstall-Font -Verbose
