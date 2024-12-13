$vmConfiguration = $args[0]
$vmVersionMajeurCible = $args[1]
initializeContextDomain $vmConfiguration $vmVersionMajeurCible

try
{
    # set network interface to private (reverted after dsc run) http://www.hurryupandwait.io/blog/fixing-winrm-firewall-exception-rule-not-working-when-internet-connection-type-is-set-to-public
    #([Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"))).GetNetworkConnections() | % { $_.GetNetwork().SetCategory(1) }

    # this setting persists only for the current session
    Enable-PSRemoting -SkipNetworkProfileCheck -Force

    & cmd @('/c', 'winrm', 'set', 'winrm/config', '@{MaxEnvelopeSizekb="8192"}')

    # j'autorise tous les PC à se connecter à cette machine !
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
}
Catch 
{ 
    $_ | Out-Host
    Write-Host "ERREUR: test-create-gpo" 
}


$cred = New-Object System.Management.Automation.PSCredential ($adDomainAndUserAdmin, $adSecurePasswordAdmin)

Invoke-Command -ComputerName "." -Credential $cred -ScriptBlock {
    $gpo = New-GPO -Name TestGPO -Comment "Test GPO"
    Start-Sleep -s 5
    $guid = $gpo.id.ToString().ToUpper()
    Write-Host "Group Policy Created: $guid"
    $domain = Get-ADDomain
    $forest = $domain.forest

    md "C:\Windows\SYSVOL\sysvol\$forest\Policies\{$guid}\Machine\Scripts\Shutdown"
    md "C:\Windows\SYSVOL\sysvol\$forest\Policies\{$guid}\Machine\Scripts\Startup"
    Copy-Item .\script_shutdown.ps1 "C:\Windows\SYSVOL\sysvol\$forest\Policies\{$guid}\Machine\Scripts\Shutdown"
    Copy-Item .\script_startup.ps1 "C:\Windows\SYSVOL\sysvol\$forest\Policies\{$guid}\Machine\Scripts\Startup"

    $pshellscript = @"

[Startup]
0CmdLine=script_startup.ps1
0Parameters=
[Shutdown]
0CmdLine=script_shutdown.ps1
0Parameters=
"@
    
    $psfilename = "C:\Windows\SYSVOL\sysvol\$forest\Policies\{$guid}\Machine\Scripts\psscripts.ini"
    $pshellscript | Out-File $psfilename -Encoding unicode
    $psfile = Get-Item $psfilename -force
    $psfile.attributes="Hidden"

    $gptini = @"
[General]
Version=2
displayName=New Group Policy Object
"@
    
    $gptinifilename = "C:\Windows\SYSVOL\sysvol\$forest\Policies\{$guid}\GPT.ini"
    $gptini | Out-File $gptinifilename -Encoding utf8

    # I don't know how this works
    # I copied these values from the GPO that was manually created and working
    $gPCMachineExtensionNames = "[{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B6664F-4972-11D1-A7CA-0000F87571E3}]"


    $adgpo = ([adsisearcher]"(&(objectCategory=groupPolicyContainer)(name={$guid}))").FindAll().Item(0)
    $gpoentry = $adgpo.GetDirectoryEntry()
    $gpoentry.Properties["gPCMachineExtensionNames"].Value = $gPCMachineExtensionNames
    $gpoentry.Properties["versionNumber"].Value = "2"
    $gpoentry.CommitChanges()
}

