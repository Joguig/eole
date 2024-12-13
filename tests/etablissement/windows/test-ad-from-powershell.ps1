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

######################################################
# cf. https://www.powershelladmin.com/wiki/Getting_usernames_from_active_directory_with_powershell.php
######################################################
Import-Module ActiveDirectory

######################################################
Get-ADUser -Filter '*' | Select -Exp Name -Last 20

######################################################
Get-ADUser -SearchBase "OU=Users,$adRealmDN" -Filter '*' | Select -Exp Name
 
######################################################
Get-ADUser -Filter '*' -Properties LastLogonTimestamp |
        Sort LastLogonTimestamp |
        Select Name,@{n='LastLogonTimestamp';e={if ($_.LastLogonTimestamp) { [datetime]::FromFileTime($_.LastLogonTimestamp)} } }

######################################################
Get-ADObject -LDAPFilter '(&(objectCategory=Person)(objectClass=User))' | Select -Exp Name -First 20
 
######################################################
# Using ADSI and DirectorySearcher
$DirSearcher = [adsisearcher][adsi]''
$DirSearcher.Filter = '(&(objectCategory=Person)(objectClass=User))'
$DirSearcher.FindAll().GetEnumerator() | %{ $_.Properties.name } | ? { $_ -imatch '^scom' }

######################################################
# Search account 'admin'
$Searcher = [ADSISearcher] "(SamAccountName=admin)"
if ($Searcher.FindOne().Count -eq 1) { "Found in AD" } else { "Not found in AD" }

######################################################
# Code Example To Dump Every User In AD
$DirSearcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher -ArgumentList ([adsi]'')
$DirSearcher.Filter = '(&(objectCategory=Person)(objectClass=User))'
$DirSearcher.FindAll().GetEnumerator() | ForEach-Object {
    # These properties are part of a DirectoryServices.ResultPropertyCollection
    # NB! These properties need to be all lowercase!
    $_.Properties.name
}


######################################################
# Getting Disabled AD Accounts with Ldap query
$DirSearcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher -ArgumentList ([adsi]'')
$DirSearcher.Filter = '(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=2))'
$DirSearcher.FindAll().GetEnumerator() | %{ $_.Properties.name }

######################################################
# Getting Enabled AD Accounts
$DirSearcher = [adsisearcher][adsi]''
$DirSearcher.Filter = '(&(objectCategory=person)(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))'
$DirSearcher.FindAll().GetEnumerator() | %{ $_.Properties.name }

######################################################
# Using Get-QADUser
Add-PSSnapin Quest.ActiveRoles.ADManagement
# Getting Every Single User From AD
Get-QADUser -SizeLimit 0 | Select -Exp Name

#Getting Disabled AD Users
Get-QADUser -SizeLimit 0 -Disabled | Select -Exp Name

######################################################
$Deleg= Get-QADObject 'contoso.com/deleg' -SecurityMask Dacl -SizeLimit 0 | Get-QADPermission -UseTokenGroups -Verbose
$Deleg | FT Account,TargetObject,Rights,RightsDisplay -AutoSize

