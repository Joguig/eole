Write-Output "Debut active_utc.ps1"

Write-Output "* get-date Avant"
Get-Date

Write-Output "* Activation RealTimeIsUniversal"
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation -Name RealTimeIsUniversal -Value 1 -Type DWord -Force

Write-Output "* w32time --> Automatic"
Set-Service -Name w32time -StartupType Automatic

Write-Output "* get-date"
Get-Date

