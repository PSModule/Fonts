Register-ArgumentCompleter -CommandName Uninstall-Font, Get-Font -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters
    if ([string]::IsNullOrEmpty($fakeBoundParameters['Scope'])) {
        Get-Font -Scope 'CurrentUser' | Where-Object { $_.Name -like "$wordToComplete*" } | Select-Object -ExpandProperty Name
    } else {
        Get-Font -Scope $fakeBoundParameters['Scope'] | Where-Object { $_.Name -like "$wordToComplete*" } | Select-Object -ExpandProperty Name
    }
}
