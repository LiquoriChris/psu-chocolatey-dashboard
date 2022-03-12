function Install-ChocolateyPackage {
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        [Parameter(Mandatory)]
        [string[]]$PackageName,
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
        [switch]$Upgrade,
        [switch]$Restart
    )

    Try {
        foreach ($Computer in $ComputerName) {
            $Session = New-PSSession -ComputerName $Computer
            if (-not($Upgrade)) {
                Invoke-Command -Session $Session -ScriptBlock ${Function:Install-Chocolatey} |Out-Null
            }
            Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
                $Params = New-Object System.Collections.Generic.List[string]
                if ($using:UseInternalFeed) {
                    choco source add --name=$using:SourceName --user=user --password=$using:PersonalAccessToken --source=$using:SourceUrl
                    $Params.Add("--Source=$using:SourceName")
                }
                $Params.Add('-y')
                $Params.Add('--no-progress')
                if ($using:upgrade) {
                    $Type = 'upgrade'
                }
                else {
                    $Type = 'install'
                }
                Write-Output $env:ComputerName 
                Write-Output ------------------
                [Environment]::NewLine
                choco $Type $using:PackageName $Params
                [Environment]::NewLine
                if ($using:Restart) {
                    Restart-Computer -Force -ErrorAction Stop
                    Write-Output "`n$env:COMPUTERNAME has restarted successfully"
                }
            }
        }
    }
    Catch {
        Write-Error $_
    }
}