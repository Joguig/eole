$vmConfiguration = $args[0]
$vmVersionMajeurCible = $args[1]
$userATester = $args[2]
initializeContextDomain $vmConfiguration $vmVersionMajeurCible

Set-Location c:\eole

Write-Host "----------------------------------------------------------------------"
Write-Host "* force-gpo-update: GPUPDATE /Target:Computer /Force /Wait:120"
CMD.EXE /C "GPUpdate /Target:Computer /Force /Wait:120"

Write-Host "* C:\Users\${userATester}\AppData\Local\Temp\eole_script.log N'EXISTE PAS (bizarre) !"
Write-Host "* force-gpo-update: GPUPDATE /Target:User /Force /Wait:120"
CMD.EXE /C "GPUpdate /Target:User /Force /Wait:120"

Write-Host "----------------------------------------------------------------------"
Write-Host "force-gpo-update: GPRESULT /H c:\eole\GpResult.htm /F"
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
    Write-Host "ERREUR: force-gpo-update: GpResult.html manque !"
}

CMD.EXE /C "gpresult /H c:\eole\GpResultUser.htm /F /USER $userATester"
if( Test-Path ( "c:\eole\GpResultUser.htm" ) )
{
    Copy-Item c:\eole\GpResultUser.htm Z:\output\$vmOwner\$vmId\GpResultUser.html
    Write-Output "EOLE_CI_PATH GpResultUser.html"
}
else
{
    Write-Host "WARNING: force-gpo-update: GpResultUser.html manque !"
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
    Write-Host "ERREUR: force-gpo-update: pas de fichier C:\Windows\TEMP\install-minion.log !"
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
    Write-Host "ERREUR: force-gpo-update: pas de fichier C:\Users\${userATester}\AppData\Local\Temp\eole_script.log !"
}

