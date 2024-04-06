function Uninstall-FontNameCompleter {
    <#
        .SYNOPSIS
        Argument completer for the Uninstall-Font cmdlet
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSReviewUnusedParameter', '', Scope = 'Function',
        Justification = 'AutoCompleter function requires all parameters to be present.'
    )]
    param(
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    $possibleValues = if ([string]::IsNullOrEmpty($fakeBoundParameters['Scope'])) {
        (Get-Font -Scope 'CurrentUser').Name | ForEach-Object { $_ }
    } else {
        (Get-Font -Scope $fakeBoundParameters.Scope).Name | ForEach-Object { $_ }
    }

    $possibleValues | Where-Object {
        $_ -like "$wordToComplete*"
    }
}
