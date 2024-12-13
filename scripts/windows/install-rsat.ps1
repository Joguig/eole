
. z:\scripts\windows\EoleCiFunctions.ps1

Log "* install-rsat Début"

enableWindowsUpdate
if( $versionBuild -ge 17758)
{
	log "* RSAT from Appx !"
    Get-WindowsCapability -Online -Name 'RSAT*' | Select-Object -Property DisplayName, State
    
    # a partir de W10 1809 ==> RSAT = feature windows store ! 
    
    checkInstallRsatComponent Rsat.ActiveDirectory.DS-LDS.Tools
    checkInstallRsatComponent Rsat.DHCP.Tools
    checkInstallRsatComponent Rsat.Dns.Tools
    checkInstallRsatComponent Rsat.ServerManager.Tools
    checkInstallRsatComponent Rsat.GroupPolicy.Management.Tools
    checkInstallRsatComponent Rsat.RemoteDesktop.Services.Tools
    
    # Rsat.BitLocker.Recovery.Tools~~~~0.0.1.0
    # Rsat.CertificateServices.Tools~~~~0.0.1.0
    # Rsat.FailoverCluster.Management.Tools~~~~0.0.1.0
    # Rsat.FileServices.Tools~~~~0.0.1.0
    # Rsat.IPAM.Client.Tools~~~~0.0.1.0
    # Rsat.LLDP.Tools~~~~0.0.1.0
    # Rsat.NetworkController.Tools~~~~0.0.1.0
    # Rsat.NetworkLoadBalancing.Tools~~~~0.0.1.0
    # Rsat.RemoteAccess.Management.Tools~~~~0.0.1.0
    # Rsat.Shielded.VM.Tools~~~~0.0.1.0
    # Rsat.StorageMigrationService.Management.Tools~~~~0.0.1.0
    # Rsat.StorageReplica.Tools~~~~0.0.1.0
    # Rsat.SystemInsights.Management.Tools~~~~0.0.1.0
    # Rsat.VolumeActivation.Tools~~~~0.0.1.0
    # Rsat.WSUS.Tools~~~~0.0.1.0
    #Update-Help
}
else
{
	log "* RSAT from Choco !"
    doChocoInstall rsat
}
 
disableWindowsUpdate

downloadIfNeeded https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/LGPO.zip LGPO.zip
downloadIfNeeded https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/PolicyAnalyzer.zip PolicyAnalyzer.zip

if( $VersionWindows -eq "7")
{ 
    log "install 7"
}
else
{
    if( $versionBuild -eq 14393)
    { 
        log "install 10.1607"
        downloadIfNeeded https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/Windows%2010%20Version%201607%20and%20Windows%20Server%202016%20Security%20Baseline.zip Windows10.1607-SecurityBaseline.zip
        downloadIfNeeded https://download.microsoft.com/download/1/D/8/1D8B5022-5477-4B9A-8104-6A71FF9D98AB/WindowsTH-KB2693643-x86.msu WindowsTH-KB2693643-x86.msu
    }
    
    if( $versionBuild -eq 16299)
    { 
        log "install 10.1709"
        downloadIfNeeded https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/Windows%2010%20Version%201709%20Security%20Baseline.zip Windows10.1709-SecurityBaseline.zip
    }
    
    if( $versionBuild -eq 17134)
    { 
        log "install 10.1803"
        downloadIfNeeded "https://download.microsoft.com/download/6/F/3/6F36772D-B61A-4B43-B636-7ACD759DC154/Administrative%20Templates%20(.admx)%20for%20Windows%2010%20April%202018%20Update.msi" "Windows10.1803-SecurityBaseline.zip"
    }
    
    if( $versionBuild -ge 17763)
    { 
        log "install 10.1809"
        downloadIfNeeded "https://download.microsoft.com/download/6/F/3/6F36772D-B61A-4B43-B636-7ACD759DC154/Administrative%20Templates%20(.admx)%20for%20Windows%2010%20April%202018%20Update.msi" "Windows10.1803-SecurityBaseline.zip"
    }

}

log "* Install RSAT FIN"
return 0

