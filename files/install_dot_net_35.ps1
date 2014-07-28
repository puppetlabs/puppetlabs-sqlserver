

Install-WindowsFeature  NET-Framework-Core

Write-Host "Installing .Net Framework 3.5, do not close this prompt..."
DISM /Online /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:$LocalSource | Out-Null
$Result = Dism /online /Get-featureinfo /featurename:NetFx3
If($Result -contains "State : Enabled")
{
    Write-Host "Install .Net Framework 3.5 successfully."
}
Else
{
    Write-Host "Failed to install Install .Net Framework 3.5,please make sure the local source is correct."
}
