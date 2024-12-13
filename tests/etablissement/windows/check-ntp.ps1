$vmConfiguration = $args[0]
$vmVersionMajeurCible = $args[1]
initializeContextDomain $vmConfiguration $vmVersionMajeurCible

#Write-Host "----------------------------------------------------------------------"
#Write-Host "* Check RTC "
#$RtcRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation"
#$RtcReg = Get-ItemProperty -Path $RtcRegPath -ErrorAction SilentlyContinue
#$RtcReg

Write-Host "check-Ntp: Get Current Date"
get-date

Write-Host "check-Ntp: Get Current TimeZone"
get-timezone

Write-Host "check-Ntp: w32tm /query /configuration"
w32tm /query /configuration

Write-Host "check-Ntp: w32tm"
#w32tm /query /computer:$Server /source
w32tm /debug /enable /file:c:\eole\ntp.log /entries:0-300 /size:1000000

Write-Host "check-Ntp: w32tm /monitor"
w32tm /monitor

Write-Host "check-Ntp: ntp.log"
Get-Content c:\eole\ntp.log -ErrorAction SilentlyContinue

Write-Host "check-Ntp: Get-ItemProperty -Path $NTPreg"
$NTPreg = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
Get-ItemProperty -Path $NTPreg | Out-GridView
## Get current NTP configuration. $NTPtype can be "NT5DS" (domain hierarchy, get time from PDCe) or "NTP" (get time from configured NTP source.)
$NTPtype = (Get-ItemProperty -Path $NTPreg).Type
## Get FQDN of the NTP server to get time from. Only applicable if $NTPtype is NTP. Ignored if $NTPtype is NT5DS.
$NTPvalue = (Get-ItemProperty -Path $NTPreg).NTPserver

