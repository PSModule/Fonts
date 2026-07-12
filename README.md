# Fonts

Fonts is a PowerShell module for managing fonts. It helps you install, uninstall, and list fonts on the system.

This module only provides the functionality to manage fonts on the system. To install popular fonts, review the
[NerdFonts](https://github.com/PSModule/NerdFonts) and [GoogleFonts](https://github.com/PSModule/GoogleFonts) modules.

## Supported platforms

This module supports managing fonts on Linux, macOS, and Windows operating systems.

## Installation

Install the module from the PowerShell Gallery:

```powershell
Install-PSResource -Name Fonts
Import-Module -Name Fonts
```

## Usage

Use the module to list, install, and uninstall fonts on your system. Fonts are managed for the current user by
default; pass `-Scope AllUsers` to manage fonts for every user, which requires elevated privileges (administrator
on Windows, root on Linux and macOS). On Windows the module also registers or unregisters fonts in the Windows
registry so applications can find them; on Linux and macOS it manages the font files in the appropriate font
directories.

### Example: List installed fonts

List all fonts installed for the current user:

```powershell
Get-Font
```

List all fonts installed for all users:

```powershell
Get-Font -Scope AllUsers
```

### Example: Install a font

Install a font for the current user:

```powershell
Install-Font -Path ./MyFont.ttf
```

Install a font for all users (requires elevated privileges):

```powershell
Install-Font -Path ./MyFont.ttf -Scope AllUsers
```

### Example: Uninstall a font

Uninstall a font for the current user:

```powershell
Uninstall-Font -Name 'FontName'
```

Uninstall a font for all users (requires elevated privileges):

```powershell
Uninstall-Font -Name 'FontName' -Scope AllUsers
```

## Documentation

Documentation is published at [psmodule.io/Fonts](https://psmodule.io/Fonts/).

Use PowerShell help and command discovery for module details:

```powershell
Get-Command -Module Fonts
Get-Help -Name Install-Font -Examples
```
