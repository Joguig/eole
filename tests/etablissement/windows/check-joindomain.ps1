$vmConfiguration = $args[0]
$vmVersionMajeurCible = $args[1]
$userATester = $args[2]
initializeContextDomain $vmConfiguration $vmVersionMajeurCible

Set-Location c:\eole

Write-Host "----------------------------------------------------------------------"
Write-Host "check-joindomain"
displayJoinStatus
if( -Not( 1,3,4,5 -contains ($computer.DomainRole) ))
{ 
    Write-Host "ERREUR: pas dans le domaine, exit 1"
    exit 1
}

Write-Host "* Check UserName et Session ?"
Get-Process -IncludeUserName | Select-Object UserName,SessionId | Where-Object { $_.UserName -ne $null } | Sort-Object UserName,SessionId -Unique

$userSessionAttendue="$adDomain\$userATester"
Write-Host "* est-ce que la session '$userSessionAttendue' est ouverte ?"
$listU = Get-Process -IncludeUserName | Select-Object UserName,SessionId | Where-Object { $_.UserName -eq $userSessionAttendue } | Sort-Object UserName,SessionId -Unique  
if ( $listU.Count -ne 0 )
{
    Write-Host "* La session '$userSessionAttendue' est ouverte : OK"
}
else
{
    Write-Host "ERREUR: La session '$userSessionAttendue' n'est pas ouverte par autologon"
}

# doit être créer apres le reboot, mais on peut arriver ici avant l'execution !
if( Test-Path ( "C:\Windows\TEMP\install-minion.log" ) )
{
    Write-Host "* C:\Windows\TEMP\install-minion.log EXISTE !"
}
else
{
    Write-Host "* C:\Windows\TEMP\install-minion.log N'EXISTE PAS (bizarre) !"
    
    Write-Host "----------------------------------------------------------------------"
    Write-Host "* check-joindomain: GPUPDATE /Target:Computer /Force /Wait:120"
    CMD.EXE /C "GPUpdate /Target:Computer /Force /Wait:120"
}

# doit être créer apres le reboot, mais on peut arriver ici avant l'execution !
if( Test-Path ( "C:\Users\${userATester}\AppData\Local\Temp\eole_script.log" ) )
{
    Write-Host "* C:\Users\${userATester}\AppData\Local\Temp\eole_script.log EXISTE !"
}
else
{
    Write-Host "* C:\Users\${userATester}\AppData\Local\Temp\eole_script.log N'EXISTE PAS (bizarre) !"
    Write-Host "* check-joindomain: GPUPDATE /Target:User /Force /Wait:120"
    CMD.EXE /C "GPUpdate /Target:User /Force /Wait:120"
}


$PoliciesSystemRegPath="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$SystemRegPath="HKLM:\Software\Policies\Microsoft\Windows\System"
$WinlogonRegPath="HKLM:\Software\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon"

if ( $vmVersionMajeurCible -eq '2.7.1' )
{
    Write-Host "WARNING: check-joindomain: test AsyncScriptDelay ignoré car pas 2.7.1 !"
}
else
{
    Write-Host "----------------------------------------------------------------------"
    Write-Host "check-joindomain: test AsyncScriptDelay"
    $SystemReg = Get-ItemProperty -Path $SystemRegPath -ErrorAction SilentlyContinue
    if ( -not ( $SystemReg ) )
    {
        Write-Host "ERREUR: check-joindomain: $SystemRegPath manque !"
    }
    else
    {
        $AsyncScriptDelay = $SystemReg.AsyncScriptDelay
        Write-Host "check-joindomain: AsyncScriptDelay = $AsyncScriptDelay"
        if ( $AsyncScriptDelay -eq 0 )
        {
            Write-Host "check-joindomain: AsyncScriptDelay OK"
        }
        else
        {
            Write-Host "ERREUR: check-joindomain: AsyncScriptDelay NOK"
        }
    }
}

