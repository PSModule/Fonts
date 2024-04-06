function Uninstall-FontCompleter {
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

    if ([string]::IsNullOrEmpty($fakeBoundParameters.Scope)) {
        (Get-Font -Scope 'CurrentUser' -Verbose:$false).Name | ForEach-Object { $_ }
    } else {
        (Get-Font -Scope $fakeBoundParameters.Scope -Verbose:$false).Name | ForEach-Object { $_ }
    }
}
