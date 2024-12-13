$vmConfiguration = $args[0]
$vmVersionMajeurCible = $args[1]
initializeContextDomain $vmConfiguration $vmVersionMajeurCible

Set-ExecutionPolicy Bypass -Scope Process -Force

New-Item -Path c:\eole -Name gpos -ItemType "directory" -ErrorAction SilentlyContinue
New-Item -Path c:\eole -Name reports -ItemType "directory" -ErrorAction SilentlyContinue

$domain = $computer.Domain
Write-Host "Domain=$domain"

$cred = New-Object System.Management.Automation.PSCredential ($adDomainAndUserAdmin, $adSecurePasswordAdmin)
$driveG = New-PSDrive -Name "G" -PSProvider FileSystem -Root "\\$adRealm\Sysvol" -Credential $cred
$UNCSysvolPolicies="G:\$adRealm\Policies"

Write-Host "----------------------------------------------"
Write-Host "check-sysvol: Acl2 $UNCSysvolPolicies"
GCI $UNCSysvolPolicies -ErrorAction SilentlyContinue | Foreach-Object { 
    try
    {
        Write-Host "========================================"
        $guid = $_.Name
        Write-Host "Gpo $guid"
         
        Write-Host "check-sysvol: Backup-Gpo -Guid $guid -DomainName $adRealm" 
        Backup-Gpo -Guid $guid -Path "c:\eole\gpos" -DomainName $adRealm -Debug
    }
    Catch 
    { 
        $_ | Out-Host
        Write-Host "ERREUR: check-sysvol" 
    }
}

Get-GPO -All -Domain $domain | foreach-object {
    try
    {
        Write-Host "========================================"
        $_
        Write-Host "----- ACL"
        $_ | Get-GPPermissions -All
        Write-Host "----- ACL"

        Write-Host "----- Backup dans c:\eole\gpos"
        $_ | Backup-GPO -All -Path "c:\eole\gpos" -ErrorAction SilentlyContinue
        Write-Host "----- Backup"

        #$gpoGuids += $gpoObj.GUID
        #$polPath = "\\$domain\SYSVOL\$domain\Policies"
        #$polFolders = Get-ChildItem $polPath -Exclude 'PolicyDefinitions' | Select-Object -ExpandProperty name
        #$sysvolGuids += $folder -replace '{|}'
    }
    Catch 
    { 
        $_ | Out-Host
        Write-Host "ERREUR: backup-gpo " $_.Name 
    }
}


$gpoName="Default Domain Policy"
try
{
    Write-Host "----- Get-GPOReport"
    Get-GPOReport -All -ReportType Html -Path 'c:\eole\reports' -ErrorAction SilentlyContinue
    
    #Get-GPOReport -Name $gpoName -ReportType 'HTML' -Path 'c:\temp\Default-Domain-Policy.html -ErrorAction SilentlyContinue

    #$gpoId = (Get-GPO -Name $gpoName).Id
    #Get-GPOReport -Guid $gpoId -ReportType 'HTML' -Path "C:\Temp\$gpoId.html" -ErrorAction SilentlyContinue
}
Catch 
{ 
    $_ | Out-Host
    Write-Host "ERREUR: backup-gpo " $_.Name 
}
