$ErrorActionPreference = 'SilentlyContinue'

$vmConfiguration = $args[0]
$vmVersionMajeurCible = $args[1]
initializeContextDomain $vmConfiguration $vmVersionMajeurCible

Set-ExecutionPolicy Bypass -Scope Process -Force

ciPingIp 192.168.0.1
ciPingIp 192.168.0.253
ciPingIp 192.168.232.2

ciPingHost gateway.ac-test.fr
ciPingHost hestia.eole.lan
ciPingHost $adRealm

if( $versionMajor -lt 10)
{
    Write-Host "test-connectivite: pas de Resolve-DnsName sur win7/2012"
}
else
{
    Write-Host "test-connectivite: Get-NetRoute"
    Get-NetRoute

    Write-Host "test-connectivite: Resolve-DnsName $adRealm"
    Resolve-DnsName "$adRealm" -ErrorAction SilentlyContinue
}

Write-Host "exit 0"
