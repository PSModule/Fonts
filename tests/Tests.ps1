﻿$Path = 'C:\Users\AD08640\Downloads\Hack\HackNerdFont-Regular.ttf'
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

Get-Font -Name 'Casc*'
Get-Font -Name 'Casc*' | Uninstall-Font -Verbose

Get-Font -Name 'Casc*' -Scope AllUsers
Get-Font -Name 'Casc*' -Scope AllUsers | Uninstall-Font -Verbose

Get-Font -Name 'Hack Nerd Font*'
Get-Font -Name 'Hack Nerd Font*' | Uninstall-Font -Verbose

Get-Font -Name 'Hack Nerd Font*' -Scope AllUsers
Get-Font -Name 'Hack Nerd Font*' -Scope AllUsers | Uninstall-Font -Verbose

Get-Font
Get-Font | Uninstall-Font -Verbose

Get-Font -Scope AllUsers
Get-Font -Scope AllUsers | Uninstall-Font -Verbose