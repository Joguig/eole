. c:\eole\EoleCiTestsCommon.ps1 -debug $true

function test()
{
    $NetworkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID('DCB00C01-570F-4A9B-8D69-199FDBA5723B'))
    if (!$NetworkListManager)
    {
        return
    }
    
    # Set enums for GetNetworks
    $NLM_ENUM_NETWORK_CONNECTED=1
    $NLM_ENUM_NETWORK_DISCONNECTED=2
    $NLM_ENUM_NETWORK_ALL=3
    
    $Networks = $NetworkListManager.GetNetworks($NLM_ENUM_NETWORK_CONNECTED)
    if ( !$Networks)
    {
        return 
    }

    # Network category
    $NetCategories = New-Object -TypeName System.Collections.Hashtable
    $NetCategories.Add(0x00,"NLM_NETWORK_CATEGORY_PUBLIC")
    $NetCategories.Add(0x01,"NLM_NETWORK_CATEGORY_PRIVATE")
    $NetCategories.Add(0x02,"NLM_NETWORK_CATEGORY_DOMAIN_AUTHENTICATED")
    
    # Domain type
    $DomainTypes = New-Object -TypeName System.Collections.Hashtable
    $DomainTypes.Add(0x00,"NLM_DOMAIN_TYPE_NON_DOMAIN_NETWORK")
    $DomainTypes.Add(0x01,"NLM_DOMAIN_TYPE_DOMAIN_NETWORK")
    $DomainTypes.Add(0x02,"NLM_DOMAIN_TYPE_DOMAIN_AUTHENTICATED")
    
    foreach($Network in $Networks)
    {
        log ("Network name : " + $Network.GetName() )
        
        # Values from INetworkListManager interface https://msdn.microsoft.com/en-us/library/windows/desktop/aa370769(v=vs.85).aspx
        log ("  NetCategories : " + $NetCategories.Get_Item($Network.GetCategory()))
        
        log ("  DomainTypes : " + $DomainTypes.Get_Item($Network.GetDomainType()))
        
        # Display all active connectivity types (method c)
        $connectivity = $Network.GetConnectivity()
        if( $connectivity -band 0x0000) {"  NLM_CONNECTIVITY_DISCONNECTED"}
        if( $connectivity -band 0x0001) {"  NLM_CONNECTIVITY_IPV4_NOTRAFFIC"}
        if( $connectivity -band 0x0002) {"  NLM_CONNECTIVITY_IPV6_NOTRAFFIC"}
        if( $connectivity -band 0x0010) {"  NLM_CONNECTIVITY_IPV4_SUBNET"}
        if( $connectivity -band 0x0020) {"  NLM_CONNECTIVITY_IPV4_LOCALNETWORK"}
        if( $connectivity -band 0x0040) {"  NLM_CONNECTIVITY_IPV4_INTERNET"}
        if( $connectivity -band 0x0100) {"  NLM_CONNECTIVITY_IPV6_SUBNET"}
        if( $connectivity -band 0x0200) {"  NLM_CONNECTIVITY_IPV6_LOCALNETWORK"}
        if( $connectivity -band 0x0400) {"  NLM_CONNECTIVITY_IPV6_INTERNET"}
    }
}












































































































































































































































