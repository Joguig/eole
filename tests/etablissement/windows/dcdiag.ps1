$vmConfiguration = $args[0]
$vmVersionMajeurCible = $args[1]
initializeContextDomain $vmConfiguration $vmVersionMajeurCible

Set-Location $env:TEMP

Write-Output "* - adRealm               = $adRealm"
Write-Output "* - adDomainAndUserAdmin  = $adDomainAndUserAdmin"
Write-Output "* - adPasswordAdmin       = $adPasswordAdmin"

diagnoseNetwork

Write-Output "******************************************************"
Write-Output "* - route delete 0.0.0.0 192.168.253.1"
CMD.EXE /C "route delete 0.0.0.0 192.168.253.1"

Write-Output "* - route print 192."
CMD.EXE /C "route print 192.*"

if ( $adRealm -eq "domseth.ac-test.fr" )
{
    ciPingIp 192.168.0.1

    Write-Output "******************************************************"
    Write-Output "* Test-ADAuthentication $adUserAdmin $adPasswordAdmin dc1.$adRealm $adDomain"
    try
    {
        Test-ADAuthentication "$adUserAdmin" "$adPasswordAdmin" "dc1.$adRealm" "$adDomain" 2>&1  
        Write-Output "* Test-ADAuthentication dc1 OK !"
    }
    catch
    {
        Write-Output "* Test-ADAuthentication dc1 Erreur !"
    }

    Write-Output "******************************************************"
    Write-Output "* Test-ADAuthentication $adUserAdmin $adPasswordAdmin dc2.$adRealm $adDomain"
    try
    {
        Test-ADAuthentication "$adUserAdmin" "$adPasswordAdmin" "dc2.$adRealm" "$adDomain"
        Write-Output "* Test-ADAuthentication dc2 OK !"
    }
    catch
    {
        Write-Output "* Test-ADAuthentication dc2 Erreur !"
    }

}
else
{
    Write-Output "******************************************************"
    Write-Host "* - Test-Connection 192.168.0.1 déactivé car pas Aca"

    Write-Output "******************************************************"
    Write-Output "* Test-ADAuthentication $adUserAdmin $adPasswordAdmin $adRealm $adDomain"
    try
    {
        Test-ADAuthentication "$adUserAdmin" "$adPasswordAdmin" "$adRealm" "$adDomain"
        Write-Output "* Test-ADAuthentication OK !"
    }
    catch
    {
        Write-Output "* Test-ADAuthentication Erreur !"
    }

}

Write-Output "******************************************************"
Write-Output "* - Test-Connection $adRealm "
ciPingHost $adRealm 

Write-Output "******************************************************"
Write-Output "* - nslookup.exe -type=ALL $adRealm"
CMD.EXE /C "nslookup.exe -type=ALL $adRealm"

Write-Output "* - nslookup.exe -type=ALL _ldap._tcp.dc._msdcs.$adRealm"
CMD.EXE /C "nslookup.exe -type=ALL _ldap._tcp.dc._msdcs.$adRealm"

$tests = @( 
    'CheckSDRefDom',
    'CheckSecurityError',
    'Connectivity',
    'CrossRefValidation',
    'CutoffServers',
    'DNS',
    'FrsSysVol',
    'FsmoCheck',
    'Intersite',
    'KccEvent',
    'KnowsOfRoleHolders',
    'LocatorCheck',
    'MachineAccount',
    'NCSecDesc',
    'NetLogons',
    'ObjectsReplicated',
    'OutboundSecureChannels',
    'Replications',
    'RidManager',
    'Services',
    'SystemLog',
    'SysVolCheck',
    'Topology',
    'VerifyEnterpriseReferences',
    'VerifyReplicas'
    )

#    'DFSREvent',
#    'FrsEvent',
#    'VerifyReferences',


foreach ($test in $tests) 
{
    Remove-Item c:\eole\$test.log -ErrorAction SilentlyContinue
    Remove-Item Z:\output\$vmOwner\$vmId\$test.log -ErrorAction SilentlyContinue
    Remove-Item Z:\output\$vmOwner\$vmId\$test.err -ErrorAction SilentlyContinue

    if ( $test -eq "Advertising" )
    {
        $diag = dcdiag /test:Advertising /v /d /i /s:$adRealm /u:$adDomainAndUserAdmin /p:$adPasswordAdmin | Out-File c:\eole\$test.log -Encoding utf8
    }
    else
    {
        dcdiag /test:$test /i /s:$adRealm /u:$adDomainAndUserAdmin /p:$adPasswordAdmin | Out-File c:\eole\$test.log -Encoding utf8
    }
    if ( Get-Content c:\eole\$test.log| Where-Object {$_ -like '*chou*'} )
    {
        Copy-Item c:\eole\$test.log Z:\output\$vmOwner\$vmId\$test.err
        Write-Output "EOLE_CI_PATH $test.err"
    }
    else
    {
        #Copy-Item c:\eole\$test.log Z:\output\$vmOwner\$vmId\$test.log
        Write-Output "             $test OK"
    }
}
Write-Output "****************************************************************************"
$diag

Write-Output "******************************************************"
Write-Output "* - nltest /dsgetdc:$adRealm"
nltest /dsgetdc:$adRealm 2>&1 | Write-Output

if ( $adRealm -eq "domseth.ac-test.fr" )
{
    Write-Output "******************************************************"
    Write-Output "* - nltest /dsgetdc:$adRealm /force"
    Write-Output "* - normalement nous avons basculé sur le Second DC !"
    nltest /dsgetdc:$adRealm /force 2>&1 | Write-Output
}

Write-Output "******************************************************"
Write-Output "* - Get-Acl -Path  \\$adRealm\SYSVOL"
Get-Acl -Path  \\$adRealm\SYSVOL 2>&1 | Write-Output

Write-Output "******************************************************"
Write-Output "* - Get-Acl -Path  \\$adRealm\NETLOGON"
Get-Acl -Path  \\$adRealm\NETLOGON 2>&1 | Write-Output

Write-Host "fin"