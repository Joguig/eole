
Set-ExecutionPolicy Bypass -Scope Process -Force
Set-Location 'c:\eole\'

Write-Host "* sourcing functions "
. z:\scripts\windows\EoleCiFunctions.ps1

#[string]$vmMachine = $context["VM_MACHINE"]
[string]$vmEoleCiTestsIp = $context["VM_IP_EOLECITEST"]

Write-Host "* Install-Module OpenSSHUtils"
Install-Module OpenSSHUtils -Force 
    
if ( -Not( Test-Path c:\Users\pcadmin\.ssh ))
{
    New-Item -ItemType directory -Path c:\Users\pcadmin\.ssh | Out-Null
}
    
Write-Host "* Generate keys pcadmin"
if ( -Not( Test-Path c:\Users\pcadmin\.ssh\id_rsa ))
{
    Write-Host "* Generation de la clef SSH"
    ssh-keygen -b 2048 -t rsa -f c:\Users\pcadmin\.ssh\id_rsa -q 
}
    
Write-Host "* ssh test "
ssh -v -o StrictHostKeyChecking=false "pcadmin@$vmEoleCiTestsIp" "ls"
