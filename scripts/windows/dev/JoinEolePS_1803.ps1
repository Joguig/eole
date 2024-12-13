
function log($t) {
    Write-Host $t
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

#Get-SmbClientConfiguration

# Windows                                 1803n 1607n 1709n 
# ConnectionCountPerRssNetworkInterface : 4     4     4     
# DirectoryCacheEntriesMax              : 16    16    16
# DirectoryCacheEntrySizeMax            : 65536 65536 65536
# DirectoryCacheLifetime                : 10    10    10
# DormantFileLimit                      : 1023  1023  1023
# EnableBandwidthThrottling             : True  True  True 
# EnableByteRangeLockingOnReadOnlyFiles : True  True  True
# EnableInsecureGuestLogons             : False True  False
# EnableLargeMtu                        : True  True  True
# EnableLoadBalanceScaleOut             : True  True  True
# EnableMultiChannel                    : True  True  True
# EnableSecuritySignature               : True  True  True
# ExtendedSessionTimeout                : 1000  1000  1000
# FileInfoCacheEntriesMax               : 64    64    64
# FileInfoCacheLifetime                 : 10    10    10
# FileNotFoundCacheEntriesMax           : 128   128   128
# FileNotFoundCacheLifetime             : 5     5     5
# KeepConn                              : 600   600   600
# MaxCmds                               : 50    50    50
# MaximumConnectionCountPerServer       : 32    32    32
# OplocksDisabled                       : False False False
# RequireSecuritySignature              : False False False
# SessionTimeout                        : 60    60    60
# UseOpportunisticLocking               : True  True  True
# WindowSizeThreshold                   : 8     8     8

#Get-Item HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters | ForEach-Object {Get-ItemProperty $_.pspath}

#                                         1803 1709  7
# ServiceDllUnloadOnStop                : 1    1     1                                                       
# EnableAuthenticateUserSharing         : 0    0     0                                                       
# NullSessionPipes                      : {}   {}    {}
# autodisconnect                        : 15   15    15                                                      
# enableforcedlogoff                    : 1    1     1                                                       
# enablesecuritysignature               : 0    0     0                                                       
# requiresecuritysignature              : 0    0     0                                                       
# restrictnullsessaccess                : 1    1     1                                                       
# Lmannounce                            : x    x     0                                                       
# Size                                  : x    x     1                                                       
# AdjustedNullSessionPipes              : x    x     3
# SMB1                                  : 0    x     x
# AuditSmb1Access                       : 1    x     x                                                       

# SMB1=0 désactivé  1 activé(pas de clé) !
# SMB2=0 désactivé  1 activé(pas de clé) !

#Get-Item HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters | ForEach-Object {Get-ItemProperty $_.pspath}

#                                         1803 
# EnablePlainTextPassword               : 0
# enablesecuritysignature               : 1
# requiresecuritysignature              : 0
# DomainCompatibilityMode               : 1                                         
# DNSNameResolutionRequired             : 0                  
# AllowInsecureGuestAuth                : 0

Set-PSDebug -Trace 0

Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol

if( $versionMajor -ge 10)
{
    $smb1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
    if ( $smb1.State -eq 'Disabled' )
    {
        Write-Host "activation SMB1 Windows 10 "
        Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
        Restart-Computer -Force
    }
    else
    {
        Write-Host "SMB1 Actif, Windows 10 : ok"
    }
}
else
{
    Write-Host "SMB1 Actif, Windows 7"
}

$srv = "FDResPub" 
$service = Get-Service $srv
if ( !($service.Status -eq "Running") )
{
    Write-Host "$srv starting..."
    Start-Service $service
}
else
{
    Write-Host "Service $srv started, ok"
}

$srv = "fdPHost" 
$service = Get-Service $srv
if ( !($service.Status -eq "Running") )
{
    Write-Host "$srv starting..."
    Start-Service $service
}
else
{
    Write-Host "Service $srv started, ok"
}

sc.exe qc lanmanworkstation
# dependencies lanmanworkstation
# 7 => Bowser ! + MRxSmb10 + MRxSmb20 + NSI
# 1709 => Bowser ! + MRxSmb10 + MRxSmb20 + NSI

sc.exe qc lanmanserver  
# dependencies lanmanserver
# 7 => SamSS + Srv
# 1709 => SamSS + Srv2
# 1803 => SamSS + Srv2

#sc.exe config lanmanworkstation depend= bowser/mrxsmb10/nsi
#sc.exe config mrxsmb10 start= auto
#sc.exe config mrxsmb20 start= disabled

$mrxsmb = Get-Service mrxsmb
if ( !($mrxsmb.Status -eq "Running") )
{
    Write-Host "mrxsmb: $mrxsmb.Status"
    #Start-Service $mrxsmb
}

$mrxsmb10 = Get-Service mrxsmb10
if ( !($mrxsmb10.Status -eq "Running") )
{
    Write-Host "mrxsmb10: $mrxsmb10.Status"
    #Start-Service $mrxsmb10
}

$mrxsmb20 = Get-Service mrxsmb20
if ( !($mrxsmb20.Status -eq "Running") )
{
    Write-Host "mrxsmb20: $mrxsmb20.Status"
    #Stop-Service $mrxsmb20
}


$restartWorkstation = $false
$DomainCompatibilityMode = Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters -Name DomainCompatibilityMode
if ( -Not ( $DomainCompatibilityMode ))
{
     Write-Host "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters\DomainCompatibilityMode manque"
     #New-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters -Name DomainCompatibilityMode -PropertyType DWord -Value 1
     $restartWorkstation = $true 
}
else
{
     Write-Host "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters\DomainCompatibilityMode existe"
     $DomainCompatibilityMode.DomainCompatibilityMode
}

$DNSNameResolutionRequired = Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters -Name DNSNameResolutionRequired
if ( -Not ( $DNSNameResolutionRequired ))
{
     Write-Host "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters\DNSNameResolutionRequired manque"
     #New-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters -Name DNSNameResolutionRequired -PropertyType DWord -Value 0
     $restartWorkstation = $true 
}
else
{
     Write-Host "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters\DNSNameResolutionRequired existe"
     $DNSNameResolutionRequired.DNSNameResolutionRequired
}

$AllowSingleLabelDnsDomain = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters -Name AllowSingleLabelDnsDomain
if ( -Not ( $AllowSingleLabelDnsDomain ))
{
     Write-Host "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\AllowSingleLabelDnsDomain manque"
     New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters -Name AllowSingleLabelDnsDomain -PropertyType DWord -Value 1
     $restartWorkstation = $true 
}
else
{
     Write-Host "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\AllowSingleLabelDnsDomain exist"
     $AllowSingleLabelDnsDomain.AllowSingleLabelDnsDomain
}

if ( $restartWorkstation )
{
     Write-Host "Restart wks"
     #Restart-Service LanmanWorkstation -force
}


Set-PSDebug -Trace 0

#[System.Management.Automation.PSCredential]$Credential = $(Get-Credential)
$Domain = "domaca"
$domaineAdmin = "admin"
$password = "eole"

#c:\Windows\debug\NetSetup.log, like the JoinDomainOrWorkgroup 
remove-Item c:\Windows\debug\NetSetup.log -ErrorAction SilentlyContinue

#add-computer -Credential $Domain\$domaineAdmin -DomainName $domaineAdmin
#$ComputerInfo.JoinDomainOrWorkgroup($Domain, $password, $domaineAdmin, $null, 3)

#Get-Content c:\Windows\debug\NetSetup.log

#Restart-Computer

#reg_add -path "HKLM:\SYSTEM\CurrentControlSet\services\LanmanWorkstation\Parameters" -key "DomainCompatibilityMode" -Value 1 -type "DWORD"
#reg_add -path "HKLM:\SYSTEM\CurrentControlSet\services\LanmanWorkstation\Parameters" -key "DNSNameResolutionRequired" -Value 0 -type "DWORD"
# reg_add -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -key "EnableLUA" -Value 0 -type "DWORD"
# reg_add -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -key "ConsentPromptBehaviorAdmin" -Value  0 -type "DWORD"
# reg_add -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -key "PromptOnSecureDesktop" -Value 0 -type "DWORD"
# reg_add -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -key "dontdisplaylastusername" -Value 1 -type "DWORD"
# reg_add -path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -key "LmCompatibilityLevel" -Value 1 -type "DWORD"
# echo  "-  Delais d'attente du profil"
# reg_add -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -key "WaitForNetwork" -Value 1 -type "DWORD"
# reg_add -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\NewNetworks", "NetworkList" -Value "" -type "MULTI_SZ" 

