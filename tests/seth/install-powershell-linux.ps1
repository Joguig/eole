

Write-Host [Environment]::GetEnvironmentVariable("PSModulePath")

Write-Host $env:HOMEPATH

Get-Module -ListAvailable
# rappel install 6.0.0-1:
#Manifest   1.1.0.0    Microsoft.PowerShell.Archive        {Compress-Archive, Expand-Archive}                                               
#Manifest   3.0.0.0    Microsoft.PowerShell.Host           {Start-Transcript, Stop-Transcript}                                              
#Manifest   3.1.0.0    Microsoft.PowerShell.Management     {Add-Content, Clear-Content, Clear-ItemProperty, Join-Path...}                   
#Manifest   3.0.0.0    Microsoft.PowerShell.Security       {Get-Credential, Get-ExecutionPolicy, Set-ExecutionPolicy, ConvertFrom-SecureS...
#Manifest   3.1.0.0    Microsoft.PowerShell.Utility        {Format-List, Format-Custom, Format-Table, Format-Wide...}                       
#Script     1.1.7.0    PackageManagement                   {Find-Package, Get-Package, Get-PackageProvider, Get-PackageSource...}           
#Script     1.6.0      PowerShellGet                       {Install-Module, Find-Module, Save-Module, Update-Module...}                     
#Script     0.0        PSDesiredStateConfiguration         {ThrowError, Get-PSMetaConfigDocumentInstVersionInfo, New-DscChecksum, Validat...
#Script     1.2        PSReadLine                          {Get-PSReadlineKeyHandler, Set-PSReadlineKeyHandler, Remove-PSReadlineKeyHandl...


# rappel install 6.2.3
    Directory: /home/gilles/.local/share/powershell/Modules

