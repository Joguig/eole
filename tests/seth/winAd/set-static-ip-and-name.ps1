
Get-NetAdapter

#set static IP address
$ip = "192.168.0.73"
$ipprefix = "24"
$netmask = "255.255.255.0"
$gateway = "192.168.0.1"
$dns = "192.168.0.1"
$dnsSuffix = "domaca.ac-test.fr"

$ipif = (Get-NetAdapter).ifIndex

#Write-Host "New-Netip -ip $ip -PrefixLength $ipprefix -InterfaceIndex $ipif -DefaultGateway $gateway"
#New-Netip -ip $ip -PrefixLength $ipprefix -InterfaceIndex $ipif -DefaultGateway $gateway -ErrorAction SilentlyContinue

# Load the NIC Configuration Object
$nic = $false
$retry = 30
do {
    $retry--
    Start-Sleep -s 1
    $nic = Get-WMIObject Win32_NetworkAdapterConfiguration | where {$_.IPEnabled -eq "TRUE"}
} while (!$nic -and $retry)

If (!$nic) 
{
    Write-Host "Configuring Network Settings: " + $mac + "  ... Failed: Interface with MAC not found"
    Continue
}
        
 Write-Host "Configuring Network Settings: " + $nic.Description.ToString()
# Release the DHCP lease, will fail if adapter not DHCP Configured
Write-Host "- Release DHCP Lease"
$ret = $nic.ReleaseDHCPLease()
If ($ret.ReturnValue) 
{
    Write-Host "  ... Failed: " + $ret.ReturnValue.ToString()
}
Else 
{
    Write-Host "  ... Success"
}
                
# set static IP address and retry for few times if there was a problem
# with acquiring write lock (2147786788) for network configuration
# https://msdn.microsoft.com/en-us/library/aa390383(v=vs.85).aspx
Write-Host "- Set Static IP"
$retry = 10
do 
{
    $retry--
    Start-Sleep -s 1
    $ret = $nic.EnableStatic($ip, $netmask)
} 
while ($ret.ReturnValue -eq 2147786788 -and $retry);
If ($ret.ReturnValue)
{
    Write-Host "  ... Failed: " + $ret.ReturnValue.ToString()
}
Else
{
    Write-Host "  ... Success"
}
    
# Set the Gateway
Write-Host "- Set Gateway"
$ret = $nic.SetGateways($gateway)
If ($ret.ReturnValue) 
{
    Write-Host "  ... Failed: " + $ret.ReturnValue.ToString()
}
Else
{
    Write-Host "  ... Success"
}

# DNS Servers
$dnsServers = $dns -split " "
# DNS Server Search Order
Write-Host "- Set DNS Server Search Order"
$ret = $nic.SetDNSServerSearchOrder($dnsServers)
If ($ret.ReturnValue)
{
    Write-Host "  ... Failed: " + $ret.ReturnValue.ToString()
}
Else
{
    Write-Host "  ... Success"
}
    
# Set Dynamic DNS Registration
Write-Host "- Set Dynamic DNS Registration"
$ret = $nic.SetDynamicDNSRegistration("TRUE")
If ($ret.ReturnValue) 
{
    Write-Host "  ... Failed: " + $ret.ReturnValue.ToString()
}
Else
{
    Write-Host "  ... Success"
}

# DNS Suffixes
$dnsSuffixes = $dnsSuffix -split " "

# Set DNS Suffix Search Order
Write-Host "- Set DNS Suffix Search Order"
$ret = ([WMIClass]"Win32_NetworkAdapterConfiguration").SetDNSSuffixSearchOrder(($dnsSuffixes))
If ($ret.ReturnValue)
{
    Write-Host "  ... Failed: " + $ret.ReturnValue.ToString()
}
Else 
{
    Write-Host "  ... Success"
}

# Set Primary DNS Domain
Write-Host "- Set Primary DNS Domain"
$ret = $nic.SetDNSDomain($dnsSuffixes[0])
If ($ret.ReturnValue)
{
    Write-Host "  ... Failed: " + $ret.ReturnValue.ToString()
}
Else
{
    Write-Host "  ... Success"
}


[string]$computerName = "$env:computername"
Write-Host "* computerName = $computerName"
$newname = "wsad"

if ( $computerName -ne $newname )
{
    Write-Host "* rename to $newname"
    $ComputerInfo = Get-WmiObject Win32_ComputerSystem
    $r = $ComputerInfo.rename($newname)
    if ( $r.returnValue -eq 0 )
    {
        # je positionne avant d'avoir agit !!
        $vmId | Out-File -Encoding ASCII -FilePath "$systemDrive\eole\isRenamed.txt"
    }
}

Write-Host "fin"