function Uninstall-FontCompleter {
    <#
        .SYNOPSIS
        Argument completer for the Uninstall-Font cmdlet
    #>
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
