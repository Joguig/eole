function log($t) {
    Write-Host $t
}

log "* Début"
[string]$systemDrive = "$env:SystemDrive"
[string]$computerName = "$env:computername"
[string]$ConnectionString = "WinNT://$computerName"
[int]$versionMajor = [environment]::OSVersion.version.Major
[int]$versionBuild = [environment]::OSVersion.version.Build
[int]$VersionWindows = 10

if( $versionMajor -lt 6)
{ 
    log "OS non supporte"
    return
}

log "* Get all drives and select only the one that has 'CONTEXT' as a label"
$contextDrive = Get-WMIObject Win32_Volume | ? { $_.Label -eq "CONTEXT" }
if ( -not ( $contextDrive ) ) 
{
    log "* pas de context ! stop"
    return
}

log "* At this point we can obtain the letter of the contextDrive"
$contextLetter     = $contextDrive.Name
$contextScriptPath = $contextLetter + "context.sh"

log "* test existance $contextScriptPath "
if( -not ( Test-Path $contextScriptPath ) )
{
    log "* pas de ''context.sh'', stop"
    return 
}

log "* load context.sh"
$context = @{}
switch -regex -file $contextScriptPath {
    "^([^=]+)='(.+?)'$" {
        $name, $value = $matches[1..2]
        $context[$name] = $value
    }
}

log "* affiche context"
Write-Output $context

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

$url = 'https://github.com/PowerShell/Win32-OpenSSH/releases/latest/'
$request = [System.Net.WebRequest]::Create($url)
$request.AllowAutoRedirect=$false
$response=$request.GetResponse()
$([String]$response.GetResponseHeader("Location")).Replace('tag','download') + '/OpenSSH-Win64.zip'  
$([String]$response.GetResponseHeader("Location")).Replace('tag','download') + '/OpenSSH-Win32.zip'
#wget https://github.com/PowerShell/Win32-OpenSSH/releases/download/0.0.24.0/OpenSSH-Win64.zip
# attention : turn off the Developer Mode SSH services. To turn off the SSH services, turn off Device Discovery
powershell -ExecutionPolicy Bypass -File install-sshd.ps1

# .\ssh-keygen.exe -A
# Powershell.exe -ExecutionPolicy Bypass -Command ". .\FixHostFilePermissions.ps1 -Confirm:$false"

Start-Service ssh-agent

# 2012: New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Service sshd -Enabled True -Direction Inbound -Protocol TCP -Action Allow
# desktop: netsh advfirewall firewall add rule name=sshd dir=in action=allow protocol=TCP service=sshd

Set-Service sshd -StartupType Automatic

Set-Service ssh-agent -StartupType Automatic

net start sshd    

# https://docs.microsoft.com/en-us/windows/uwp/get-started/enable-your-device-for-development
# reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowAllTrustedApps" /d "1"
# reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"

(gci env:*).GetEnumerator() | Sort-Object Name | Out-String >$vmDir\postinstall.env
log "* fin"