function doConfigureNicIpv4($context, $nicId, $ip, $netmask, $dns, $dnsSuffix, $gateway, $network, $mtu )
{
    #log "doConfigureNicIpv4 $nicId $ip"

    $macKey = "ETH" + $nicId + "_MAC"
    $mac    = $context[$macKey]

    if (!$mac) 
    {
        log "* doConfigureNicIpv4 $nicId " + $mac + "  pas de mac !"
        return
    }
    $mac = $mac.ToUpper()

    if (!$netmask) 
    {
        $netmask = "255.255.255.0"
    }
    if (!$network) 
    {
        $network = $ip -replace "\.[^.]+$", ".0"
    }
    if ($nicId -eq 0 -and !$gateway) 
    {
        $gateway = $ip -replace "\.[^.]+$", ".1"
    }

    # Load the NIC Configuration Object
    $nic = $false
    $retry = 30
    do {
        $retry--
        Start-Sleep -s 1
        $nic = Get-WMIObject Win32_NetworkAdapterConfiguration | where {$_.IPEnabled -eq "TRUE" -and $_.MACAddress -eq $mac}
    } while (!$nic -and $retry)

    If (!$nic) 
    {
        log "* doConfigureNicIpv4 $nicId " + $mac + "  ... Failed: Interface with MAC not found"
        return
    }

    Get-NetAdapter -Physical | Select Name,MACAddress -ErrorAction Stop
    
    $na | Where MACddress -eq "$mac"
    Get-NetAdapter -Physical | Where MACddress -eq "$mac"
    
    log ("* doConfigureNicIpv4 $nicId '" + $nic.Description.ToString() + "'")

    # Release the DHCP lease, will fail if adapter not DHCP Configured
    if( $nic.DHCPEnabled )
    {
        Log "- Release DHCP Lease"
        $ret = $nic.ReleaseDHCPLease()
        If ($ret.ReturnValue) 
        {
            log ("  ... Failed: " + $ret.ReturnValue.ToString())
        }
        Else 
        {
            log "  ... Success"
        }
    }

    if (!$ip) 
    {
        log "doConfigureNicIpv4 $nicId : pas d'ip static, stop"
        return
    }
    
    # set static IP address and retry for few times if there was a problem
    # with acquiring write lock (2147786788) for network configuration
    # https://msdn.microsoft.com/en-us/library/aa390383(v=vs.85).aspx
    $retry = 10
    do 
    {
        $retry--
        Start-Sleep -s 1
        $ret = $nic.EnableStatic($ip , $netmask)
    } 
    while ($ret.ReturnValue -eq 2147786788 -and $retry);
    If ($ret.ReturnValue)
    {
        log ("- Set Static IP $ip : Failed: " + $ret.ReturnValue.ToString())
    }
    Else
    {
        log "- Set Static IP $ip : Success"
    }
        
    # Set IPv4 MTU
    if ($mtu)
    {
        
        netsh interface ipv4 set interface $nic.InterfaceIndex mtu=$mtu

        If ($?) {
            log "- Set MTU: ${mtu} : Success"
        } Else {
            log "- Set MTU: ${mtu} : Failed"
        }
    }

    if (!$gateway) 
    {
        log "* doConfigureNicIpv4 $nicId pas de gateway, stop"
        return
    }
    
    # Set the Gateway
    $ret = $nic.SetGateways($gateway)
    If ($ret.ReturnValue) 
    {
        log ("- Set Gateway $gateway : Failed: " + $ret.ReturnValue.ToString())
    }
    Else
    {
        log "- Set Gateway $gateway : Success"
    }
            
    if (!$dns) 
    {
        log "  pas de dns, stop"
        return
    }

    # DNS Servers
    $dnsServers = $dns -split " "
    # DNS Server Search Order
    
    $ret = $nic.SetDNSServerSearchOrder($dnsServers)
    If ($ret.ReturnValue)
    {
        log ("- Set DNS Server Search Order $dnsServers : Failed: " + $ret.ReturnValue.ToString())
    }
    Else
    {
        log "- Set DNS Server Search Order $dnsServers : Success"
    }
    
    # Set Dynamic DNS Registration
    
    $ret = $nic.SetDynamicDNSRegistration("TRUE")
    If ($ret.ReturnValue) 
    {
        log ("- Set Dynamic DNS Registration : Failed, " + $ret.ReturnValue.ToString())
    }
    Else
    {
        log "- Set Dynamic DNS Registration : Success"
    }
    # WINS Addresses
    # $nic.SetWINSServer($DNSServers[0], $DNSServers[1])
            
    if ($dnsSuffix) 
    {
        # DNS Suffixes
        $dnsSuffixes = $dnsSuffix -split " "

        # Set DNS Suffix Search Order
        
        $ret = ([WMIClass]"Win32_NetworkAdapterConfiguration").SetDNSSuffixSearchOrder(($dnsSuffixes))
        If ($ret.ReturnValue)
        {
            Log ("- Set DNS Suffix Search Order : Failed, " + $ret.ReturnValue.ToString())
        }
        Else 
        {
            Log "- Set DNS Suffix Search Order : Success"
        }

        # Set Primary DNS Domain
        
        $ret = $nic.SetDNSDomain($dnsSuffixes[0])
        If ($ret.ReturnValue)
        {
            Log ("- Set Primary DNS Domain : Failed, " + $ret.ReturnValue.ToString())
        }
        Else
        {
            Log "- Set Primary DNS Domain : Success"
        }
    }
    log "* doConfigureNicIpv4 $nicId : done ok"
}

