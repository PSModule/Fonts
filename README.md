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

Use the module to list, install, and uninstall fonts on your system.

### Example: List installed fonts

List all fonts installed in the current user context:

```powershell
Get-Font
```

List all fonts installed in the system context. On Windows this lists the fonts in the `C:\Windows\Fonts` folder:

```powershell
Get-Font -Scope AllUsers
```

### Example: Install a font

Install a font in the current user context. This installs the font in the user font folder and updates the
registry so it is available to the current user:

```powershell
Install-Font -Path 'C:\path\to\font.ttf'
```

Install a font for all users. This must run as an administrator, installs the font in the `C:\Windows\Fonts`
folder, and updates the registry so it is available to every user on the system:

```powershell
Install-Font -Path 'C:\path\to\font.ttf' -Scope AllUsers
```

### Example: Uninstall a font

Uninstall a font from the current user context. This removes the font from the user font folder and updates the
registry to remove it from the current user:

```powershell
Uninstall-Font -Name 'FontName'
```

Uninstall a font for all users. This must run as an administrator, removes the font from the `C:\Windows\Fonts`
folder, and updates the registry to remove it from every user on the system:

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
