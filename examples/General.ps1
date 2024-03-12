<#
  .SYNOPSIS
    This is a general example of how to use the module.
#>

# Import the module
Import-Module -Name 'PSModule'

# Define the path to the font file
$FontFilePath = 'C:\Fonts\CodeNewRoman\CodeNewRomanNerdFontPropo-Regular.tff'

# Install the font
Install-Font -Path $FontFilePath -Verbose

# List installed fonts
Get-Font -Name 'CodeNewRomanNerdFontPropo-Regular'

# Uninstall the font
Get-Font -Name 'CodeNewRomanNerdFontPropo-Regular' | Uninstall-Font -Verbose
