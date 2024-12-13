Write-Output "Active services : Win Update + BITS"
Set-Service wuauserv -StartupType Automatic -ErrorAction Ignore
Set-Service BITS -StartupType Automatic -ErrorAction Ignore

Write-Output "* Start services Win Update + BITS"
Start-Service wuauserv -ErrorAction Ignore
Start-Service BITS  -ErrorAction Ignore

Write-Output "* wuauclt /detectnow"
wuauclt /detectnow

start-job -Name addFeature -ScriptBlock {
    Add-WindowsFeature -Name "ad-domain-services" -IncludeAllSubFeature -IncludeManagementTools
    Add-WindowsFeature -Name "dns" -IncludeAllSubFeature -IncludeManagementTools
    Add-WindowsFeature -Name "gpmc" -IncludeAllSubFeature -IncludeManagementTools 
    Add-WindowsFeature -Name "RSAT-AD-Tools"
    Add-WindowsFeature -Name "RSAT-AD-PowerShell"}

Write-Output "* Wait-Job addFeature"
Wait-Job -Name "addFeature" -Timeout 1000

Write-Output "* Uninstall-WindowsFeature FS-SMB1"
start-job -Name removeFeature -ScriptBlock {
    Uninstall-WindowsFeature -Name FS-SMB1 -Remove
}    

Write-Output "* Wait-Job removeFeature"
Wait-Job -Name "removeFeature" -Timeout 1000

Write-Output "* liste installés"
Get-WindowsFeature | Where installed | Select Name, DisplayName

Write-Host "fin"