function doConfigureNicIpv6($context, $nicId, $ip6, $ip6Prefix, $ip6ULA, $dns6, $dnsSuffix, $gw6 )
{
    #log "doConfigureNicIpv6 $nicId $ip6"

    $macKey = "ETH" + $nicId + "_MAC"
    $mac    = $context[$macKey]
    if (!$mac) 
    {
        log "doConfigureNicIpv $nicId " + $mac + "  pas de mac !"
        return
    }
    $mac    = $mac.ToUpper()

    if (!$ip6Prefix) 
    {
        $ip6Prefix = "64"
    }

    # Load the NIC Configuration Object
    $nic = $false
    $retry = 30
    do {
        $retry--
        Start-Sleep -s 1
        $nic = Get-WMIObject Win32_NetworkAdapterConfiguration | where {$_.IPEnabled -eq "TRUE" -and $_.MACAddress -eq $mac}
    } while (!$nic -and $retry)

    If (!$nic) 
    {
        log "* doConfigureNicIpv6 $nicId : " + $mac + "  ... Failed: Interface with MAC not found"
        return
    }
            
    if ($ip6) 
    {
        log ("* doConfigureNicIpv6 $nicId : '" + $nic.Description.ToString() + "'")
    
        # We need the connection ID (i.e. "Local Area Connection",
        # which can be discovered from the NetworkAdapter object
        $na = Get-WMIObject Win32_NetworkAdapter | where {$_.deviceId -eq $nic.index}
        $na

        # Disable router discovery
        
        netsh interface ipv6 set interface $na.NetConnectionId advertise=disabled routerdiscover=disabled | Out-Null
        If ($?) 
        {
            Log "- Disable IPv6 router discovery : Success"
        }
        Else
        {
            Log "- Disable IPv6 router discovery : Failed"
        }

        # Remove old IPv6 addresses
        
        if (Get-Command Remove-NetIPAddress -errorAction SilentlyContinue) 
        {
            # Windows 8.1 and Server 2012 R2 and up
            # we want to remove everything except the link-local address
            Remove-NetIPAddress -InterfaceAlias $na.NetConnectionId `
                -AddressFamily IPv6 -Confirm:$false `
                -PrefixOrigin Other,Manual,Dhcp,RouterAdvertisement `
                -errorAction SilentlyContinue

            If ($?)
            {
                Log "- Removing old IPv6 addresses : Success"
            }
            Else
            {
                Log "- Removing old IPv6 addresses : Nothing to do"
            }
        }
        Else
        {
            Log "- Removing old IPv6 addresses : Not implemented"
        }

        # Set IPv6 Address
        
        netsh interface ipv6 add address $na.NetConnectionId $ip6/$ip6Prefix
        If ($? -And $ip6ULA) {
            netsh interface ipv6 add address $na.NetConnectionId $ip6ULA/64
        }

        If ($?) {
            Log "- Set IPv6 Address : Success"
        } Else {
            Log "- Set IPv6 Address : Failed"
        }

        # Set IPv6 Gateway
        if ($gw6) {
            
            netsh interface ipv6 add route ::/0 $na.NetConnectionId $gw6

            If ($?) {
                Log "- Set IPv6 Gateway : Success"
            } Else {
                Log "- Set IPv6 Gateway : Failed"
            }
        }

        # Set IPv6 MTU
        if ($mtu)
        {
            
            netsh interface ipv6 set interface $nic.InterfaceIndex mtu=$mtu

            If ($?)
            {
                Log "- Set IPv6 MTU ${mtu} : Success"
            }
            Else 
            {
                Log "- Set IPv6 MTU ${mtu} : Failed"
            }
        }

        # Remove old IPv6 DNS Servers
        
        Log "- Removing old IPv6 DNS Servers"
        netsh interface ipv6 set dnsservers $na.NetConnectionId source=static address=

        If ($dns6)
        {
            # Set IPv6 DNS Servers
            Log "- Set IPv6 DNS Servers $dns6"
            $dns6Servers = $dns6 -split " "
            foreach ($dns6Server in $dns6Servers) 
            {
                netsh interface ipv6 add dnsserver $na.NetConnectionId address=$dns6Server
            }
        }

        doPing($ip6)
        log "* doConfigureNicIpv6 $nicId : done ok"
    }
}

function doConfigureNic($context , $nicId)
{
    log "* doCnfigureNic $nicId"
    $nicPrefix = "ETH" + $nicId + "_"

    $ipKey        = $nicPrefix + "IP"
    $netmaskKey   = $nicPrefix + "MASK"
    $macKey       = $nicPrefix + "MAC"
    $dnsKey       = $nicPrefix + "DNS"
    $dnsSuffixKey = $nicPrefix + "SEARCH_DOMAIN"
    $gatewayKey   = $nicPrefix + "GATEWAY"
    $networkKey   = $nicPrefix + "NETWORK"
    $mtuKey       = $nicPrefix + "MTU"

    $ip           = $context[$ipKey]
    $netmask      = $context[$netmaskKey]
    $mac          = $context[$macKey]
    $dns          = $context[$dnsKey]
    $dns          = (($context[$dnsKey] -split " " | Where {$_ -match '^(([0-9]*).?){4}$'}) -join ' ')
    $dnsSuffix    = $context[$dnsSuffixKey]
    $gateway      = $context[$gatewayKey]
    $network      = $context[$networkKey]
    $mtu          = $context[$mtuKey]
    doConfigureNicIpv4 -context $context -nicId $nicId -ip $ip -netmask $netmask -dns $dns -dnsSuffix $dnsSuffix -gateway $gateway -network $network -mtu $mtu

    $ip6Key       = $nicPrefix + "IP6"
    $ip6ULAKey    = $nicPrefix + "IP6_ULA"
    $ip6PrefixKey = $nicPrefix + "IP6_PREFIX_LENGTH"
    $gw6Key       = $nicPrefix + "GATEWAY6"
    $ip6          = $context[$ip6Key]
    $ip6ULA       = $context[$ip6ULAKey]
    $ip6Prefix    = $context[$ip6PrefixKey]
    $gw6          = $context[$gw6Key]
    $dns6         = (($context[$dnsKey] -split " " | Where {$_ -match '^(([0-9A-F]*):?)*$'}) -join ' ')
    doConfigureNicIpv6 -context $context -nicId $nicId -ip6 $ip6 -ip6Prefix $ip6Prefix -ip6ULA $ip6ULA -dns6 $dns6 -dnsSuffix $dnsSuffix -gw6 $gw6 
    
    log "* configureNic $ipKey : fait"
}

function doConfigureNetwork($context)
{
    log "* configureNetwork"

    $nicId = 0;
    $nicIpKey = "ETH" + $nicId + "_IP"
    while ($context[$nicIpKey]) 
    {
        doConfigureNic $context $nicId
        $nicId++;
        $nicIpKey = "ETH" + $nicId + "_IP"
    }
}

function configureNetwork($context)
{
    log "* configureNetwork"
    $doSetNetworkStatic = $context["SET_NETWORK_STATIC"]
    if( $doSetNetworkStatic -eq "YES" )
    {
        if( -not ( checkFichierVmId "$systemDrive\eole\isNetworkConfigured.txt" ) ) 
        {
            doConfigureNetwork $context
        }
        else
        {
           log "* SET_NETWORK_STATIC : a déjà été effectué"
        }
    }
    else
    {
        log "* SET_NETWORK_STATIC : disabled"
    }
}

#doConfigureNetwork  $context
doConfigureNic $context 1
test