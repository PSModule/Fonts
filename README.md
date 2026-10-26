# Fonts

This is a PowerShell module for managing fonts.
It helps you to install, uninstall and list fonts on the system.

This module only provides the functionality to manage fonts on the system. To install popular fonts on the system,
please review the [NerdFonts](https://github.com/PSModule/NerdFonts) and [GoogleFonts](https://github.com/PSModule/GoogleFonts) modules.

## Supported platforms

This module supports managing fonts on Linux, macOS and Windows operating systems.
The minimum PowerShell version is 5.1, including Windows PowerShell 5.1.

## Installation

To install the module simply run the following command in a PowerShell terminal.

```powershell
Install-PSResource -Name Fonts
Import-Module -Name Fonts
```

## Usage

You can use this module to install, uninstall and list fonts on your system.

### List installed fonts

This command will list all fonts installed in the user context.

```powershell
Get-Font
```

This command will list all fonts installed in the system context.
For Windows this means that it will list all fonts installed on the `C:\Windows\Fonts` folder.

```powershell
Get-Font -Scope AllUsers
```

### Install a font

To install a font in the user context, you can use the following command.
This will install the font in the users font folder `$env:LOCALAPPDATA\Microsoft\Windows\Fonts` and update the registry to
make it available to the current user.

```powershell
Install-Font -Path 'C:\path\to\font.ttf'
```

To install a font on the system you can use the following command. This will need to be run as an administrator.
This will install the font in the `C:\Windows\Fonts` folder and update the registry to make it available to all users on the system.

```powershell
Install-Font -Path 'C:\path\to\font.ttf' -Scope AllUsers
```

### Uninstall a font

To uninstall a font from the user context, you can use the following command.
This will remove the font from the users font folder `$env:LOCALAPPDATA\Microsoft\Windows\Fonts` and update the
registry to remove it from the current user.

```powershell
Uninstall-Font -Name 'FontName' # You can tab complete the font name
```

To uninstall a font from the system you can use the following command. This will need to be run as an administrator.
This will remove the font from the `C:\Windows\Fonts` folder and update the registry to remove it from all users on the system.

```powershell
Uninstall-Font -Name 'FontName' -Scope AllUsers # You can tab complete the font name
```

## Documentation

Documentation is published at [psmodule.io/Fonts](https://psmodule.io/Fonts/).
Use PowerShell help for command details and examples:

```powershell
Get-Command -Module Fonts
Get-Help -Name Install-Font -Examples
```
