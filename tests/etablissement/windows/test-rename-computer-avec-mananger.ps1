$vmConfiguration = $args[0]
$vmVersionMajeurCible = $args[1]
$compteAUtiliser = $args[2]
initializeContextDomain $vmConfiguration $vmVersionMajeurCible

if ( $compteAUtiliser -eq "eole-workstation-manager" )
{
    $pwd_manager = Get-Content "Z:\output\$vmOwner\${compteAUtiliser}.password"
}

echo "pwd_manager= $pwd_manager"
$password = ConvertTo-SecureString $pwd_manager -asPlainText -Force
$username = "$adDomain\compteAUtiliser" 
$credential = New-Object System.Management.Automation.PSCredential($username,$password)
log "* Rename to PC-RENOMME"
$computerChangeInfo = Rename-Computer -NewName "PC-RENOMME" -DomainCredential $credential -Force -PassThru
# pas de -Restart --> dans le Yaml !
# $ComputerInfo = Get-WmiObject Win32_ComputerSystem
# $r = $ComputerInfo.rename($hostname)
# $r.returnValue -eq 0
if ( $computerChangeInfo.HasSucceeded )
{
    log "* $computerChangeInfo"
    exit 0
}
else
{
    log "* $computerChangeInfo"
    exit 1
}
