Set-ExecutionPolicy unrestricted -force # not needed if already done once on the VM

Write-Host "* run-from-context Début"
[string]$systemDrive = "$env:SystemDrive"
[string]$computerName = "$env:computername"
[string]$ConnectionString = "WinNT://$computerName"
[int]$VersionWindows = [environment]::OSVersion.version.Major
Write-Host "* systemDrive=$systemDrive"
Write-Host "* computerName = $computerName"
Write-Host "* ConnectionString= $ConnectionString"
Write-Host "* VersionWindows= $VersionWindows"

if( $VersionWindows -lt 6)
{ 
    Write-Host "OS non supporté"
    return
}

Write-Host "* Get all drives and select only the one that has 'CONTEXT' as a label"
$contextDrive = Get-WMIObject Win32_Volume | ? { $_.Label -eq "CONTEXT" }
if ( -not ( $contextDrive ) ) 
{
    Write-Host "* pas de context ! stop"
    exit 0
}

Write-Host "* At this point we can obtain the letter of the contextDrive"
$contextLetter     = $contextDrive.Name
$contextScriptPath = $contextLetter + "context.sh"

Write-Host "* test existance $contextScriptPath "
if( -not ( Test-Path $contextScriptPath ) )
{
    Write-Host "* pas de ''context.sh'', stop"
    exit 0
}

Write-Host "* load context.sh"
$context = @{}
switch -regex -file $contextScriptPath {
    "^([^=]+)='(.+?)'$" {
        $name, $value = $matches[1..2]
        $context[$name] = $value
    }
}

Write-Host "* affiche context"
Write-Output $context

Write-Host "* runScripts "
$startScript64 = $context["INSTALL_SCRIPT_BASE64"]
if ($startScript64) 
{
    Write-Host "* Execute INSTALL_SCRIPT"
    $startScript = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($startScript64))
}
else
{
    Write-Host "* Execute INSTALL_SCRIPT "
    $startScript   = $context["INSTALL_SCRIPT"]
}

if ($startScript) 
{
    Write-Host "* Execute startScript"
    $startScriptPS = "$systemDrive\eole\opennebula-install-script.ps1"
    $startScript | Out-File $startScriptPS "UTF8"
    & $startScriptPS
    Write-Host "* fin execution startScript"
}

Write-Host "* run-from-context fin"
