
. c:\eole\EoleCiFunctions.ps1

log "install-choco: début"

Write-Host "Test TLS 1.2 !"
[Enum]::GetNames([Net.SecurityProtocolType]) -contains 'Tls12'
[System.Net.ServicePointManager]::SecurityProtocol.HasFlag([Net.SecurityProtocolType]::Tls12)

try
{
  # Set TLS 1.2 (3072) as that is the minimum required by Chocolatey.org
  # Use integers because the enumeration value for TLS 1.2 won't exist
  # in .NET 4.0, even though they are addressable if .NET 4.5+ is installed (.NET 4.5 is an in-place upgrade).
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
}
catch
{
  Write-Warning 'Unable to set PowerShell to use TLS 1.2. This is required for contacting Chocolatey as of 03 FEB 2020. https://chocolatey.org/blog/remove-support-for-old-tls-versions. If you see underlying connection closed or trust errors, you may need to do one or more of the following: (1) upgrade to .NET Framework 4.5+ and PowerShell v3+, (2) Call [System.Net.ServicePointManager]::SecurityProtocol = 3072; in PowerShell prior to attempting installation, (3) specify internal Chocolatey package location (set $env:chocolateyDownloadUrl prior to install or host the package internally), (4) use the Download + PowerShell method of install. See https://docs.chocolatey.org/en-us/choco/installation for all install options.'
}


Write-Host "Test from windows desktop !"
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
    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
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

choco install chocolatey-windowsupdate.extension

log "install-choco: fin"