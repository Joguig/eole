
function disableWindowsUpdate()
{
    $WindowsUpdateKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
    $Update_Never    = 1
    $Update_Check    = 2
    $Update_Download = 3
    $Update_Auto     = 4
    Set-ItemProperty -Path $WindowsUpdateKey -Name AUOptions       -Value $Update_Never -Force -Confirm:$false
    Set-ItemProperty -Path $WindowsUpdateKey -Name CachedAUOptions -Value $Update_Never -Force -Confirm:$false
}

function enableWindowsUpdate()
{
    $mgr = New-Object -ComObject Microsoft.Update.ServiceManager -Strict
    $mgr.ClientApplicationID = "installer"
    $mgr.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"")
}

Write-Host "Début Windowsupdate"

Set-PSDebug -Trace 1

Write-Host "get service object"
$pss = Get-Service 'wuauserv' 
$pss
$pss.Status

Write-Host "service automatic"
Set-Service wuauserv -StartupType Automatic
$pss = Get-Service 'wuauserv' 
$pss

Write-Host "start service BITS"
Start-Service BITS
$pss = Get-Service BITS
$pss

Write-Host "start service wuauserv"
Start-Service wuauserv
$pss = Get-Service 'wuauserv' 
$pss

wuauclt /detectnow
#Set-Service wuauserv -StartupType Disable
#disableWindowsUpdate

Set-PSDebug -Trace 0
Write-Host "* Fin"

