$ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath scripts
Get-ChildItem -Path $ScriptPath -File |ForEach-Object {
    . $_.FullName
}

$DashboardParams = @{
    Title = 'Chocolatey'
    Content = {
        New-ChocolateySearchForm
        New-ChocolateyInstallForm
    }
}
New-UDDashboard @DashboardParams