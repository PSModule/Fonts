Register-ArgumentCompleter -CommandName 'Uninstall-Font', 'Get-Font' -ParameterName 'Name' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters
    $scope = if ([string]::IsNullOrEmpty($fakeBoundParameters['Scope'])) {
        'CurrentUser'
    } else {
        $fakeBoundParameters['Scope']
    }
    (Get-Font -Scope $scope).Name | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
