#Requires -Modules @{ ModuleName = 'Admin'; RequiredVersion = '1.1.6' }

function Get-Font {
    <#
        .SYNOPSIS
        Retrieves the installed fonts.

        .DESCRIPTION
        Retrieves a list of installed fonts for the current user or all users, depending on the specified scope.
        Supports filtering by font name using wildcards.

        .EXAMPLE
        Get-Font

        Output:
        ```powershell
        Name     Path                             Scope
        ----     ----                             -----
        Arial    C:\Windows\Fonts\arial.ttf       CurrentUser
        ```

        Gets all the fonts installed for the current user.

        .EXAMPLE
        Get-Font -Name 'Arial*'

        Output:
        ```powershell
        Name       Path                                Scope
        ----       ----                                -----
        Arial      C:\Windows\Fonts\arial.ttf          CurrentUser
        Arial Bold C:\Windows\Fonts\arialbd.ttf        CurrentUser
        ```

        Gets all the fonts installed for the current user that start with 'Arial'.

        .EXAMPLE
        Get-Font -Scope 'AllUsers'

        Output:
        ```powershell
        Name      Path                               Scope
        ----      ----                               -----
        Calibri   C:\Windows\Fonts\calibri.ttf       AllUsers
        ```

        Gets all the fonts installed for all users.

        .EXAMPLE
        Get-Font -Name 'Calibri' -Scope 'AllUsers'

        Output:
        ```powershell
        Name     Path                               Scope
        ----     ----                               -----
        Calibri  C:\Windows\Fonts\calibri.ttf       AllUsers
        ```

        Gets the font with the name 'Calibri' for all users.

        .OUTPUTS
        System.Collections.Generic.List[PSCustomObject]

        .NOTES
        Returns a list of installed fonts.
        Each font object contains properties:
        - Name: The font name.
        - Path: The full file path to the font.
        - Scope: The scope from which the font is retrieved.

        .LINK
        https://psmodule.io/Fonts/Functions/Get-Font/
    #>
    [Alias('Get-Fonts')]
    [OutputType([System.Collections.Generic.List[PSCustomObject]])]
    [CmdletBinding()]
    param(
        # Specifies the name of the font to get.
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [SupportsWildcards()]
        [string[]] $Name = '*',

        # Specifies the scope of the font(s) to get.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string[]] $Scope = 'CurrentUser'
    )

    begin {
        $functionName = $MyInvocation.MyCommand.Name
        Write-Verbose "[$functionName]"
    }

    process {
        $scopeCount = $Scope.Count
        Write-Verbose "[$functionName] - Processing [$scopeCount] scope(s)"
        foreach ($scopeName in $Scope) {

            Write-Verbose "[$functionName] - [$scopeName] - Getting font(s)"
            $fontFolderPath = $script:FontFolderPathMap[$script:OS][$scopeName]
            Write-Verbose "[$functionName] - [$scopeName] - Font folder path: [$fontFolderPath]"
            $folderExists = Test-Path -Path $fontFolderPath
            Write-Verbose "[$functionName] - [$scopeName] - Folder exists: [$folderExists]"
            if (-not $folderExists) {
                return $fonts
            }
            $installedFonts = Get-ChildItem -Path $fontFolderPath -File
            $installedFontsCount = $($installedFonts.Count)
            Write-Verbose "[$functionName] - [$scopeName] - Filtering from [$installedFontsCount] font(s)"
            $nameCount = $Name.Count
            Write-Verbose "[$functionName] - [$scopeName] - Filtering based on [$nameCount] name pattern(s)"
            foreach ($fontFilter in $Name) {
                Write-Verbose "[$functionName] - [$scopeName] - [$fontFilter] - Filtering font(s)"
                $filteredFonts = $installedFonts | Where-Object { $_.BaseName -like $fontFilter }
                foreach ($fontItem in $filteredFonts) {
                    $fontName = $fontItem.BaseName
                    $fontPath = $fontItem.FullName
                    $fontScope = $scopeName
                    Write-Verbose "[$functionName] - [$scopeName] - [$fontFilter] - Found [$fontName] at [$fontPath]"

                    [PSCustomObject]@{
                        Name  = $fontName
                        Path  = $fontPath
                        Scope = $fontScope
                    }
                }
                Write-Verbose "[$functionName] - [$scopeName] - [$fontFilter] - Done"
            }
            Write-Verbose "[$functionName] - [$scopeName] - Done"
        }
    }

    end {}
}
