# Fonts

This is a PowerShell module for managing fonts.
It helps you to install, uninstall and list fonts on the system.

## Prerequisites

This module currently only supports Windows operating systems.

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

## Contributing

Coder or not, you can contribute to the project! We welcome all contributions.

### For Users

If you don't code, you still sit on valuable information that can make this project even better. If you experience that the
product does unexpected things, throw errors or is missing functionality, you can help by submitting bugs and feature requests.
Please see the issues tab on this project and submit a new issue that matches your needs.

### For Developers

If you do code, we'd love to have your contributions. Please read the [Contribution guidelines](CONTRIBUTING.md) for more information.
You can either help by picking up an existing issue or submit a new one if you have an idea for a new feature or improvement.
