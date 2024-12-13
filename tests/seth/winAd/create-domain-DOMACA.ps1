Write-Output "Active services : Win Update + BITS"
Set-Service wuauserv -StartupType Automatic -ErrorAction Ignore
Set-Service BITS -StartupType Automatic -ErrorAction Ignore

Write-Output "* Start services Win Update + BITS"
Start-Service wuauserv -ErrorAction Ignore
Start-Service BITS  -ErrorAction Ignore

Write-Output "* import ADDSDeployment"
Import-Module ADDSDeployment -Force

Write-Output "* Create New Forest, add Domain Controller"

Write-Output "* Reset pwd Admionistrator"
$pass = "Eole12345!"| ConvertTo-SecureString -AsPlainText -Force
#Get-LocalUser -Name "Administrator" | Set-LocalUser -Password $pass

Write-Output "* Create New Forest, add Domain Controller"
Install-ADDSForest `
        -DomainName "domaca.ac-test.fr" `
        -SkipPreChecks `
        -SafeModeAdministratorPassword $pass `
        -DatabasePath "C:\Windows\NTDS" `
        -DomainMode "Win2008R2" `
        -ForestMode "Win2008R2" `
        -InstallDns:$true `
        -LogPath "C:\Windows\NTDS" `
        -NoRebootOnCompletion `
        -SysvolPath "C:\Windows\SYSVOL" `
        -Force

#Write-Output "* DomainMode"
#Get-ADDomain | fl Name, DomainMode

#Write-Output "* ForestMode"
#Get-ADDomain | fl Name, ForestMode

# Samba 4.13 -> 2008R2 seulement !
#Set-ADDomainMode -identity domaca.ac-test.fr -DomainMode Windows2012Forest
#Set-ADDomainMode -identity domaca.ac-test.fr -ForestMode Windows2012Forest

Write-Host "fin"