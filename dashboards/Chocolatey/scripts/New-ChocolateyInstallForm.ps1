function New-ChocolateyInstallForm {   
    param (
        [string]$SourceName = $AzureDevOpsSourceName,
        [string]$SourceUrl = $AzureDevOpsSourceUrl,
        [string]$PersonalAccessToken = $AzureDevOpsPAT
    ) 
    New-UDDynamic -Content {
        New-UDPaper -Children {
            Try {
                New-UDRow -Columns {
                    New-UDColumn -Content {
                        New-UDTypography -Text 'Install Chocolatey package(s) on one or more remote systems (Comma delimited)' -Variant h4
                    }
                    New-UDColumn -Content {
                        New-UDForm -Content {
                            New-UDTextBox -Id 'txtInstallComputerName' -Label 'ComputerName (Name of computer to install packages) (Comma delimited)' -Type text -FullWidth
                            New-UDTextBox -Id 'txtInstallPackageName' -Label 'PackageName (Name of package(s) to install) (Comma delimited)' -Type text -FullWidth
                            New-UDCheckbox -Id 'chkInstallUseInternalFeed' -Label 'Use Internal Feed (Use Azure DevOps NuGet Repository as source install)' -OnChange {
                                Sync-UDElement -Id 'dyInstallInternalFeed'
                            }
                            New-UDDynamic -Id 'dyInstallInternalFeed' -Content {
                                $InternalFeed = Get-UDElement -Id 'chkInstallUseInternalFeed'
                                if ($InternalFeed.checked) {
                                    New-UDRow -Columns {
                                        New-UDColumn -Content {
                                            New-UDTextBox -Id 'txtInstallSourceName' -Label 'SourceName' -Value $SourceName -Type text -Placeholder 'Name of Azure DevOps NuGet Source' -FullWidth
                                        }
                                        New-UDColumn -Content {
                                            New-UDTextBox -Id 'txtInstallSourceUrl' -Label 'SourceUrl' -Value $SourceUrl -Type text -Placeholder 'Url of Azure DevOps NuGet Artifact' -FullWidth
                                        }
                                        New-UDColumn -Content {
                                            New-UDTextBox -Id 'txtInstallSourcePersonalAccessToken' -Label 'PersonalAccessToken' -Value $PersonalAccessToken -Type password -Placeholder 'Azure DevOps Personal Access Token (Must have access to Artifacts)' -FullWidth
                                        }
                                    }
                                }
                            }
                            New-UDCheckbox -Id 'chkInstallUpgrade' -Label 'Upgrade (Will use choco upgrade to upgrade current package to latest version)'
                            New-UDCheckbox -Id 'chkInstallRestart' -Label 'Restart (Will restart computer after install completes)'
                        } -OnValidate {
                            $FormContent = $EventData
                            if (-not($FormContent.txtInstallComputerName)) {
                                New-UDFormValidationResult -ValidationError 'ComputerName field is required'
                            }
                            elseif (-not($FormContent.txtInstallPackageName)) {
                                New-UDFormValidationResult -ValidationError 'PackageName field is required'
                            }
                            else {
                                New-UDFormValidationResult -Valid
                            }
                        } -OnSubmit {
                            Clear-UDElement -Id 'installResults'
                            Show-UDModal -Content {
                                New-UDTypography -Text 'Installing Chocolatey packages... Please wait'
                                New-UDProgress
                            }
                            $ComputerName = $EventData.txtInstallComputerName.Split(',').Trim()
                            $Params = @{
                                ComputerName = $ComputerName
                                PackageName = $EventData.txtInstallPackageName
                            }
                            $InternalFeed = (Get-UDElement -Id 'chkInstallUseInternalFeed').checked
                            if ($InternalFeed) {
                                $Params.UseInternalFeed = $true
                                $Params.SourceName = $EventData.txtInstallSourceName
                                $Params.SourceUrl = $EventData.txtInstallSourceUrl
                                $Params.PersonalAccessToken = $EventData.txtInstallSourcePersonalAccessToken
                            }
                            $Upgrade = (Get-UDElement -Id 'chkInstallUpgrade').checked
                            if ($Upgrade) {
                                $Params.Upgrade = $true
                            }
                            $Restart = (Get-UDElement -Id 'chkInstallRestart').checked
                            if ($Restart) {
                                $Params.Restart = $true
                            }
                            Set-UDElement -Id 'installResults' -Content {
                                $Install = Install-ChocolateyPackage @Params |Out-String
                                Hide-UDModal
                                Show-UDModal -MaxWidth lg -FullWidth -Persistent -Content {
                                    New-UDCodeEditor -Code $Install -Height 500 -ReadOnly
                                } -Footer {
                                    New-UDButton -Text 'Close' -OnClick {
                                        Hide-UDModal
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Catch {
                New-UDErrorBoundary -Content {
                    throw $_
                }
            }
        }
        New-UDElement -Id 'installResults' -Tag div
    }
}