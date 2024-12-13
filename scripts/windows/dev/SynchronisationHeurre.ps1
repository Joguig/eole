
$keyNtp = (Get-Item -LiteralPath HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config)
$FileLogSize = $keyNtp.GetValue("FileLogSize")
Write-Host "current FileLogSize = $FileLogSize"
$FileLogName = $keyNtp.GetValue("FileLogName")
Write-Host "current FileLogName = $FileLogName"
$FileLogEntries = $keyNtp.GetValue("FileLogEntries" )
Write-Host "current FileLogEntries = $FileLogEntries"

$parametersNtp = (Get-Item -LiteralPath HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters)
$Type = $parametersNtp.GetValue("Type" )
Write-Host "current Type = $Type"
$ntpserver = $parametersNtp.GetValue("ntpserver" )
Write-Host "current ntpserver = $ntpserver"

Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config -Name "FileLogSize" -Value "1000000"
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config -Name "FileLogName" -Value "c:\\w32time_debug.txt"
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config -Name "FileLogEntries" -Value "0-300"
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters -Name "Type" -Value "ntp"
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters -Name "ntpserver" -Value "addc.domscribe.ac-test.fr"


w32tm /config /syncfromflags:domhier
w32tm /config /update
w32tm /resync /nowait

w32tm /monitor