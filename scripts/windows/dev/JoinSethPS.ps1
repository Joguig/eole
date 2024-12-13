
function log($t) {
    Write-Host $t
}

function eoleJoinDomain($newDNSServers,$sethDomain,$sethUser,$sethPasswdNotSecure) 
{
    log "* eoleJoinDomain dns=$newDNSServers, domain=$sethDomain, user=$sethUser, pwd=$sethPasswdNotSecure"

    #c:\Windows\debug\NetSetup.log, like the JoinDomainOrWorkgroup 
    remove-Item c:\Windows\debug\NetSetup.log -ErrorAction SilentlyContinue

    if ( $newDNSServers -ne "" )
    {
        log "* Set dns to $newDNSServers " 
        $adapters = Get-WMIObject Win32_NetworkAdapterConfiguration | where {$_.IPEnabled -eq "TRUE" }
        $adapters | ForEach-Object { 
                              $cdu = $_.SetDNSServerSearchOrder($newDNSServers)
                              log "* cdu set dns ==> $cdu" 
                              }
    }
    
    #$vComp = Get-ADObject -LDAPFilter cn="$($computer)" -SearchBase "OU=Computers,DC=Contoso,DC=Com"
    #If $vComp # if not null
    #{
    #}
    
    $sethPasswd = ConvertTo-SecureString $sethPasswdNotSecure -AsPlainText -Force
    $sethCredential = New-Object System.Management.Automation.PSCredential ("$sethUser", $sethPasswd)
    try
    {
        log "* Add Computer to $sethDomain" 
        #$ComputerInfo.JoinDomainOrWorkgroup($Domain, $password, $domaineAdmin, $null, 3)
        $joinInfo = Add-Computer -DomainName "$sethDomain" -Credential $sethCredential -PassThru -ErrorAction stop
        if ( $joinInfo.HasSucceeded )
        {
            Write-Host "pc join au domaine OK!" -foregroundcolor green
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultDomainName" -Value "$sethDomain"
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableFirstLogonAnimation" -Value "0"
            
            $vmId | Out-File -Encoding ASCII -FilePath "$systemDrive\eole\domain-jointed.txt"
            
            log "* joinction --> Restart-Computer"
            Restart-Computer -force
        } 
    }
    catch
    {
        Write-Host 'System Error Caught' -foregroundcolor red
        $_   #this is the error
    }
}


[string]$VersionWindows = "?"
[int]$versionMajor = [environment]::OSVersion.version.Major
[int]$versionBuild = [environment]::OSVersion.version.Build
if( $versionMajor -lt 6)
{ 
    Log "OS non supporté"
    return
}

if( $versionMajor -lt 10)
{ 
    if( $versionBuild -eq 9600)
    { 
        log "* Windows 7"
        $VersionWindows = "7"
    }

    if( $versionBuild -eq 9200)
    {
        log "* Windows 2012R2"
        $VersionWindows = "2012R2"
    }    
}
else
{
    log "* Windows 10"
    $VersionWindows = 10
    
    if( $versionBuild -eq 16299)
    { 
        $VersionWindows = "10.1709"
    }
    
    if( $versionBuild -eq 15063)
    { 
        $VersionWindows = "10.1703"
    }

    if( $versionBuild -eq 14393)
    { 
        $VersionWindows = "10.1607"
    }

    if( $versionBuild -eq 17134)
    { 
        $VersionWindows = "10.1803"
    }
    
    
}
log "* VersionWindows= $VersionWindows"

[string]$computerName = "$env:computername"
[string]$ConnectionString = "WinNT://$computerName"

Set-PSDebug -Trace 0

$contextDrive = Get-WMIObject Win32_Volume | ? { $_.Label -eq "CONTEXT" }
if ( -not ( $contextDrive ) ) 
{
    return
}

$contextLetter     = $contextDrive.Name
$contextScriptPath = $contextLetter + "context.sh"

if( -not ( Test-Path $contextScriptPath ) )
{
    log "* pas de ''context.sh'', stop"
    return 
}

$context = @{}
switch -regex -file $contextScriptPath {
    "^([^=]+)='(.+?)'$" {
        $name, $value = $matches[1..2]
        $context[$name] = $value
    }
}

[string]$vmId = $context["VM_ID"]
[string]$vmOwner = $context["VM_OWNER"]
if ( -not ( $vmId ) )
{
    log "* pas de ''VM_ID'', stop"
    return 
} 
if ( -not ( $vmOwner ) )
{
    log "* pas de ''VM_OWNER'', stop"
    return 
} 

if( $versionMajor -ge 10)
{
    $smb1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
    if ( $smb1.State -eq 'Disabled' )
    {
        Write-Host "SMB1 déactivé, Windows 10 : ok"
    }
    else
    {
        Write-Host "SMB1 Actif, Windows 10 : ok"
        return        
    }
}
else
{
    Write-Host "SMB1 Actif, Windows 7"
}

$netmask = "255.255.255.0"
$network = "192.168.0.0"
$gateway = "192.168.0.1"

#[System.Management.Automation.PSCredential]$Credential = $(Get-Credential)

eoleJoinDomain -newDNSServers 192.168.0.5 -sethDomain domseth.ac-test.fr -sethUser admin -sethPasswdNotSecure Eole12345!

#Get-Content c:\Windows\debug\NetSetup.log

