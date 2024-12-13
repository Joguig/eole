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

$nssm = 'C:\eole\download\nssm.exe'
$ScriptPath = 'C:\eole\run-from-context.ps1'
$ServiceName = 'EoleCiTestsDaemon'

#https://nssm.cc/release/nssm-2.24.zip

$ServicePath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
$ServiceArguments = '-ExecutionPolicy Bypass -NoProfile -File "{0}"' -f $ScriptPath

& $nssm install $ServiceName $ServicePath $ServiceArguments
Start-Sleep -Seconds .5
& $nssm install $ServiceName AppDirectory C:\eole
& $nssm install $ServiceName AppStdout C:\eole\$ServiceName.log
& $nssm install $ServiceName AppStderr C:\eole\$ServiceName.log
& $nssm install $ServiceName AppStopMethodSkip 6
& $nssm install $ServiceName AppStopMethodConsole 1000
#& $nssm install $ServiceName AppNoConsole 1
& $nssm install $ServiceName AppThrottle 5000

# check the status... should be stopped
& $nssm status $ServiceName

# start things up!
& $nssm start $ServiceName

# verify it's running
& $nssm status $ServiceName
