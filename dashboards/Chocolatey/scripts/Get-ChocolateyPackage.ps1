function Get-ChocolateyPackage {
    [CmdletBinding(DefaultParameterSetName = 'Package')]
    param (
        [Parameter()]
        [string]$ComputerName = $env:COMPUTERNAME,
        [Parameter(ParameterSetName = 'Local')]
        [Parameter(ParameterSetName = 'InternalFeed')]
        [Parameter(Mandatory,
            ParameterSetName = 'Package')]
        [string]$PackageName,
        [Parameter(ParameterSetName = 'InternalFeed')]
        [switch]$UseInternalFeed,
        [Parameter(Mandatory,
            ParameterSetName = 'InternalFeed')]
        [string]$SourceName,
        [Parameter(Mandatory,
            ParameterSetName = 'InternalFeed')]
        [string]$SourceUrl,
        [Parameter(Mandatory,
            ParameterSetName = 'InternalFeed')]
        [string]$PersonalAccessToken,
        [Parameter(ParameterSetName = 'Local')]
        [switch]$LocalOnly
    )

    Try {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock ${Function:Install-Chocolatey} |Out-Null
        $Result = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $Params = New-Object System.Collections.Generic.List[string]
            if ($using:UseInternalFeed) {
                choco source add --name=$using:SourceName --user=user --password=$using:PersonalAccessToken --source=$using:SourceUrl
                $Params.Add("--Source=$using:SourceName")
            }
            if ($using:LocalOnly) {
                $Params.Add('--local-only')
            }
            $Params.Add('--limit-output')
            choco search $using:PackageName $Params |ConvertFrom-Csv -Delimiter '|' -Header PackageName,PackageVersion -ErrorAction Ignore
        }
        if ($Result) {
            $Result |Select-Object PackageName, PackageVersion
        }
    }
    Catch {
        throw $_
    }
}