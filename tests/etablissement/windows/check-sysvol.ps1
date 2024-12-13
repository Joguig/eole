$vmConfiguration = $args[0]
$vmVersionMajeurCible = $args[1]
initializeContextDomain $vmConfiguration $vmVersionMajeurCible

Set-Location c:\eole

Write-Host "check-sysvol : REALM=$adRealm"
if( -Not( 1,3,4,5 -contains ($computer.DomainRole) ))
{ 
    Write-Host "Warning: pas dans le domaine"
}
else
{ 
    Write-Host "ok dans le domaine"
}

#Test-DnsServer -IPAddress 192.168.0.1

if( $versionMajor -lt 10)
{
    Write-Host "check-sysvol: pas de Resolve-DnsName sur win7/2012"
}
else
{
    Write-Host "check-sysvol: Resolve-DnsName $adRealm"
    Resolve-DnsName "$adRealm"
}

$cred = New-Object System.Management.Automation.PSCredential ($adDomainAndUserAdmin, $adSecurePasswordAdmin)
$driveG = New-PSDrive -Name "G" -PSProvider FileSystem -Root "\\$adRealm\Sysvol" -Credential $cred
$UNCSysvolPolicies="G:\$adRealm\Policies"

try
{
    Write-Host "check-sysvol: GCI $UNCSysvolPolicies"
    GCI $UNCSysvolPolicies -ErrorAction SilentlyContinue | Select FullName, Mode
}
Catch 
{ 
    $_ | Out-Host
    Write-Host "ERREUR: backup-gpo " $_.Name 
}

try
{
    Write-Host "----------------------------------------------"
    Write-Host "check-sysvol: Acl1 $UNCSysvolPolicies"
    GCI $UNCSysvolPolicies -ErrorAction SilentlyContinue | Foreach-Object { 
        Write-Host "----------------------------------------------"
        Write-Host "check-sysvol: Acl1 " $_.FullName
        $Acl = $_.GetAccessControl('Access')
        $Acl
    }
}
Catch 
{ 
    $_ | Out-Host
    Write-Host "ERREUR: check-sysvol"
}


try
{
    # https://docs.microsoft.com/en-us/powershell/module/grouppolicy/get-gppermission?view=windowsserver2019-ps
    Write-Host "----------------------------------------------"
    Write-Host "check-sysvol: Acl2 $UNCSysvolPolicies"
    GCI $UNCSysvolPolicies -ErrorAction SilentlyContinue | Foreach-Object { 
        Write-Host "----------------------------------------------"
        $guid = $_.Name
        Write-Host "check-sysvol: Get-GPPermission -Guid $guid -DomainName $adRealm" 
        Get-GPPermission -Guid $guid -All -DomainName "$adRealm"
    }
}
Catch 
{ 
    $_ | Out-Host
    Write-Host "ERREUR: check-sysvol" 
}


try
{
    Write-Host "----------------------------------------------"
    Write-Host "check-sysvol: Acl3"
    #$colRights=[System.Security.AccessControl.FileSystemRights]"FullControl"
    #$InheritanceFlag=[System.Security.AccessControl.InheritanceFlags]::ContainerInherit,[System.Security.AccessControl.InheritanceFlags]::ObjectInherit
    #$PropagationFlag= [System.Security.AccessControl.PropagationFlags]::NoPropagateInherit
    #$objType= [System.Security.AccessControl.AccessControlType]::Allow
    #$objUser= New-Object System.Security.Principal.NTAccount($adDomainAndUserAdmin)
    #$ACE01= New-Object System.Security.AccessControl.FileSystemAccessRule($objUser,$colRights,$InheritanceFlag,$PropagationFlag,$objType)
    $FolderTree= gci "\\$adRealm\Sysvol\$adRealm\Policies" -ErrorAction SilentlyContinue -ErrorVariable +Global:strError
    Foreach ($Folder in $FolderTree.FullName)
    {
        Write-Host "----------------------------------------------"
        Write-Host "check-sysvol: Acl3 " $Folder
        Get-Acl $Folder
    }
}
Catch 
{ 
    $_ | Out-Host
    Write-Host "ERREUR: backup-gpo " 
}

try
{
    Write-Host "----------------------------------------------"
    Write-Host "check-sysvol: Attributs"
    $baseSysvol = "\\$adRealm\Sysvol\$adRealm\Policies\"
    $FolderTree= gci $baseSysvol -Recurse -ErrorAction SilentlyContinue -ErrorVariable +Global:strError
    Foreach ($Folder in $FolderTree.FullName)
    {
        $replativePath = $Folder.replace( $baseSysvol, "")
        Write-Host "check-sysvol: Attr " $replativePath
        Get-ItemProperty $Folder
        if ( $Folder.Extension -eq "ps1" )
        {
            Get-Content -Path $Folder -Stream ‘Zone.Identifier’ -ErrorAction SilentlyContinue
        } 
    }
}
Catch 
{ 
    $_ | Out-Host
    Write-Host "ERREUR: backup-gpo " 
}



        
#dsquery /?
#dsquery server -d $adRealm -u $adUserAdmin -p $adPasswordAdmin! -o rdn
#For /f %i IN ('dsquery server -o rdn') do @echo %i && @(net view \\%i | find "SYSVOL") & echo
#For /f %i IN ('dsquery server -o rdn') do @echo %i && @wmic /node:"%i" /namespace:\\root\microsoftdfs path dfsrreplicatedfolderinfo WHERE replicatedfoldername='SYSVOL share' get replicationgroupname,replicatedfoldername,state
#0 = Uninitialized
#1 = Initialized
#2 = Initial Sync
#3 = Auto Recovery
#4 = Normal
#5 = In Error
#Original post: https://support.microsoft.com/en-us/kb/2958414
