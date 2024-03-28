# $FontFolderPath = "C:\Users\marst\Downloads\Ubuntu"

$FontFilePath = 'C:\Users\marst\Downloads\CodeNewRoman\CodeNewRomanNerdFontPropo-Regular.otf'

# $FontFilePathList = @(
#     'C:\Users\marst\Downloads\CodeNewRoman\CodeNewRomanNerdFontPropo-Bold.otf',
#     'C:\Users\marst\Downloads\CodeNewRoman\CodeNewRomanNerdFontPropo-Italic.otf',
#     'C:\Users\marst\Downloads\CodeNewRoman\CodeNewRomanNerdFontPropo-Regular.otf'
# )

Install-Font -Path $FontFilePath -Verbose
Install-Font -Path $FontFilePath -Verbose -Scope CurrentUser -Force
Install-Font -Path $FontFilePath -Verbose -Force

$FontFilePath | Install-Font -Verbose
$FontFilePath | Install-Font -Verbose -Force

$FontFile = Get-Item -Path $FontFilePath
Install-Font -Path $FontFile -Verbose
Install-Font -Path $FontFile -Verbose -Force

$FontFile | Install-Font -Verbose
$FontFile | Install-Font -Verbose -Force

$Files = Get-ChildItem -Path "$env:USERPROFILE\Downloads\Hack\"
$Files | Install-Font -Verbose
$Files | Install-Font -Verbose -Force
$Files | Install-Font -Verbose -Scope AllUsers
$Files | Install-Font -Verbose -Scope AllUsers -Force


"$env:USERPROFILE\Downloads\CascadiaCode-2111\ttf\" | Install-Font -Verbose
"$env:USERPROFILE\Downloads\CascadiaCode-2111\ttf\" | Install-Font -Verbose -Force
"$env:USERPROFILE\Downloads\CascadiaCode-2111\ttf\" | Install-Font -Verbose -Scope AllUsers
"$env:USERPROFILE\Downloads\CascadiaCode-2111\ttf\" | Install-Font -Verbose -Scope AllUsers -Force


Get-Font -Name 'Casc*' -Verbose
Get-Font -Name 'Casc*', 'Hack Nerd Font*' -Verbose

Get-Font -Name 'Casc*', 'Ha*' -Scope AllUsers, CurrentUser -Verbose

'Casc*','Ha*' | Get-Font -Scope AllUsers, CurrentUser -Verbose


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