Write-Host "check-joindomain: test EnableLinkedConnection"
$EnableLinkedConnections = (Get-ItemProperty -Path $PoliciesSystemRegPath).EnableLinkedConnections
Write-Host "check-joindomain: EnableLinkedConnections = $EnableLinkedConnections"
if ( $EnableLinkedConnections -eq 1 )
{
    Write-Host "check-joindomain: EnableLinkedConnections OK"
}
else
{
    Write-Host "ERREUR: check-joindomain: EnableLinkedConnections NOK"
}

Write-Host "----------------------------------------------------------------------"
Write-Host "check-joindomain: GPRESULT /H c:\eole\GpResult.htm /F"
if ( Test-Path( "c:\eole\gpresult.htm" ) )
{
    Remove-Item "c:\eole\gpresult.htm" -ErrorAction SilentlyContinue
}

CMD.EXE /C "gpresult /H c:\eole\GpResult.htm /F"
if( Test-Path ( "c:\eole\GpResult.htm" ) )
{
    Copy-Item c:\eole\GpResult.htm Z:\output\$vmOwner\$vmId\GpResult.html
    Write-Output "EOLE_CI_PATH GpResult.html"
}
else
{
    Write-Host "ERREUR: check-joindomain: GpResult.html manque !"
}

CMD.EXE /C "gpresult /H c:\eole\GpResultUser.htm /F /USER $userATester"
if( Test-Path ( "c:\eole\GpResultUser.htm" ) )
{
    Copy-Item c:\eole\GpResultUser.htm Z:\output\$vmOwner\$vmId\GpResultUser.html
    Write-Output "EOLE_CI_PATH GpResultUser.html"
}
else
{
    Write-Host "WARNING: check-joindomain: GpResultUser.html manque !"
}

if( Test-Path ( "C:\Windows\debug\usermode\gpsvc.log" ) )
{
    Get-Content C:\Windows\debug\usermode\gpsvc.log | Out-File -Encoding UTF8 Z:\output\$vmOwner\$vmId\gpsvc.log
    Write-Output "EOLE_CI_PATH gpsvc.log"
}
else
{
    Write-Host "Warning: check-joindomain: pas de fichier gpsvc.log !"
}

if( Test-Path ( "C:\Windows\debug\usermode\gpmgmt.log" ) )
{
    Get-Content C:\Windows\debug\usermode\gpmgmt.log | Out-File -Encoding UTF8 Z:\output\$vmOwner\$vmId\gpmgmt.log
    Write-Output "EOLE_CI_PATH gpmgmt.log"
}
else
{
    Write-Host "Warning: check-joindomain: pas de fichier gpmgmt.log !"
}

if( Test-Path ( "C:\Windows\TEMP\install-minion.log" ) )
{
    Copy-Item C:\Windows\TEMP\install-minion.log Z:\output\$vmOwner\$vmId\install-minion.log
    Write-Output "EOLE_CI_PATH install-minion.log"
    
    Write-Output "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    Get-Content C:\Windows\TEMP\install-minion.log | Write-Host
    Write-Output "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}
else
{
    Write-Host "ERREUR: check-joindomain: pas de fichier C:\Windows\TEMP\install-minion.log !"
}


if( Test-Path ( "C:\Users\${userATester}\AppData\Local\Temp\eole_script.log" ) )
{
    Copy-Item "C:\Users\${userATester}\AppData\Local\Temp\eole_script.log" Z:\output\$vmOwner\$vmId\eole_script.log
    Write-Output "EOLE_CI_PATH eole_script.log"
    
    Write-Output "#########################################################################################################################"
    Get-Content "C:\Users\${userATester}\AppData\Local\Temp\eole_script.log" | Write-Host
    Write-Output "#########################################################################################################################"
}
else
{
    Write-Host "ERREUR: check-joindomain: pas de fichier C:\Users\${userATester}\AppData\Local\Temp\eole_script.log !"
}

