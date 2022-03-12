function New-ChocolateySearchForm {
    param (
        [string]$SourceName = $AzureDevOpsSourceName,
        [string]$SourceUrl = $AzureDevOpsSourceUrl,
        [string]$PersonalAccessToken = $AzureDevOpsPAT
    ) 
    New-UDDynamic -Content {
        New-UDButton -Id 'btnSearch' -Text 'Search Choco Packages' -OnClick {
            Set-UDElement -Id 'searchForm' -Content {
                New-UDPaper -Children {
                    Try {
                        New-UDRow -Columns {
                            New-UDColumn -Content {
                                New-UDTypography -Text 'Search for Chocolatey packages. Empty ComputerName field will search public or private repositories' -Variant h4
                            }
                            New-UDColumn -Content {
                                New-UDForm -Content {
                                    New-UDTextBox -Id 'txtSearchComputerName' -Label 'ComputerName (Name of computer to search for packages)' -Type text -FullWidth
                                    New-UDTextBox -Id 'txtSearchPackageName' -Label 'PackageName (Name of package to search)' -Type text -FullWidth
                                    New-UDCheckbox -Id 'chkSearchUseInternalFeed' -Label 'Use Internal Feed (Use Azure DevOps NuGet Repository as source for search)' -OnChange {
                                        Sync-UDElement -Id 'dySearchInternalFeed'
                                        Sync-UDElement -Id 'searchForm'
                                    }
                                    New-UDDynamic -Id 'dySearchInternalFeed' -Content {
                                        $InternalFeed = Get-UDElement -Id 'chkSearchUseInternalFeed'
                                        if ($InternalFeed.checked) {
                                            New-UDRow -Columns {
                                                New-UDColumn -Content {
                                                    New-UDTextBox -Id 'txtSearchSourceName' -Label 'SourceName' -Value $SourceName -Type text -Placeholder 'Name of Azure DevOps NuGet Source' -FullWidth
                                                }
                                                New-UDColumn -Content {
                                                    New-UDTextBox -Id 'txtSearchSourceUrl' -Label 'SourceUrl' -Value $SourceUrl -Type text -Placeholder 'Url of Azure DevOps NuGet Artifact' -FullWidth
                                                }
                                                New-UDColumn -Content {
                                                    New-UDTextBox -Id 'txtSearchSourcePersonalAccessToken' -Label 'PersonalAccessToken' -Value $PersonalAccessToken -Type password -Placeholder 'Azure DevOps Personal Access Token (Must have access to Artifacts)' -FullWidth
                                                }
                                            }
                                        }
                                    }
                                    New-UDCheckbox -Id 'chkSearchLocalOnly' -Label 'Local Only (Returns packages installed on ComputerName)'
                                } -OnValidate {
                                    $FormContent = $EventData
                                    if ($FormContent.chkSearchLocalOnly -and -not($FormContent.txtSearchComputerName)) {
                                        New-UDFormValidationResult -ValidationError 'ComputerName field is required when searching locally'
                                    }
                                    elseif (-not($FormContent.txtSearchPackageName) -and (-not($FormContent.chkSearchLocalOnly) -and (-not($FormContent.chkSearchUseInternalFeed)))) {
                                        New-UDFormValidationResult -ValidationError 'PackageName field is required'
                                    }
                                    else {
                                        New-UDFormValidationResult -Valid
                                    }
                                } -OnSubmit {
                                    Clear-UDElement -Id 'searchResults'
                                    Show-UDModal -Content {
                                        New-UDTypography -Text 'Searching to Chocolatey packages... Please wait'
                                        New-UDProgress
                                    }
                                    $Params = @{}
                                    if ($EventData.txtSearchComputerName) {
                                        $Params.ComputerName = $EventData.txtSearchComputerName
                                    }
                                    $Package = $EventData.txtSearchPackageName
                                    if ($Package) {
                                        $Params.PackageName = $Package
                                    }
                                    $InternalFeed = (Get-UDElement -Id 'chkSearchUseInternalFeed').checked
                                    if ($InternalFeed) {
                                        $Params.UseInternalFeed = $true
                                        $Params.SourceName = $EventData.txtSearchSourceName
                                        $Params.SourceUrl = $EventData.txtSearchSourceUrl
                                        $Params.PersonalAccessToken = $EventData.txtSearchSourcePersonalAccessToken
                                    }
                                    $LocalOnly = (Get-UDElement -Id 'chkSearchLocalOnly').checked
                                    if ($LocalOnly) {
                                        $Params.LocalOnly = $true
                                    }
                                    Try {
                                        $Data = Get-ChocolateyPackage @Params
                                        $Columns = @(
                                            New-UDTableColumn -Title PackageName -Property PackageName -IncludeInSearch -DefaultSortColumn
                                            New-UDTableColumn -Title PackageVersion -Property PackageVersion -IncludeInSearch
                                        )
                                        Set-UDElement -Id 'searchResults' -Content {
                                            New-UDTable -Id tblSearchResults -Data $Data -Columns $Columns -Dense -ShowSort -ShowFilter -ShowSearch -ShowSelection
                                            New-UDButton -Text 'Add To Install' -OnClick {
                                                $Element = Get-UDElement -Id tblSearchResults
                                                $Package = $Element.selectedRows.PackageName -join ', '
                                                Set-UDElement -Id txtInstallPackageName -Properties @{
                                                    value = $Package
                                                }
                                            }
                                        }
                                        Hide-UDModal
                                    }
                                    Catch {
                                        New-UDErrorBoundary -Content {
                                            New-UDTypography -Text $_
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
            }
        }
        New-UDButton -Id 'btnCloseSearchForm' -Text 'Close Search' -OnClick {
            Clear-UDElement -Id 'searchForm'
        }
        New-UDButton -Id 'btnClearSearchResults' -Text 'Clear Search Results' -OnClick {
            Clear-UDElement -Id 'searchResults'
        }
    }
    New-UDElement -Id 'searchForm' -Tag div
    New-UDElement -Id 'searchResults' -Tag div
}