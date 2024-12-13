
. z:\scripts\windows\EoleCiFunctions.ps1

Log "* install-logiciels Début"

Set-Location c:\eole\download

#cf: https://chocolatey.org/docs/proxy-settings-for-chocolatey#installing-chocolatey-behind-a-proxy-server
#$env:chocolateyProxyLocation = 'https://local/proxy/server'
#$env:chocolateyProxyUser = 'username'
#$env:chocolateyProxyPassword = 'password'
# install script

if( $VersionWindows -eq "7")
{ 
    log "install 7"
    #Register-PackageSource -Name "chocolatey" -Location "http://chocolatey.org/api/v2/" -ProviderName "Choco" -Verbose
    downloadIfNeeded https://packages.chocolatey.org/chocolatey.0.10.11.nupkg chocolatey.0.10.11.nupkg
    
    Set-ExecutionPolicy Bypass -Scope Process -Force
    iex ((new-object net.webclient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

if( $versionMajor -ge 10)
{
    Set-ExecutionPolicy Bypass -Scope Process -Force
    iex ((new-object net.webclient).DownloadString('https://community.chocolatey.org/install.ps1'))

    Import-Module PackageManagement
    Install-PackageProvider -Name ChocolateyGet -verbose -Force
    Import-PackageProvider ChocolateyGet
}

# stop the -y flag being needed for all "choco install"s
choco feature enable --name allowGlobalConfirmation

doChocoInstall ChocolateyGUI
doChocoInstall autoit
doChocoInstall 7zip
doChocoInstall firefox
doChocoInstall thunderbird
doChocoInstall vlc
doChocoInstall wireshark
doChocoInstall openjdk11
doChocoInstall openjdk21
doChocoInstall Sysinternals
doChocoInstall treesizefree
doChocoInstall notepad2-mod
doChocoInstall sumatrapdf
doChocoInstall libreoffice

downloadIfNeeded http://ultimateoutsider.com/downloads/GWX_control_panel.exe GWX_control_panel.exe
downloadIfNeeded https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/LGPO.zip LGPO.zip
downloadIfNeeded https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/PolicyAnalyzer.zip PolicyAnalyzer.zip
downloadIfNeeded https://www.portablefreeware.com/download.php?dd=2811 fulleventlogview.zip
downloadIfNeeded https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.221-1/virtio-win.iso virtio-win.iso
Remove-Item c:\eole\download\virtio-win-0.1.171.iso -ErrorAction SilentlyContinue

if( $env:PROCESSOR_ARCHITECTURE -eq 'AMD64' )
{ 
    log "common AMD64"
}
else
{ 
    log "common X86"
}

if( $VersionWindows -eq "7")
{ 
    log "install 7"
}
else
{
    log "common win10 AMD64"
    #downloadIfNeeded https://ftp.hp.com/pub/softlib/software13/COL40842/ds-99376-19/upd-ps-x64-6.6.0.23029.exe upd-ps-x64-6.6.0.23029.exe
    choco download hp-universal-print-driver-ps --version 6.6.5.23510

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
    
    if( $versionBuild -ge 17758)
    { 
        log "install 10.1809"
        downloadIfNeeded "https://download.microsoft.com/download/6/F/3/6F36772D-B61A-4B43-B636-7ACD759DC154/Administrative%20Templates%20(.admx)%20for%20Windows%2010%20April%202018%20Update.msi" "Windows10.1803-SecurityBaseline.zip"
    }

    if( $versionBuild -ge 18362)
    { 
        $VersionWindows = "10.1903"
    }

    if( $versionBuild -ge 18363)
    { 
        $VersionWindows = "10.1909"
    }        

    if( $versionBuild -ge 19041)
    { 
        $VersionWindows = "10.2004"
    }        

    if( $versionBuild -ge 19042)
    { 
        $VersionWindows = "10.20H2"
    }        

    if( $versionBuild -ge 19043)
    { 
        $VersionWindows = "10.21H1"
    }        

    if( $versionBuild -ge 19044)
    { 
        $VersionWindows = "10.21H2"
    }        

    if( $versionBuild -ge 19045)
    { 
        $VersionWindows = "10.22H2"
    }        

    if( $versionBuild -ge 22000)
    { 
        $VersionWindows = "11"
    }

    if( $versionBuild -ge 22621)
    { 
        $VersionWindows = "11.22H2"
    }

}

Log "powercfg OFF"
powercfg -hibernate off

# Windows Subsystem for Linux
#Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
#DISM.exe /Online /Enable-Feature /FeatureName:Microsoft-Windows-Subsystem-Linux
#avec Chocolatey #cinst Microsoft-Windows-Subsystem-Linux -source windowsfeatures -y

# Windows configuration
#Set-ExplorerOptions -showFileExtensions -showHiddenFilesFoldersDrives -showProtectedOSFiles
#Set-TaskbarOptions -Size Large -Lock -Dock Bottom

# Disables the Bing Internet Search when searching from the search field in the Taskbar or Start Menu.
#Disable-BingSearch

#Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -DisableOpenFileExplorerToQuickAccess -EnableShowFileExtensions -EnableShowFullPathInTitleBar -EnableShowRecentFilesInQuickAccess -EnableShowFrequentFoldersInQuickAccess -EnableExpandToOpenFolder
 
#Show Powershell on Win+X instead of Command Prompt
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name DontUsePowerShellOnWinX -Value 0
 
#Enable-RemoteDesktop

# Update Windows and reboot if necessary
#Install-WindowsUpdate -AcceptEula -Full
#if (Test-PendingReboot) { Invoke-Reboot }

Remove-Item "c:\users\pcadmin\Desktop\Microsoft Edge.lnk" -ErrorAction silentlycontinue 
log "* install-logiciels FIN"
return 0

