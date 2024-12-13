
Function ChangeServiceAccount($sServiceName,$sComputerName,$sUsername,$sPassword)
{
    $oService = Get-WmiObject -ComputerName $sComputerName -Query "SELECT * FROM Win32_Service WHERE Name = '$sServiceName'"
    $oService.Change($null,$null,$null,$null,$null,$null,"$sUsername",$sPassword) | Out-Null
}

$step = $MyInvocation.MyCommand.Name

log "* doInstall début $vmOwner, $vmId, $step"
if( $env:PROCESSOR_ARCHITECTURE -eq 'AMD64' )
{ 
    $nssm = 'C:\eole\nssm64.exe'
}
else
{ 
    $nssm = 'C:\eole\nssm32.exe'
}

$ServiceName = 'EoleCiTestService'
$eoleCiTestServiceObject = Get-Service $ServiceName
$eoleCiTestServiceObject

$compte="DOMSCRIBE\admin"
$pwd="eole"

$current = (& $nssm get $serviceName ObjectName) | Out-String
# suppression des caracteres CR LF TAB ...
$current = $current -replace "`t|`n|`r",""

log "* current = $current"
log "* compte = $compte"
If ( $current -eq $compte )
{
    log "NSSM ObjectName OK"
}
else
{
    log "NSSM Change ObjectName $compte $pwd"
    & $nssm set $serviceName ObjectName "$compte" "$pwd"
    
    log "NSSM Vérification ObjectName"
    $eoleCiTestServiceObject
    & $nssm get $serviceName ObjectName
    
    log "NSSM status"
    # check the status... should be stopped
    & $nssm status $ServiceName
    
}

if ( $eoleCiTestServiceObject.Status -ne 'Running' )
{
    $step = $step -replace ".ps1", ".exit"
    $fichierExit = "z:\\output\$vmOwner\$vmId\done\$step" 
    log "fichier exit avant restart service $fichierExit !"
    "0" | Out-File -Encoding ASCII -FilePath "$fichierExit"
    
    # attente prise en compte !
    Start-Sleep -s 5

    log "NSSM restart"
    # restart va killer le process en cours
    # mais j'ai signalé dans le fichie exit que c'est OK (=0)
    Restart-Service $ServiceName
}

$eoleCiTestServiceObject
