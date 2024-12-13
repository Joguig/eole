
. c:\eole\EoleCiFunctions.ps1

enableWindowsUpdate

log "* Install OpenSSH server FIN"
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$AllUsersDesktopPath = [Environment]::GetFolderPath("CommonDesktopDirectory")

Set-Location c:\eole\download

if( $versionMajor -ge 10)
{
   log "* install type Windows 10"
   $sshCapability = Get-WindowsCapability -Online | Where-Object -Property Name -Like "OpenSSH.Server*"
      
   Log "* Add-WindowsCapability OpenSSH.Server"
   Add-WindowsCapability -Online -Name  OpenSSH.Server~~~~0.0.1.0

   Log "* Get-WindowsCapability OpenSSH.Server"
   $sshCapability = Get-WindowsCapability -Online | Where-Object -Property Name -Like "OpenSSH.Server*"
   
   Log "* dir OpenSSH.Server"
   Get-ChildItem C:\Windows\System32\OpenSSH\
   
   Log "* Get-Service sshd"
   $sshServerService = Get-Service -Name *sshd*
   $sshServerService
   
   Log "* Set-Service sshd Auto"
   Set-Service sshd -StartupType Automatic 
   
   Log "* Start sshd"
   Start-Service $sshServerService  
   
   Log "* netstat -ano"
   netstat -ano
   
   Log "* dir C:\ProgramData\ssh\"
   Get-ChildItem -Path 'C:\ProgramData\ssh\' 
   
   Log "* New-NetFirewallRule 22"
   New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
   
   # Confirm the Firewall rule is configured. It should be created automatically by setup. Run the following to verify
   if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled))
   {
       Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
       New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
   }
   else
   {
       Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
   }
   
   #ssh pcadmin@localhost
}
else
{
    $url = 'https://github.com/PowerShell/Win32-OpenSSH/releases/latest/'
    $request = [System.Net.WebRequest]::Create($url)
    $request.AllowAutoRedirect=$false
    $response=$request.GetResponse()
    $url64 = $([String]$response.GetResponseHeader("Location")).Replace('tag','download') + '/OpenSSH-Win64.zip'  
    $url32 = $([String]$response.GetResponseHeader("Location")).Replace('tag','download') + '/OpenSSH-Win32.zip'
    downloadIfNeeded $url64 "OpenSSH-Win64.zip"
    #wget $url64

    #$url = 'https://github.com/PowerShell/Win32-OpenSSH/releases/latest/'
    #$request = [System.Net.WebRequest]::Create($url)
    #$request.AllowAutoRedirect=$false
    #$response=$request.GetResponse()
    #$([String]$response.GetResponseHeader("Location")).Replace('tag','download') + '/OpenSSH-Win64.zip'  
    #$([String]$response.GetResponseHeader("Location")).Replace('tag','download') + '/OpenSSH-Win32.zip'
    #wget https://github.com/PowerShell/Win32-OpenSSH/releases/download/0.0.24.0/OpenSSH-Win64.zip
    # attention : turn off the Developer Mode SSH services. To turn off the SSH services, turn off Device Discovery
    # powershell -ExecutionPolicy Bypass -File install-sshd.ps1
    # .\ssh-keygen.exe -A
    # Powershell.exe -ExecutionPolicy Bypass -Command ". .\FixHostFilePermissions.ps1 -Confirm:$false"
    # Start-Service ssh-agent
    # 2012: New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Service sshd -Enabled True -Direction Inbound -Protocol TCP -Action Allow
    # desktop: netsh advfirewall firewall add rule name=sshd dir=in action=allow protocol=TCP service=sshd
    # Set-Service sshd -StartupType Automatic
    # Set-Service ssh-agent -StartupType Automatic
    #net start sshd    
    #
    # https://docs.microsoft.com/en-us/windows/uwp/get-started/enable-your-device-for-development
    # reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowAllTrustedApps" /d "1"
    # reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"
        
    #    (gci env:*).GetEnumerator() | Sort-Object Name | Out-String >$vmDir\postinstall.env
}

disableWindowsUpdate

log "* Install OpenSSH server FIN"
