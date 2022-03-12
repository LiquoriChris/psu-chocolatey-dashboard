function Install-Chocolatey {
    Try {
        Get-Command -Name choco.exe -ErrorAction Stop |Out-Null
    }
    Catch {
        [Net.ServicePointManager]::SecurityProtocol = 'tls12'
        $TempDirectory = $env:Temp
        $ZipName = 'Choco.zip'
        $ChocoZip = Join-Path -Path $TempDirectory -ChildPath $ZipName
        $ChocoTemp = Join-Path -Path $TempDirectory -ChildPath 'choco'
        Invoke-WebRequest -Uri https://chocolatey.org/api/v2/package/chocolatey -OutFile $ChocoZip
        if (-not(Test-Path -Path $ChocoTemp)) {
            New-Item -Path $ChocoTemp -ItemType Directory -ErrorAction Stop
        }
        Expand-Archive -Path $ChocoZip -DestinationPath $ChocoTemp -ErrorAction Stop -Force
        Get-ChildItem -Path $ChocoTemp -Dept 5 -ErrorAction Stop |ForEach-Object {
            Unblock-File -Path $PSItem.FullName -ErrorAction Stop
        }
        Invoke-Expression -Command (Join-Path $ChocoTemp -ChildPath '\tools\ChocolateyInstall.ps1') -ErrorAction Stop
        Remove-Item -Path $ChocoTemp, $ChocoZip -Force -Recurse
    }
}