ModuleType Version    Name                                PSEdition ExportedCommands
---------- -------    ----                                --------- ----------------
Manifest   1.1        NtpTime                             Desk      Get-NtpTime
Script     3.0.1      PolicyFileEditor                    Desk      {Set-PolicyFileEntry, Remove-PolicyFileEntry, Get-PolicyFileEntry, Upd…
Script     2.1.3      SSHSessions                         Desk      {New-SshSession, Invoke-SshCommand, Enter-SshSession, Remove-SshSessio…
Script     1.0.0      WindowsCompatibility                Core      {Initialize-WinSession, Add-WinFunction, Invoke-WinCommand, Get-WinMod…
Script     1.0.0      WindowsPSModulePath                 Core,Desk Add-WindowsPSModulePath
Manifest   2.8.0.0    xWindowsUpdate                      Desk      

    Directory: /usr/local/share/powershell/Modules

ModuleType Version    Name                                PSEdition ExportedCommands
---------- -------    ----                                --------- ----------------
Script     2.0.0.9    ActiveDirectoryTools                Desk      {Import-WmiFiltersFromJson, Import-GPOPermissionsFromJson, Export-GPOB…
Manifest   1.0        nx                                  Desk      
Manifest   2.0.2      Posh-SSH                            Desk      {New-SSHDynamicPortForward, New-SFTPSymlink, Stop-SSHPortForward, New-…
Manifest   1.0.21     WriteToLogs                         Desk      {Write-ToLogOnly, Write-WithTime, Write-ToConsoleAndLog}
Manifest   2.16.0.0   xActiveDirectory                    Desk      

    Directory: /opt/microsoft/powershell/6/Modules

ModuleType Version    Name                                PSEdition ExportedCommands
---------- -------    ----                                --------- ----------------
Manifest   1.2.3.0    Microsoft.PowerShell.Archive        Desk      {Compress-Archive, Expand-Archive}
Manifest   6.1.0.0    Microsoft.PowerShell.Host           Core      {Start-Transcript, Stop-Transcript}
Manifest   6.1.0.0    Microsoft.PowerShell.Management     Core      {Add-Content, Clear-Content, Clear-ItemProperty, Join-Path…}
Manifest   6.1.0.0    Microsoft.PowerShell.Security       Core      {Get-Credential, Get-ExecutionPolicy, Set-ExecutionPolicy, ConvertFrom…
Manifest   6.1.0.0    Microsoft.PowerShell.Utility        Core      {Export-Alias, Get-Alias, Import-Alias, New-Alias…}
Script     1.3.2      PackageManagement                   Desk      {Find-Package, Get-Package, Get-PackageProvider, Get-PackageSource…}
Script     2.1.3      PowerShellGet                       Desk      {Find-Command, Find-DSCResource, Find-Module, Find-RoleCapability…}
Script     0.0        PSDesiredStateConfiguration         Desk      {ValidateNodeManager, Test-NodeManager, ConvertTo-MOFInstance, Generat…
Script     2.0.0      PSReadLine                          Desk      {Get-PSReadLineKeyHandler, Set-PSReadLineKeyHandler, Remove-PSReadLine…
Binary     1.1.2      ThreadJob                           Desk      Start-ThreadJob


Get-Process | Sort-Object CPU -Descending | Select-Object -First 5

Write-Host "* list Dir / "
Get-ChildItem -Path / | Select Name

#Write-Host "* get List of available Commands"
#Get-Command

Write-Host "* get all repo "
Get-PSRepository | Format-List *

Write-Host "* check PSReadline "
Find-Package -provider PowerShellGet PSReadline -allversions

Write-Host "* Create Get-PSGalleryModule "
function Get-PSGalleryModule
{
    [CmdletBinding(PositionalBinding = $false)]
    Param
    (
        # Required modules
        [Parameter(Mandatory = $true,
                   HelpMessage = "Please enter the PowerShellGallery.com modules required for this script",
                   ValueFromPipeline = $true,
                   Position = 0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]$ModulesToInstall
    ) #end param

    # NOTE: The newest version of the PowerShellGet module can be found at: https://github.com/PowerShell/PowerShellGet/releases
    # 1. Always ensure that you have the latest version 

    $Repository = "PSGallery"
    Set-PSRepository -Name $Repository -InstallationPolicy Trusted
    foreach ($Module in $ModulesToInstall)
    {
        Write-Host "* Get-PSGalleryModule $Module"
        # To avoid multiple versions of a module is installed on the same system, first uninstall any previously installed and loaded versions if they exist
        Uninstall-Module -Name $Module -AllVersions -Force -ErrorAction SilentlyContinue -Verbose

        # If the modules aren't already loaded, install and import it
        If (!(Get-Module -Name $Module))
        {
            # https://www.powershellgallery.com/packages/WriteToLogs
            Install-Module -Name $Module -Repository $Repository -Force -Verbose
            Import-Module -Name $Module -Verbose
        }
    }
}

# index 01
# Get any PowerShellGallery.com modules required for this script.
# Check contents of "Azure" module to see if it's ASM related
#Install-PackageProvider -Name Nuget -ForceBootstrap -Force
#Get-PSGalleryModule -ModulesToInstall "WriteToLogs"
#Get-PSGalleryModule -ModulesToInstall "Posh-SSH"
#Get-PSGalleryModule -ModulesToInstall "nx"
#err Get-PSGalleryModule -ModulesToInstall "Azure"
#Get-PSGalleryModule -ModulesToInstall "ActiveDirectoryTools"
Get-PSGalleryModule -ModulesToInstall "xActiveDirectory"

#pwsh -c "Invoke-Webrequest https://www.powershellgallery.com/api/v2/ -UseDefaultCredentials; Install-PackageProvider Nuget –force –verbose"


#cd $POWERSHELL_HOME
#git clone --recursive https://github.com/PowerShell/DscResources.git

#if ! grep "10.1.3.1" /etc/opt/omi/conf/dsc/dsc.conf
#then
#    echo "PROXY=http://admin:eole@10.1.3.1:3128/" >>/etc/opt/omi/conf/dsc/dsc.conf
#fi
#cat /etc/opt/omi/conf/dsc/dsc.conf

#ls -l /home/gilles/.local/share/powershell/Modules
#ls -l /usr/local/share/powershell/Modules
#ls -l /opt/microsoft/powershell/6.0.0-beta.3/Modules
# repertoire modules :
# /home/gilles/.local/share/powershell/Modules
# /usr/local/share/powershell/Modules
# /opt/microsoft/powershell/6.0.0-beta.3/Modules

# Paths utils
#   $PSHOME is /opt/microsoft/powershell/6.0.0-beta.3/
#   User profiles will be read from ~/.config/powershell/profile.ps1
#   Default profiles will be read from $PSHOME/profile.ps1
#   User modules will be read from ~/.local/share/powershell/Modules
#   Shared modules will be read from /usr/local/share/powershell/Modules
#   Default modules will be read from $PSHOME/Modules
#   PSReadline history will be recorded to ~/.local/share/powershell/PSReadLine/ConsoleHost_history.txt
# The profiles respect PowerShell's per-host configuration, so the default host-specific profiles exists at Microsoft.PowerShell_profile.ps1 in the same locations.


#sudo pwsh -c "Install-Package -Name ActiveDirectoryTools -Source https://www.powershellgallery.com/api/v2 -ProviderName NuGet -ExcludeVersion -Destination /home/gilles/.local/share/powershell/Modules"
#Install-Package -Name ActiveDirectoryTools -Source https://www.powershellgallery.com/api/v2 -ProviderName NuGet -ExcludeVersion

#Import-Module $POWERSHELL_HOME/PowerShellGet/tools/build.psm1; Install-Dependencies;
#Import-Module nx
#Import-Module ActiveDirectoryTools

#
#
#Import-Module nx
#Import-DscResource -Module nx
#Import-Module $POWERSHELL_HOME/DscResources/xDscResources/xActiveDirectory
#Import-Module $POWERSHELL_HOME/DscResources/xDscResources/xComputerManagement
#Import-Module $POWERSHELL_HOME/PowerShellGet/PowerShellGet

return 0