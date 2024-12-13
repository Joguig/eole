param(
    [switch]$debug=$false,
    [string]$command="?"
)

function log($t) {
    Write-Host $t
}

function Get-Encoding
{
  param
  (
    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Alias('FullName')]
    [string]
    $Path
  )

  process 
  {
    $bom = New-Object -TypeName System.Byte[](4)
        
    $file = New-Object System.IO.FileStream($Path, 'Open', 'Read')
    
    $null = $file.Read($bom,0,4)
    $file.Close()
    $file.Dispose()
    
    $enc = [Text.Encoding]::ASCII
    if ($bom[0] -eq 0x2b -and $bom[1] -eq 0x2f -and $bom[2] -eq 0x76) 
      { $enc =  [Text.Encoding]::UTF7 }
    if ($bom[0] -eq 0xff -and $bom[1] -eq 0xfe) 
      { $enc =  [Text.Encoding]::Unicode }
    if ($bom[0] -eq 0xfe -and $bom[1] -eq 0xff) 
      { $enc =  [Text.Encoding]::BigEndianUnicode }
    if ($bom[0] -eq 0x00 -and $bom[1] -eq 0x00 -and $bom[2] -eq 0xfe -and $bom[3] -eq 0xff) 
      { $enc =  [Text.Encoding]::UTF32}
    if ($bom[0] -eq 0xef -and $bom[1] -eq 0xbb -and $bom[2] -eq 0xbf) 
      { $enc =  [Text.Encoding]::UTF8}
        
    [PSCustomObject]@{
      Encoding = $enc
      Path = $Path
    }
  }
}

function umountUnit
{
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $unitDisk
    )
    
    log "* umountUnit $unitDisk :"
    try
    {
        $driveZ = Get-PSDrive -PSProvider FileSystem -Name "$unitDisk"
        if ( -Not ( $driveZ  ) )
        {
            remove-PSDrive -Name "$unitDisk" -Force | Log
            log "* umountUnit $unitDisk : OK"
        }  
        else
        {
            log "* umountUnit $unitDisk : nom monte, ok"
        }
    }
    catch
    {
        log "* umountUnit $unitDisk : Erreur, ignore"
    }     
}

function mountUnit
{
    Param
    (
       [string] $unitDisk, 
       [string] $share,
       [string] $pathToTest
    )

    log "mountUnit $unitDisk, $share, $pathToTest "
    try
    {
        if( Test-Path $pathToTest )
        {
            0
            return
        }
        $pass = "eole"| ConvertTo-SecureString -AsPlainText -Force
        $Cred = New-Object System.Management.Automation.PsCredential('root',$pass)

        $driveZ = New-PSDrive -Name "$unitDisk" -PSProvider FileSystem -Root "$share" -Credential $Cred -Scope Global
        if( Test-Path $pathToTest )
        {
            log "mountUnit $unitDisk 1 : ok,  "
            0
            return
        }
        
        $driveZ = New-PSDrive -Name "$unitDisk" -PSProvider FileSystem -Root "$share" -Credential $Cred 
        if( Test-Path $pathToTest )
        {
            log "mountUnit $unitDisk 2 : ok,"
            0
            return
        }
        
        $driveZ = New-PSDrive -Name "$unitDisk" -PSProvider FileSystem -Root "$share"  -Scope Global
        if( Test-Path $pathToTest )
        {
            log "mountUnit $unitDisk 3 : ok,  "
            0
            return
        }

        $driveZ = New-PSDrive -Name "$unitDisk" -PSProvider FileSystem -Root "$share" 
        if( Test-Path $pathToTest )
        {
            log "mountUnit $unitDisk 4 : ok,  "
            0
            return
        }

        log "* mountUnit $unitDisk : erreur"
        2
        return  
    }
    catch
    {
        log "* mountUnit $unitDisk : Erreur.."
        log "* mountUnit $unitDisk : $_.Exception.Message"
        2
        return 
    }     
}


function checkFichierVmId( $file )
{
    if ( checkFichierVmIdNoLog $file )
    {
        log "* $file ==> true"
        return $true
    }
    else
    {
	    log "* $file ==> false"
	    return $false 
	}
}

function checkFichierVmIdNoLog( $file )
{
    if ( Test-Path $file )
    {
        $id = Get-Content $file
        if ( $id -eq $vmId )
        {
            return $true
        }
    }
    return $false 
}

function checkReturnValue( $ret )
{
    If ($ret.ReturnValue)
    {
        $msg = switch ([int] $ret.ReturnValue)
        {
            0        {'Successful completion, no reboot required'}
            1        {'Successful completion, reboot required'}
            64       {'Method not supported on this platform'}
            65       {'Unknown failure'}
            66       {'Invalid subnet mask'}
            67       {'An error occurred while processing an Instance that was returned'}
            68       {'Invalid input parameter'}
            69       {'More than 5 gateways specified'}
            70       {'Invalid IP  address'}
            71       {'Invalid gateway IP address'}
            72       {'An error occurred while accessing the Registry for the requested information'}
            73       {'Invalid domain name'}
            74       {'Invalid host name'}
            75       {'No primary/secondary WINS server defined'}
            76       {'Invalid file'}
            77       {'Invalid system path'}
            78       {'File copy failed'}
            79       {'Invalid security parameter'}
            80       {'Unable to configure TCP/IP service'}
            81       {'Unable to configure DHCP service'}
            82       {'Unable to renew DHCP lease'}
            83       {'Unable to release DHCP lease'}
            84       {'IP not enabled on adapter'}
            85       {'IPX not enabled on adapter'}
            86       {'Frame/network number bounds error'}
            87       {'Invalid frame type'}
            88       {'Invalid network number'}
            89       {'Duplicate network number'}
            90       {'Parameter out of bounds'}
            91       {'Access denied'}
            92       {'Out of memory'}
            93       {'Already exists'}
            94       {'Path, file or object not found'}
            95       {'Unable to notify service'}
            96       {'Unable to notify DNS service'}
            97       {'Interface not configurable'}
            98       {'Not all DHCP leases could be released/renewed'}
            100      {'DHCP not enabled on adapter'}
            default  {'Unknown Error '}
        }
        Write-Output ("  ... Failed: " + $msg)
    }
    Else 
    {
        Write-Output "  ... Success"
    }

}

function doConfigureDOMACA()
{
    Get-NetAdapter
    
    $ip = "192.168.0.73"
    $ipprefix = "24"
    $netmask = "255.255.255.0"
    $gateway = "192.168.0.1"
    $dns = "192.168.0.1"
    $dnsSuffix = "domaca.ac-test.fr"
    
    $ipif = (Get-NetAdapter).ifIndex
    
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
        $r = $ComputerInfo.rename($newname)
        if ( $r.returnValue -eq 0 )
        {
            # je positionne avant d'avoir agit !!
            $vmId | Out-File -Encoding ASCII -FilePath "$systemDrive\eole\isRenamed.txt"
        }
    }
}


function configureNetworkEole($context)
{
    log "* configureNetworkEole"
    $doSetNetworkEole = $context["SET_NETWORK_EOLE"]
    if( $doSetNetworkEole -eq "YES" )
    {
        if( -not ( checkFichierVmId "$systemDrive\eole\isNetworkConfigured.txt" ) ) 
        {
            doConfigureDOMACA
        }
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
    $nicIpKey = "ETH" + $nicId + "_MAC"
    while ($context[$nicIpKey]) 
    {
        doConfigureNic $context $nicId
        $nicId++;
        $nicIpKey = "ETH" + $nicId + "_MAC"
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
           log "* SET_NETWORK_STATIC : a d�j� �t� effectu�"
        }
    }
    else
    {
        log "* SET_NETWORK_STATIC : disabled"
    }
}


function setTimeZoneUtc($context)
{
    log "* DO_SET_TIMEZONE_UTC ?"

    $keyRtc = (Get-Item -LiteralPath HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation)
    $rtc = $keyRtc.GetValue("RealTimeIsUniversal")
    Log "  current RealTimeIsUniversal = $rtc"

    $setTimeZoneUtc = $context["DO_SET_TIMEZONE_UTC"]
    if( $setTimeZoneUtc -eq "YES" )
    {
        if ($rtc -ne 1) 
        {
            log "* DO_SET_TIMEZONE_UTC : not 1, must be enable, update.."
            Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation -Name "RealTimeIsUniversal" -Value "1"
            $rtc = $keyRtc.GetValue("RealTimeIsUniversal")
            Log "update RealTimeIsUniversal = $rtc"
        } 
        else
        {
            log "* DO_SET_TIMEZONE_UTC : ok, no update"
        }
    }
    else
    {
        if ( $rtc -eq 1) 
        {
            log "* DO_SET_TIMEZONE_UTC : not 0 ==> must be disable, update.."
            Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation -Name "RealTimeIsUniversal" -Value "1"
            $rtc = $keyRtc.GetValue("RealTimeIsUniversal")
            Log "update RealTimeIsUniversal = $rtc"
        } 
        else
        {
            log "* DO_SET_TIMEZONE_UTC : ok, no update"
        }
    }
    log "* DO_SET_TIMEZONE_UTC : done"
}

function UpdateFile( $fichier, $texte )
{
    Remove-Item $fichier -Force -ErrorAction Continue
    if ( Test-Path $fichier )
    {
        log "* remove $fichier : erreur, existe toujours"
    }
    Out-File -Encoding ASCII -FilePath "$fichier"  -InputObject $texte
    $raw1 = Get-Content $fichier 
    if ( $raw1 -ne $texte )
    {
        log "* update error"
    }
}

function UpdateFileIfNeeded( $fichier, $texte )
{
    if ( -not ( Test-Path "$fichier" ))
    {
        log "* create $fichier"
        Out-File -verbose -Encoding ascii -FilePath "$fichier" -InputObject $texte
    }
    else
	{
	    $raw = Get-Content $fichier
	    if ( $raw -ne $texte )
	    {
            log "* update $fichier from $raw to $texte"
            UpdateFile "$fichier" "$texte"
	    }
    }
}
     
function removeFichier( $fichier )
{
    try
    {
        if ( Test-Path $fichier )
        {
            log "* remove $fichier : to do"
            $Error.Clear()
            Remove-Item $fichier -Force -ErrorAction SilentlyContinue
            $Error
            if ( Test-Path $fichier )
            {
                log "* remove $fichier : erreur, existe toujours"
                
                log "* remove $fichier : icacls /grant"
                $Error.Clear()
                & icacls $fichier /grant "pcadmin:(OI)(CI)F" 
                $Error
                
                log "* remove $fichier : icacls /setowner"
                $Error.Clear()
                & icacls $fichier /setowner pcadmin 
                $Error
                
                $Error.Clear()
                Remove-Item $fichier -Force -ErrorAction SilentlyContinue 
                $Error
                if ( Test-Path $fichier )
                {
                    log "* remove $fichier : 2nd erreur, existe toujours"
                    return
                }
            }
        }
        log "* remove $fichier : OK"
    }
    catch
    {                                    
        log "* remove $fichier : NOK"
    }
}

function checkSaltMinionId( $saltDir )
{
    log "* checkSaltMinionId"

    if ( -Not( Test-Path $saltDir ) )
    {
        log "* checkSaltMinionId : pas de dossier Salt $saltDir"
        return
    }
    
    $ss = Get-Service salt-minion
    $statusMinion = $ss.Status
    $minionAttendu = "PC-$vmId"

    log "* checkSaltMinionId : test rights "
    try
    {
        $minionid = Get-Content $saltDir\conf\minion_id -ErrorAction Stop
    }
    catch [System.Management.Automation.ItemNotFoundException]
    {
        log "exception: not found"
    }
    catch
    {
        $n=$_.Exception.GetType().FullName
        log "exception: $n"
        $_ | Write-Host

        Set-PSDebug -Trace 1
        log "bad acls ! � minionid"
        Start-Transcript -Path "c:\eole\salt-icacls.log"
        try
        {
            log "set acls $saltDir"
            & icacls "$saltDir" /grant "pcadmin:(OI)(CI)F" /T

            $minionid = Get-Content "$saltDir\conf\minion_id"
            log "minionid after icacls = $minionid"
        }
        catch
        {
            $_ | Out-Host
            $Error.Clear()
        }
        finally
        {
            Stop-Transcript -ErrorAction SilentlyContinue
            log "finnaly icacls"
        }
        $Error.Clear()
    }

    log "minionid=$minionid, attendu=$minionAttendu"
    if ( $minionid -match $minionAttendu )
    {
        log "* checkSaltMinionId : minionId Ok"
        return 0
    }
    else
    {
        log "* checkSaltMinionId : minionId NOK"
    }
    
    Start-Transcript -Path "c:\eole\salt-clean-on-rename.log"
    try
    {
        log "Stop-Service salt-minion"
        Stop-Service salt-minion -Force

        log "status minion"
        Get-Service salt-minion

        log "remove minion_id"
        removeFichier "$saltDir\conf\minion_id"
        
        log "Start-Service salt-minion"
        Start-Service salt-minion
        
        log "salt-call saltutils.regen_keys"
        CMD.EXE /C "salt-call saltutils.regen_keys"
        
        log "* checkSaltMinionId : OK tag image"
        $vmId | Out-File -Encoding ASCII -FilePath "$systemDrive\eole\isSaltInit.txt"
    }
    catch
    {
        $_ | Out-Host
        $Error.Clear()
    }
    finally
    {
        Set-PSDebug -Trace 0
        Stop-Transcript -ErrorAction SilentlyContinue
    }
    return 0
}

function renameComputer($context)
{
    log "* renameComputer"
    $enableRenameAuto = $context["ENABLE_RENAMEAUTO"]
    if( $enableRenameAuto -eq "YES" )
    {
        log "* ENABLE_RENAMEAUTO : enable, check ..."
        if( -not ( checkFichierVmId "$systemDrive\eole\isRenamed.txt" ) ) 
        {
            log "* test si rename necessaire : $computerName = $hostname ?"
            if ( $computerName -ne $hostname )
            {
                log "* rename to $hostname"
                $r = $ComputerInfo.rename($hostname)
                if ( $r.returnValue -eq 0 )
                {
                    # je positionne avant d'avoir agit !!
                    $vmId | Out-File -Encoding ASCII -FilePath "$systemDrive\eole\isRenamed.txt"
                    
                    checkSaltMinionId "c:\salt"
                    checkSaltMinionId "$env:ProgramData\Salt Project\Salt"
                     
                    log "* rename --> Restart-Computer -Force"
                    Restart-Computer -Force 
                    
                    # on ne devrait pas venir ici ....
                    log "* rename --> Start-Sleep -s 100"
                    Start-Sleep -s 100
                    
                    log "* rename ==> exit 0"
                    # sortie du processus , donc du service sans erreur
                    [Environment]::Exit(0)
                    $true
                }
                else
                {
                    log "* rename ERREUR ==> $r.returnValue"
                    $false
                }
            }
            else
            {
                log "* le nom est d�j� $hostname"
                $vmId | Out-File -Encoding ASCII -FilePath "$systemDrive\eole\isRenamed.txt"
                $false
            }
        }
        else
        {
           log "* VM has been renamed "
           $false
        }
    }
    else
    {
        log "* ENABLE_RENAMEAUTO : disabled"
        $false
    }
}

Function Test-RegistryValue
{
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [String]$Path
        ,
        [Parameter(Position = 1, Mandatory = $true)]
        [String]$Name
        ,
        [Switch]$PassThru
    ) 

    process {
        if (Test-Path $Path) {
            $Key = Get-Item -LiteralPath $Path
            if ($Key.GetValue($Name, $null) -ne $null) {
                if ($PassThru) {
                    Get-ItemProperty $Path $Name
                } else {
                    $true
                }
            } else {
                $false
            }
        } else {
            $false
        }
    }
}

# cf : https://msdn.microsoft.com/fr-fr/library/windows/desktop/ee309553(v=vs.85).aspx
#@FirewallAPI.dll,-28502 (File/Print Sharing)
#@FirewallAPI.dll,-28752 (Remote Desktop)
#@FirewallAPI.dll,-32752 (Network Discovery)

function enableFileAndPrinterSharing()
{
    log "* enableFileAndPrinterSharing"
    $enableFileAndPrinterSharing = $context["ENABLE_FILE_PRINTER_SHARING"]
    if( $enableFileAndPrinterSharing -eq "YES" )
    {
        log "* ENABLE_FILE_PRINTER_SHARING : enable, check ..."
        if( -not ( checkFichierVmId "$systemDrive\eole\enableFileAndPrinterSharing.txt" ) ) 
        {
            log "* FileAndPrinterSharing to do"
            if( $versionMajor -lt 10)
            { 
                # Win 7
                log "* enableFileAndPrinterSharing : TODO win7"
            }
            else
            {
                # Win 10
                Enable-NetFirewallRule -Group "@FirewallAPI.dll,-28502"
            }
            $vmId | Out-File -Encoding ASCII -FilePath "$systemDrive\eole\enableFileAndPrinterSharing.txt"
        }
        else
        {
           log "* FileAndPrinterSharing actif "
        }
    }
    else
    {
        log "* ENABLE_FILE_PRINTER_SHARING : disabled"
    }
}

function disableFirewallPublic()
{
    log "* disableFirewallPublic"
    $disableFirewallPublic = $context["DISABLE_FIREWALL_PUBLIC"]
    if( $disableFirewallPublic -eq "YES" )
    {
        log "* DISABLE_FIREWALL_PUBLIC : disable, check ..."
        if ( -not ( checkFichierVmId "$systemDrive\eole\disableFirewallPublic.txt" ) )
        {
            if( $versionMajor -lt 10)
            { 
                # Win 7
                log "* disableFirewallPublic : TODO win7"
            }
            else
            {
                # Win 10
                Set-NetFirewallProfile -Profile Public -Enabled False
            }
            $vmId | Out-File -Encoding ASCII -FilePath "$systemDrive\eole\disableFirewallPublic.txt"
        }
        else
        {
           log "* disableFirewallPublic actif "
        }
    }
    else
    {
        log "* DISABLE_FIREWALL_PUBLIC : disabled"
    }
}


function enableRemoteDesktop()
{
    log "* enableRemoteDesktop"
    
    $enableRemoteDesktop = $context["ENABLE_REMOTE_DESKTOP"]
    if( $enableRemoteDesktop -eq "YES" )
    {
        log "* ENABLE_REMOTE_DESKTOP : enable, check ..."
        if ( -not ( checkFichierVmId "$systemDrive\eole\enableRemoteDesktop.txt" ) )
        {
            if( $versionMajor -lt 10)
            {
                # Enable Remote Desktop  
                log "*   Enable RDP"
                log "*   Windows 7 only - add firewall exception for RDP"
                netsh advfirewall Firewall set rule group="@FirewallAPI.dll,-28752" new enable=yes
                
                log "*   Enable TS Connection"
                $wmiTs = Get-WmiObject -Class Win32_TerminalServiceSetting -Namespace root\cimv2\TerminalServices
                # 1=New connections are allowed. If the ModifyFirewallException parameter is 1, then the Remote Desktop firewall exception is enabled., 
                # 1=Modify the firewall exception setting.
                $result = $wmiTs.SetAllowTsConnections(1,1)
                if($result.ReturnValue -eq 0) 
                {
                    Write-Host "* ==> Enabled RDP Successfully"
                } 
                else 
                {
                    Write-Host "* ==> Failed to enabled RDP"
                }
                
                log "*   Disable UserAuthentication TS Connection"
                $wmiTsGeneralSetting = Get-WmiObject -Class "Win32_TSGeneralSetting" -Namespace root\cimv2\TerminalServices -Filter "TerminalName='RDP-tcp'"
                $result = $wmiTsGeneralSetting.SetUserAuthenticationRequired(0) 
                if($result.ReturnValue -eq 0) 
                {
                    Write-Host "* ==> UserAuthentication TS Connection Successfully"
                } 
                else 
                {
                    Write-Host "* ==> UserAuthentication TS Connection Failed"
                }
            }
            else
            { 
                log "*   Windows 10 Remote Desktop on"
                Enable-NetFirewallRule -Group "@FirewallAPI.dll,-28752"
                log "*   Windows 10 Network Discovery on"
                Enable-NetFirewallRule -Group "@FirewallAPI.dll,-32752"
            }
            $vmId | Out-File -Encoding ASCII -FilePath "$systemDrive\eole\enableRemoteDesktop.txt"
        }
        else
        {
           log "* enableRemoteDesktop actif "
        }
    }
    else
    {
        log "* ENABLE_REMOTE_DESKTOP : disabled"
    }
}

function enablePing()
{
    log "* enablePing"
    $enablePing = $context["ENABLE_PING"]
    if( $enablePing -eq "YES" )
    {
        log "* ENABLE_PING : enable, check ..."
        if ( -not ( checkFichierVmId "$systemDrive\eole\enablePing.txt" ) )
        {
            log "*   Create firewall manager object"
            $FWM = new-object -com hnetcfg.fwmgr
    
            log "*   Get current profile"
            $pro=$fwm.LocalPolicy.CurrentProfile
            $pro.IcmpSettings.AllowInboundEchoRequest=$true
        
            $vmId | Out-File -Encoding ASCII -FilePath "$systemDrive\eole\enablePing.txt"
        }
        else
        {
           log "* enablePing actif "
        }
    }
    else
    {
        log "* ENABLE_PING : disabled"
    }
}


function runInitScripts()
{
    log "* runInitScripts DO_INITSCRIPTS ?"
    $doScripts = $context["DO_INITSCRIPTS"]
    if( $doScripts -eq "YES" )
    {
        log "* DO_INITSCRIPTS enable"
        $initscripts = $context["INIT_SCRIPTS"]
        if ($initscripts) 
        {
            if ( -not ( checkFichierVmId "$systemDrive\eole\isInitScriptExecuted.txt" ) )
            {
                foreach ($script in $initscripts.split(" ")) 
                {
                    $script = $contextLetter + $script
                    if (Test-Path $script) 
                    {
                        & $script
                    }
                }
                $vmId | Out-File -Encoding ASCII -FilePath "$systemDrive\eole\isInitScriptExecuted.txt"
            }
        }
        else
        {
            log "* pas de scripts $INIT_SCRIPTS"
        }
    }
    else
    {
        log "* DO_INITSCRIPTS : disabled"
    }
}

function runScriptContext {
    Param(
       [Parameter(Mandatory=$false)] [String]$scriptVar,
       [Parameter(Mandatory=$false)] [String]$semaphore
    )

    $key="DO_$scriptVar"
    log "* runScriptContext $key"
    $doScripts = $context[$key]
    if( $doScripts -eq "YES" )
    {
        $key = $scriptVar + "_BASE64"
        $script64 = $context[$key]
        if ($script64) 
        {
            log "* Execute $key"
            $script = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($script64))
        }
        else
        {
            log "* Execute $scriptVar"
            $script   = $context[$scriptVar]
        }
    
        if ($script) 
        {
            log "* Execute script $scriptVar"
            $scriptPS = "$systemDrive\eole\opennebula-startscript.ps1"
            $scriptPS | Out-File -Encoding UTF8 -FilePath $scriptPS 
            & $scriptPS
            log "* fin execution script $scriptVar"
        }
    }
    else
    {
        log "* $key : disabled"
    }
}

function joinDomain() 
{
    log "* JoinDomain domain=$sethDomain, user=$sethUser, pwd=$sethPasswdNotSecure"
    $sethPasswd = ConvertTo-SecureString $sethPasswdNotSecure -AsPlainText -Force
    $sethCredential = New-Object System.Management.Automation.PSCredential ($sethUser, $sethPasswd)
    try
    {
        if ( $computerName -ne $hostname )
        {
	        log "* Add Computer to $sethDomain with rename to $hostname" 
    	    $joinInfo = Add-Computer -ComputerName "." -NewName $hostname -DomainName $sethDomain -Credential $sethCredential -UnjoinDomainCredential $sethCredential -Verbose -Debug -PassThru -Force -ErrorAction Stop 
    	}
    	else
    	{
	        log "* Add Computer to $sethDomain" 
    	    $joinInfo = Add-Computer -DomainName $sethDomain -Credential $sethCredential -Options AccountCreate,JoinWithNewName -Verbose -Debug -PassThru -Force -ErrorAction Stop 
    	}
    	$joinInfo
        if ( $joinInfo.HasSucceeded )
        {
            $vmId | Out-File -Encoding ASCII -FilePath "$systemDrive\eole\domain-jointed.txt"
            $vmId | Out-File -Encoding ASCII -FilePath "$systemDrive\eole\isRenamed.txt"
        
            Write-Host "pc join au domaine OK!" -foregroundcolor green
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultDomainName" -Value "$sethDomain"
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableFirstLogonAnimation" -Value "0"
            return $true
        } 
        
    }
    catch
    {
        # pas trouv� d'autre moyen pour faire cela !!!
        $e = $_
        switch -regex ($e.Exception.Message) 
        {
    	  ".*car il se trouve*" 
    	  	 { 
    	  		log "l'ordinateur est d�j� inscrit !" 
	            $vmId | Out-File -Encoding ASCII -FilePath "$systemDrive\eole\domain-jointed.txt"
                $vmId | Out-File -Encoding ASCII -FilePath "$systemDrive\eole\isRenamed.txt"
    	  		return $true
    	  	 }
	      '.*unknown user name.*'     
	         {
	         'unknown user name' 
	         }
    	  '.*domain does not exist.*' 
    	     {
    	     'domain does not exist' 
    	     }
    	  default                     
    	     {
    	     'Unexpected error' 
    	     }
	    }
        Write-Host 'System Error Caught' -foregroundcolor red
        log "* ------------ " 
        $e
        log "* ------------ " 
        $Error.clear()
    }
	return $false
}

function eoleJoinDomain($newDNSServers,$sethDomain,$sethUser,$sethPasswdNotSecure) 
{
    log "* eoleJoinDomain dns=$newDNSServers, domain=$sethDomain, user=$sethUser, sethPasswdNotSecure=$sethPasswdNotSecure"
    $dnsServers = $newDNSServers -split " "

    $adapters = Get-WMIObject Win32_NetworkAdapterConfiguration | where {$_.IPEnabled -eq "TRUE" }
    $adapters | ForEach-Object {
        $nic = $_ 
        if ( $newDNSServers -ne "" )
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
        
            log "* Set dns to $$dnsServers " 
            $ret = $nic.SetDNSServerSearchOrder($dnsServers)
            If ($ret.ReturnValue) 
            {
                log ("  ... Failed: " + $ret.ReturnValue.ToString())
            }
            Else
            {
                log "  ... Success"
            }
            
            # Set Dynamic DNS Registration
            log "- Set Dynamic DNS Registration"
            $ret = $nic.SetDynamicDNSRegistration("TRUE")
            If ($ret.ReturnValue) 
            {
                log ("  ... Failed: " + $ret.ReturnValue.ToString())
            }
            Else
            {
                log "  ... Success"
            }
            # WINS Addresses
            # $nic.SetWINSServer($DNSServers[0], $DNSServers[1])
 
            # Set DNS Suffix Search Order
            Log "- Set DNS Suffix Search Order to '$sethDomain' "
            $ret = ([WMIClass]"Win32_NetworkAdapterConfiguration").SetDNSSuffixSearchOrder(($sethDomain))
            If ($ret.ReturnValue)
            {
                log ("  ... Failed: " + $ret.ReturnValue.ToString())
            }
            Else 
            {
                log "  ... Success"
            }

            # Set Primary DNS Domain
            Log "- Set Primary DNS Domain to '$sethDomain'"
            $ret = $nic.SetDNSDomain($sethDomain)
            If ($ret.ReturnValue)
            {
                log ("  ... Failed: " + $ret.ReturnValue.ToString())
            }
            Else
            {
                log "  ... Success"
            }
 
        }
    }

	Set-PSDebug -Trace 1

	if ( joinDomain )
    {
    	return $true
    }
	else
	{
        Write-Host "IMPOSSIBLE DE JOINDRE LE PC AU DOMAIN " -foregroundcolor red
        CMD.EXE /C "ipconfig /all"
    
        Get-NetRoute

        Test-Connection $sethDomain -ErrorAction Ignore

        nslookup.exe $sethDomain
    
        log "hostname            = $hostname"
        log "sethDomain          = $sethDomain"
        log "sethUser            = $sethUser"
        log "sethPasswdNotSecure = $sethPasswdNotSecure"
        return $false
	}
}

function doJoinDomain( $vmConfiguration) 
{
    if ( checkFichierVmId "$systemDrive\eole\domain-jointed.txt" )
    {
        log "* la machine a �t� jointe au domaine ==> ne rien faire "
        return
    }

	Start-Transcript -Path "c:\eole\join-domain.log"
	try 
	{
    	switch ( $vmConfiguration )
	    {
    	  domseth
        	      {
            	     eoleJoinDomain "192.168.0.5 192.168.0.6" "domseth.ac-test.fr" "DOMSETH\admin" "Eole12345!"
	              }
    	          
	      dompedago 
    	          {
        	         eoleJoinDomain "10.1.3.5 192.168.0.1" "dompedago.ac-test.fr" "DOMPEDAGO\admin" "Eole12345!"
            	  }
              
	      etb3 
    	          {
        	         eoleJoinDomain "10.3.2.5 192.168.0.1" "etb3.ac-test.fr" "ETB3\admin" "Eole12345!"
            	  }
              
	      domadmin 
    	          {
        	         eoleJoinDomain "10.1.1.10 192.168.0.1" "domadmin.ac-test.fr" "DOMADMIN\admin" "Eole12345!"
            	  }
              
	      domscribe
    	          {
        	        eoleJoinDomain "192.168.0.30 192.168.0.1" "domscribe.ac-test.fr" "DOMSCRIBE\admin" "eole"
	              }
	
	      default 
    	          {
        	         return $true
            	  }
        }
	}
	catch
	{
	    $_ | Out-Host 
	}
	finally
	{
		Set-PSDebug -Trace 0
		Stop-Transcript -ErrorAction SilentlyContinue
	}
}

function checkIfDoJoinDomain( $context) 
{
    log "* checkIfDoJoinDomain : ?"
    [string]$vmMethode = $context["VM_METHODE"]
    if ( $vmMethode -eq "domain" )
    {
        log "* checkIfDoJoinDomain : doit �tre int�gr�e au domain "
        $newDNSServers = ""
        [string]$vmDomaineServer = $context["VM_CONFIGURATION"]
        doJoinDomain $vmDomaineServer
    }
    else
    {
        log "* checkIfDoJoinDomain : pas demand� VM_METHODE=$vmMethode"
    }
}

function setNetworkPrivateConnection( $connection )
{
    log "* setNetworkPrivateConnection : début"
    if ( !$connection )
    {
        log "* setNetworkPrivateConnection : connection null "
        return $false
    }

    $reseau = $connection.GetNetwork()
    if ( !$reseau )
    {
        log "* setNetworkPrivateConnection : reseau null "
        return $false
    }

    $nomReseau = $reseau.GetName()

    $categorie = $reseau.GetCategory()
    If ($categorie -eq 1 )
    {
        log "* setNetworkPrivateConnection : R�seau $nomReseau est d�j� $categorie ==> OK"
        return $true 
    }

    $IsConnected = $connection.IsConnected
    $IsConnectedToInternet = $connection.IsConnectedToInternet
    log "* setNetworkPrivateConnection $nomReseau : Category = $categorie"
    log "* setNetworkPrivateConnection $nomReseau : IsConnected = $IsConnected"
    log "* setNetworkPrivateConnection $nomReseau : IsConnectedToInternet = $IsConnectedToInternet"
     
    Try
    {
        # Don't prompt for network location
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff" -Force -ErrorAction Continue
           
        if ( $IsConnected -eq $true )
        {
            log "* setNetworkPrivateConnection : SetCategory 1"
            $reseau.SetCategory(1)
        }
    }
    Catch
    {
        log "* setNetworkPrivateConnection : Impossible de bascule en category 1, exception"
        return $false
    }
    $categorie = $reseau.GetCategory()
    If ($categorie -ne 0 )
    {
        log "* setNetworkPrivate : Réseau $nomReseau est déjà $categorie ==> OK"
        return $true
    }
    else
    {
        log "ERROR setNetworkPrivateConnection : R�seau $nomReseau n'est pas pass� en private ==> NOK"
        return $false
    }
}

function setNetworkPrivate()
{
    log "* setNetworkPrivate DO_SET_NETWORK_PRIVATE ?"
    $doScripts = $context["DO_SET_NETWORK_PRIVATE"]
    if( $doScripts -eq "YES" )
    {
        log "* DO_SET_NETWORK_PRIVATE enable"
        if(1,3,4,5 -contains $ComputerInfo.DomainRole) 
        { 
            log "* setNetworkPrivate : Machine dans le domaine"
        }
        else
        {
            log "* setNetworkPrivate : Machine hors domaine, todo"

            # Determine if attached to domain network
            if (($versionMajor -gt 6) -or (($versionMajor -eq 6) -and ($versionBuild -gt 1)))
            {
                # First, get all Network Connection Profiles, and filter it down to only those that are domain networks
                $connections = Get-NetConnectionProfile | Where-Object {$_.NetworkCategory -eq "Public"}
                if ( $connections.Count -eq 0 )
                {
                	# ok fait!
                	return 
                }
	            log "* setNetworkPrivate : Machine hors domaine, todo"
                Get-NetConnectionProfile | Where-Object {$_.NetworkCategory -eq "Public"} | Set-NetConnectionProfile -NetworkCategory Private
                log "* DO_SET_NETWORK_PRIVATE : done"
            }
            else
            {
                # (Untested on Windows XP / Windows Server 2003)
                # Get-NetConnectionProfile is not available; need to access the Network List Manager COM object
                # So, we use the Network List Manager COM object to get a list of all network connections
                # Then we get the category of each network connection
                # Categories: 0 = Public; 1 = Private; 2 = Domain; see: https://msdn.microsoft.com/en-us/library/windows/desktop/aa370800(v=vs.85).aspx
                $domainNetworks = ([Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"))).GetNetworkConnections() | `
                    ForEach-Object {$_.GetNetwork().GetCategory()} | Where-Object {$_ -eq 0}
                if ( ! $domainNetworks )
                {
                    log "* setNetworkPrivate : par de connection public !"
                    log "* DO_SET_NETWORK_PRIVATE : done"
                    return 
                }
    	        try
                { 
                     $domainNetworks | Foreach-Object {
                            $connection = $_
                            $connection 
                            if ( setNetworkPrivateConnection $connection )
                            {
                            	$val = 100
                            	break
                            }
    	             }
                     log "* DO_SET_NETWORK_PRIVATE : done"
                }
                Catch
                {
                    $_ | Out-Host
                    log "* DO_SET_NETWORK_PRIVATE : exception"
                }
            }
        }
    }
    else
    {
        log "* DO_SET_NETWORK_PRIVATE : disabled"
    }
}


function ciCreateDir( $chemin )
{
    if( -not ( Test-Path $chemin ) )
    {
        log "ciCreateDir: $chemin" 
        $dir = New-Item -Path $chemin -ItemType Directory
        if( -not ( Test-Path $chemin ) )
        {
            Log "* ciCreateDir: $chemin impossible de le cr�er"  
        }
        
        # dans le Virtfs, le owner est 'oneadmin' inconnu de la machine local
        # il faut donc autoriser les drotis 'others' !
        #chmod 777 "$1"
    }
}

function ciSurveilleServiceArrete()
{
    Param
    (
       [string] $serviceName
    )
        
    Stop-Service $serviceName -Force -confirm -ErrorAction silentlycontinue
}

function ciLog( $texte, $output)
{
    Log "$texte"
    $texte | Out-File -Encoding UTF8 -Append "$output"
}

function ciExecute2( $fichierScriptLocal, $output, $fichierExit)
{
    $cdu = "-1"
    $OutEvent = $null
    $ErrEvent = $null
    $stream = $null
    $Error.Clear()
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
    try
    {
        if ( Test-Path $fichierExit )
        {
            Remove-Item $fichierExit
        }

        $stream = [System.IO.StreamWriter]::new($output)
        $stream.WriteLine("ciExecute2 $fichierScriptLocal ")

        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.RedirectStandardError = $true
        $pinfo.RedirectStandardOutput = $true
        $pinfo.UseShellExecute = $false
        $pinfo.CreateNoWindow = $true
        $pinfo.FileName = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
        $pinfo.Arguments = "-ExecutionPolicy Bypass -NoProfile -c & '$fichierScriptLocal'"

    	$Process = New-Object system.Diagnostics.Process
        $Process.StartInfo = $pinfo
        
        # Register Object Events for stdin\stdout reading
        $OutEvent = Register-ObjectEvent -Action {
            $stream.WriteLine( $Event.SourceEventArgs.Data )
        } -InputObject $Process -EventName OutputDataReceived

        $ErrEvent = Register-ObjectEvent -Action {
            $stream.WriteLine( $Event.SourceEventArgs.Data )
        } -InputObject $Process -EventName ErrorDataReceived
        
        # Start process
        [void]$Process.Start()

        # Begin reading stdin\stdout
        $Process.BeginOutputReadLine()
        $Process.BeginErrorReadLine()
        
        Start-Sleep -s 5
        do
        {
           Start-Sleep -Seconds 2
        }
        while (!$Process.HasExited)
        
        $cdu = $Process.ExitCode
        $stream.WriteLine("ExitCode ==> $cdu")
        $cdu | Out-File -Encoding ASCII -FilePath "$fichierExit"
    }
    Catch
    {
        $Error
        $stream.WriteLine( $Error )
        if ( -Not ( Test-Path $fichierExit ))
        {
            $stream.WriteLine( "Exit suite erreur ==> -1" )
            "-1" | Out-File -Encoding ASCII -FilePath "$fichierExit"
        }
        else
        {
            $stream.WriteLine( "Exit suite erreur MAIS le fichier d'exit est crée !")
        }
        $Error.Clear()
    }
    finally
    {
        if ( $ErrEvent )
        {
            Unregister-Event -SourceIdentifier $ErrEvent.name
        }
        
        if ( $OutEvent )
        {
            Unregister-Event -SourceIdentifier $OutEvent.name
        }
        
        if ( -Not ( Test-Path $fichierExit ))
        {
            $stream.WriteLine( "Exit sans fichierExit ==> $cdu" )
            $cdu | Out-File -Encoding ASCII -FilePath "$fichierExit"
        }

        if( $stream )
        {
            $stream.close()
        }
        
    }
}

function ciExecute( $fichierScriptLocal, $output, $fichierExit)
{
    $cdu = "-1"
    try
    {
        if ( Test-Path $fichierExit )
        {
            Remove-Item $fichierExit
        }

        $Error.Clear()
        $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
        #"ciExecute $fichierScriptLocal " | Out-File -Encoding UTF8 -FilePath $output
        # pour forcer la cr�ation du fichier !
        " " | Out-File -Encoding UTF8 -FilePath $output

        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.RedirectStandardError = $true
        $pinfo.RedirectStandardOutput = $true
        $pinfo.UseShellExecute = $false
        $pinfo.CreateNoWindow = $true
        $pinfo.FileName = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
        $pinfo.Arguments = "-ExecutionPolicy Bypass -NoProfile -c & '$fichierScriptLocal'"

        $Process = New-Object system.Diagnostics.Process
        $Process.StartInfo = $pinfo
        $Process.Start() 
        
        Start-Sleep -s 1
        do
        {
           $ligne = $Process.StandardOutput.ReadLine()
           ciLog $ligne $output
           Start-Sleep -MilliSeconds 500
        }
        while (!$Process.HasExited)
        
        while (!$Process.StandardOutput.EndOfStream)
        {
           $ligne = $Process.StandardOutput.ReadLine()
           ciLog $ligne $output
        }

        while (!$Process.StandardError.EndOfStream)
        {
           $ligne = $Process.StandardError.ReadLine()
           ciLog $ligne $output
        }

        $cdu = $Process.ExitCode
        ciLog "ExitCode ==> $cdu" $output
        $cdu | Out-File -Encoding ASCII -FilePath "$fichierExit"
    }
    Catch
    {
        $Error
        $Error | Out-File -Encoding UTF8 -FilePath $output -Append
        if ( -Not ( Test-Path $fichierExit ))
        {
            ciLog "Exit suite erreur ==> -1" $output
            "-1" | Out-File -Encoding ASCII -FilePath "$fichierExit"
        }
        else
        {
            ciLog "Exit suite erreur MAIS le fichier d'exit est cr�e !" $output
        }
        $Error.Clear()
    }
    finally
    {
        if ( -Not ( Test-Path $fichierExit ))
        {
            ciLog "Exit sans fichierExit ==> $cdu" $output
            $cdu | Out-File -Encoding ASCII -FilePath "$fichierExit"
        }
    }
}

function ciExecute1( $fichierScriptLocal, $output, $fichierExit)
{
    try
    {
        $Error.Clear()
        Log "ciExecute1 = $fichierScriptLocal"
    
        $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
        "ciExecute1 " | Out-File -Encoding UTF8 -FilePath $output
        
        $script = Get-Content -Path $fichierScriptLocal -Raw
        $scriptBlock = [scriptblock]::Create($script)
        $session = Get-PSSession
        $cdu = Invoke-Command -ScriptBlock $scriptBlock -Verbose

        ciLog "Exit ==> $cdu" $output
        if ( -Not ( Test-Path $fichierExit ))
        {
            $cdu | Out-File -Encoding ASCII -FilePath "$fichierExit"
        }
    }
    Catch
    {
        $Error | Out-File -Encoding UTF8 -FilePath $output -Append
        if ( -Not ( Test-Path $fichierExit ))
        {
            ciLog "Exit -1 ! " $output
            "-1" | Out-File -Encoding ASCII -FilePath "$fichierExit"
        }
    }
}

function ciExecuteScript( $fichierScript )
{
    try
    {
        $Error.Clear()
        Log "ciExecuteScript = $fichierScript"
    
        $script = Get-Content -Path "$fichierScript" -Raw
        $scriptBlock = [scriptblock]::Create($script)
        $cdu = Invoke-Command -ScriptBlock $scriptBlock -Verbose
        
        $cdu
    }
    Catch
    {
        -1
    }
}


#-----------------------------------------------------------------------------#
#                                                                             #
#   Function        Maintenant                                                #
#                                                                             #
#   Description     Get a string with the current time.                       #
#                                                                             #
#   Notes           The output string is in the ISO 8601 format, except for   #
#                   a space instead of a T between the date and time, to      #
#                   improve the readability.                                  #
#                                                                             #
#-----------------------------------------------------------------------------#
Function Maintenant
{
  Param (
    [Switch]$ms,        # Append milliseconds
    [Switch]$ns         # Append nanoseconds
  )
  
  $Date = Get-Date
  $now = ""
  $now += "{0:0000}-{1:00}-{2:00} " -f $Date.Year, $Date.Month, $Date.Day
  $now += "{0:00}:{1:00}:{2:00}" -f $Date.Hour, $Date.Minute, $Date.Second
  $nsSuffix = ""
  if ($ns) 
  {
    if ("$($Date.TimeOfDay)" -match "\.\d\d\d\d\d\d")
    {
      $now += $matches[0]
      $ms = $false
    }
    else
    {
      $ms = $true
      $nsSuffix = "000"
    }
  } 
  if ($ms)
  {
    $now += ".{0:000}$nsSuffix" -f $Date.MilliSecond
  }
  return $now
}

function mountZ()
{
    $ipEoleCiTest         = $context["VM_IP_EOLECITEST"]
    if ( -not ( $ipEoleCiTest ) )
    {
        $ipEoleCiTest = "192.168.0.253"
    }
    
    $partage = "\\$ipEoleCiTest\eolecitests"
    $cdu = mountUnit "Z" $partage "Z:\ModulesEole.yaml"
    $cdu
    return
}

function ciExecuteToDosPs1( $baseName )
{
    Log "############################################################################################"
    Log "base = $baseName"
    $output="$vmDirDone\$baseName.log"
    Log "output = $output"
    if ( Test-Path $output ) { remove-Item $output }
    $fichierExit="$vmDirDone\$baseName.exit"
    Log "fichierExit = $fichierExit"
    if ( Test-Path $fichierExit ) { remove-Item $fichierExit }
    $fichierScript="$vmDirrunning\$baseName.ps1"
    Log "fichierScript = $fichierScript"
    if ( Test-Path $fichierScript ) { remove-Item $fichierScript }
    
    Move-Item $f $fichierScript
    
    # avec Windows 10, il faut copier sur le disque avant de lancer. (protection anti virus venant du r�seau !)
    $fichierScriptLocal="c:\eole\$baseName.ps1"
    if ( Test-Path $fichierScriptLocal ) { remove-Item $fichierScriptLocal }
    Copy-Item $fichierScript $fichierScriptLocal

    Log "Commande TODO : $fichierScriptLocal vers $output"
    #Log "--------------------------------------------------------------------------------------------"
    #Get-Content -Path $fichierScriptLocal | Foreach-Object { Log "$_" }
    #Log "--------------------------------------------------------------------------------------------"
    
    if ( Test-Path $fichierScriptLocal ) 
    { 
        ciExecute $fichierScriptLocal $output $fichierExit
        if ( -Not ( Test-Path $fichierExit ))
        {
            Log "verification $fichierExit manquant !"
            "-1" | Out-File -Encoding ASCII -FilePath "$fichierExit"
        }
        else
        {
            Log "verification $fichierExit"
            Get-Content -Path $fichierExit | Foreach-Object { Log "$_" }
        }
    }
    Log "############################################################################################"
    # 10 secondes
    $tempsPause = 10
}

function ciCheckToDos( $base )
{
    $cduCheckToDos = 0
    $vmDirOutput="${base}\output\$vmOwner"
    $vmDir="$vmDirOutput\$vmId"
    $vmDirToDo="$vmDir\todo"
    $vmDirRunning="$vmDir\running"
    $vmDirDone="$vmDir\done"

    if ( -Not( Test-Path "${base}\ModulesEole.yaml" ) )
    { 
        "-1"
        return
    }
    
    ciCreateDir "${BASE}\status"
    ciCreateDir "${BASE}\output"
    ciCreateDir "$vmDirOutput"
    ciCreateDir "$vmDir"
    ciCreateDir "$vmDirToDo"
    ciCreateDir "$vmDirRunning"
    ciCreateDir "$vmDirDone"
        
    if ( -not ( Test-Path "$vmDir\env" ))
    {
        log "* save env"
        Get-Item env: | Sort-Object Name | %{ '{0}={1}' -f $_.Name, $_.Value
                                       $key = $_.Name
                                       $value = $_.Value
                                       $e = ""
                                       $e += "{0}={1}" -f $key, $value
                                       } | Out-File -Encoding UTF8 -FilePath "$vmDir\env"
    }
        
    UpdateFileIfNeeded "$vmDir\daemon.start" "$PID"
    UpdateFileIfNeeded "$vmDir\computername" "$computerName"

    # le fichier 'daemon.running' est modifier toutes les 10 secondes !
    $Date = Get-Date
    $d = ""
    $d += "{0:0000}-{1:00}-{2:00} " -f $Date.Year, $Date.Month, $Date.Day
    $d += "{0:00}:{1:00}" -f $Date.Hour, $Date.Minute
    Log $d
    UpdateFileIfNeeded "${vmDir}\daemon.running" "$d"
    
    $daemonPid = $PID
    UpdateFileIfNeeded "${vmDir}\daemon.pid" "$daemonPid"

    # enregistre l'ip
    try
    {
        $ipAddr = (Get-NetIPAddress | ?{ $_.AddressFamily -eq "IPv4" -and !($_.IPAddress -match "169" ) -and !($_.IPaddress -match "127" ) })
        $currentIp= $ipAddr[0].IPAddress
    }
    catch 
    {
        $currentIps = gwmi Win32_NetworkAdapterConfiguration |
                                    Where { $_.IPAddress } |
                                    Select -Expand IPAddress
        $currentIp=$currentIps[0]
    }
     
    if ( -Not ( $currentIp -eq $global:vmPreviousIp ) )
    {
        if ( $global:vmPreviousIp -ne "" )
        {
            log "$vmOwner $vmMachine $vmId Adresse(s) ip chang�e de '$global:vmPreviousIp' vers '$currentIp'"
            Log "Changement IP : $currentIp"
        }
        else
        {
            Log "IP actuelle : $currentIp"
        }
        $global:vmPreviousIp=$currentIp
        UpdateFileIfNeeded "${vmDir}\ip" "$currentIp"
    }

    if ( $vmName)
    {
        $vmMachineIdPath = "$vmDirOutput\${vmName}.id"
        UpdateFileIfNeeded "$vmMachineIdPath" "$vmId"
	}        

    Get-ChildItem $vmDirToDo | Foreach-Object {
        $f = $_.FullName
        if ( $f.EndsWith(".ps1") )
        {
            try
            {
                ciExecuteToDosPs1 $_.BaseName
            }
            Catch
            {
                $e = $_
                log "ciCheckToDos Error: $e"
                log "ciCheckToDos FailedItem: $e.Exception.ItemName"
                $Error.clear()
            }
        }
        if ( Test-Path $f ) 
        { 
            Remove-Item $f 
        }
        # une commande au moins a �t� execut�e
        $cduCheckToDos = 2
    }
    
    actualiseFichier "c:\eole\join-domain.log" "$vmDir\join-domain.log"
    actualiseFichier "c:\eole\salt-clean-on-rename.log" "$vmDir\salt-clean-on-rename.log" 
    
    $cduCheckToDos
    return
}

function actualiseFichier( $source, $destination)
{
    try 
    {
        if ( -Not ( Test-Path $source ) )
        {
           return 
        } 
        
        $sourceFile = Get-Item $source
        if ( -Not ( Test-Path $destination ) )
        {
        	Log "Actualise: $destination"
            Copy-Item $source $destination 
            return 
        } 
        else
        {
            $destinationFile = Get-Item $destination
            if ($destinationFile.LastWriteTime -gt $sourceFile.LastWriteTime)
            {
	        	Log "Actualise: $destination"
                Copy-Item $source $destination 
            }
        }
    }
    catch
    {
        log "actualiseFichier: Error: $_.Exception.Message"
        log "actualiseFichier: FailedItem: $_.Exception.ItemName"
    }    
}

function ciBoucleDExecution()
{
    log "* ciBoucleDExecution: d�but"

    # je memorise dans une variable le no de processus ==> s'il change
    $daemonPid="$pid"
    $pass = "eole"| ConvertTo-SecureString -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PsCredential('root',$pass)
    $tempsPause = 10
    
    Log "Deconnection F:"
    CMD.EXE /C "NET USE F: /DELETE /Y 2>NUL" 
    Log "Deconnection G:"
    CMD.EXE /C "NET USE G: /DELETE /Y 2>NUL" 
    Log "Deconnection Y:"
    CMD.EXE /C "NET USE Y: /DELETE /Y 2>NUL" 
    #Log "Deconnection Z:"
    #CMD.EXE /C "NET USE Z: /DELETE /Y 2>NUL" 

    if( $versionBuild -gt 16299)
    { 
        Log "Winget est présent $versionBuild"
        if ( -not( test-path "C:\Program Files\SSHFS-Win\bin\sshfs.exe" ) )
        {
            try
            {
                # --accept-package-agreements --accept-source-agreements
                & winget install WinFsp.WinFsp --exact --silent --source winget
            }
            Catch
            {
                log "doService Error: $_.Exception.Message"
                log "doService FailedItem: $_.Exception.ItemName"
            }
            try
            {
                # --accept-package-agreements --accept-source-agreements
                & winget install SSHFS-Win.SSHFS-Win --exact --silent --source winget
            }
            Catch
            {
                log "doService Error: $_.Exception.Message"
                log "doService FailedItem: $_.Exception.ItemName"
            }
        }
    }
    
    do
    {
	    setNetworkPrivate
    
        $enableRenameAuto = $context["ENABLE_RENAMEAUTO"]
        if( $enableRenameAuto -eq "YES" )
        {
            if( -not (checkFichierVmIdNoLog "$systemDrive\eole\isRenamed.txt") )
            {
                log "* ENABLE_RENAMEAUTO=YES, mais la machine n'a pas encore reboot�e ..."
                Start-Sleep -s 30
                continue
            }
        } 

        if ( -Not ( Test-Path "F:\ModulesEole.yaml" )) 
        {
            CMD.EXE /C "NET USE F: /DELETE /Y 2>NUL" 
            CMD.EXE /C "NET USE F: \\$ipEoleCiTest\eolecitests eole /USER:root"
        }
        
        #if ( -Not ( Test-Path "g:\eole-ci-tests\ModulesEole.yaml" )) 
        #{
        #    CMD.EXE /C "NET USE G: /DELETE /Y 2>NUL" 
        #    CMD.EXE /C "NET USE G: \\sshfs.r\root@192.168.253.1\mnt eole /USER:root"
        #}

        try
        {
            $cduCheckToDos = ciCheckToDos "F:"
            if ( $cduCheckToDos.count -gt 1 )
            {
                $cduCheckToDos = $cduCheckToDos[-1]
            }
            else
            {
                $cduCheckToDos = 0
            }
        }
        Catch
        {
            $e = $_
            $e | Out-Host
            $cduCheckToDos = 2
        }
        

        #if ( $cduCheckToDos -le 0 ) # -1
        #{
        #    try
        #    {
        #        $cduCheckToDos = ciCheckToDos "G:\eole-ci-tests"
        #        if ( $cduCheckToDos.count -gt 1 )
        #        {
        #            $cduCheckToDos = $cduCheckToDos[-1]
        #        }
        #         else
        #        {
        #            $cduCheckToDos = 0
        #        }
        #    }
        #    Catch
        #    {
        #        $e = $_
        #        $e | Out-Host
        #    }
        #}
        
        if ( $cduCheckToDos -eq 1 )
        {
            Log "Sortie demand�e"
            break
        }
        if ( $cduCheckToDos -eq 2 )
        {
            $tempsPause = 0
        }

        $tempsPause = 10
        Log "Pause ${tempsPause}..."
        Start-Sleep -s $tempsPause

    }
    while ($true)
    log "* ciBoucleDExecution: fin.."
}

Function doService( $origine ) 
{
    log "* doService d�marrage  $origine "

    configureNetworkEole $context
    configureNetwork $context
    
    #if ($context["ETH1_MAC"])
    #{ 
    #    doConfigureNic $context 1
    #}
    enableFileAndPrinterSharing $context
    enableRemoteDesktop
    enablePing
    
    $rtc = (Get-Item -LiteralPath HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation).GetValue("RealTimeIsUniversal")
    Log "* rtc = $rtc"
    
    [string]$vmConfiguration = $context["VM_CONFIGURATION"]
    if ( $vmConfiguration -eq "agent-jenkins" )
    {
        Log "* vmDaemon=$vmDaemon ==> agent jenkins"
        [string]$vmConfiguration = $context["VM_MACHINE"]
        # "agent-" ==> 5
        $vmAgent = $vmConfiguration.Substring( 6 )
        [string]$vmJnlpMac = $context["VM_JNLPMAC"]
        Log "start agent agent='$vmAgent' mac='vmJnlpMac'"

        Write-Host "get agent.jar"
        wget http://jenkins.eole.lan/jenkins/jnlpJars/agent.jar -O c:\Users\pcadmin\agent.jar

        Write-Host "start process java"
        start-process java.exe -ArgumentList "-jar","c:\Users\pcadmin\agent.jar","-jnlpUrl","http://jenkins.eole.lan/jenkins/computer/$vmAgent/slave-agent.jnlp","-secret","$vmJnlpMac","-workDir","c:\Users\pcadmin" -RedirectStandardOutput c:\eole\jenkins-agent.log -RedirectStandardError c:\eole\jenkins-agent-error.log  
    }

    $vmDaemon        = $context["VM_DAEMON"]
    Log "* vmDaemon=$vmDaemon ==> desktop"
    try
    {
        log "* vmDaemon=$vmDaemon ==> a lancer "
        ciBoucleDExecution
    }
    Catch
    {
        log "doService Error: $_.Exception.Message"
        log "doService FailedItem: $_.Exception.ItemName"
    }
    Log "* doService fin"
}

function ciBoucleContext()
{
    log "* ciBoucleContext: d�but"

    $pass = "eole"| ConvertTo-SecureString -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PsCredential('root',$pass)
    $BASE = "c:\eole\"
    do
    {
        Log "Connection ${BASE} OK"
        try
        {
            $cduCheckToDos = 0
            $vmDirOutput="c:\eole\output"
            $vmDir="c:\eole\"
            $vmDirToDo="$vmDir\todo"
            $vmDirRunning="$vmDir\running"
            $vmDirDone="$vmDir\done"
        
            ciCreateDir "$vmDirOutput"
            ciCreateDir "$vmDir"
            ciCreateDir "$vmDirToDo"
            ciCreateDir "$vmDirRunning"
            ciCreateDir "$vmDirDone"
             
            Get-ChildItem $vmDirToDo | Foreach-Object {
                $f = $_.FullName
                if ( $f.EndsWith(".ps1") )
                {
                    try
                    {
                        ciExecuteToDosPs1 $_.BaseName
                    }
                    Catch
                    {
                        log "ciBoucleContext Error: $_.Exception.Message"
                        log "ciBoucleContext FailedItem: $_.Exception.ItemName"
                    }
                }
                if ( Test-Path $f ) 
                { 
                    Remove-Item $f 
                }
                # une commande au moins a �t� execut�e
                $cduCheckToDos = 2
            }
        }
        Catch
        {
            $_
            log "ciBoucleContext Error: $_.Exception.Message"
            log "ciBoucleContext FailedItem: $_.Exception.ItemName"
        }
        Log "Pause 10..."
        Start-Sleep -s 10
    }
    while ($true)
    log "* ciBoucleContext: fin.."
}

Function extendPartitions($context)
{
    log "* Extend partitions"

    if( -not (checkFichierVmIdNoLog "$systemDrive\eole\isPartitionExtended.txt") )
    {
        log "* la partition est d�j� etendue ..."
        return
    }

    # je positionne avant d'avoir agit !!
    $vmId | Out-File -Encoding ASCII -FilePath "$systemDrive\eole\isPartitionExtended.txt"

    "rescan" | diskpart

    $disks = @()

    # Cmdlet 'Get-Partition' is not in older Windows/Powershell versions
    if (Get-Command -errorAction SilentlyContinue -Name Get-Partition)
    {
        if ([string]$context['GROW_ROOTFS'] -eq '' -or $context['GROW_ROOTFS'].ToUpper() -eq 'YES')
        {
            # Add at least C:
            $drives = "C: $($context['GROW_FS'])"
        }
        else
        {
            $drives = "$($context['GROW_FS'])"
        }

        $driveLetters = (-split $drives | Select-String -Pattern "^(\w):?[\/]?$" -AllMatches | %{$_.matches.groups[1].Value} | Sort-Object -Unique)

        ForEach ($driveLetter in $driveLetters) {
            $disk = New-Object PsObject -Property @{
                name=$null;
                diskId=$null ;
                partIds=@()
                }
            # TODO: in the future an AccessPath can be used instead of just DriveLetter
            $drive = (Get-Partition -DriveLetter $driveLetter)
            $disk.name = "$driveLetter" + ':'
            $disk.diskId = $drive.DiskNumber
            $disk.partIds += $drive.PartitionNumber
            $disks += $disk
        }
    }
    Else
    {
        # always resize at least the disk 0
        $disk = New-Object PsObject -Property @{
            name=$null;
            diskId=0 ;
            partIds=@()
            }

        # select all parts - preserve old behavior for disk 0
        $disk.partIds = "select disk $($disk.diskId)", "list partition" | diskpart | Select-String -Pattern "^\s+\w+ (\d+)\s+" -AllMatches | %{$_.matches.groups[1].Value}
        $disks += $disk
    }

    # extend all requested disk/part
    ForEach ($disk in $disks)
    {
        ForEach ($partId in $disk.partIds) 
        {
            if ($disk.name)
            {
                log "- Extend ($($disk.name)) Disk: $($disk.diskId) / Part: $partId"
            }
            Else
            {
                log "- Extend Disk: $($disk.diskId) / Part: $partId"
            }
            $diskId = $disk.diskId
            "select disk $diskId","select partition $partId","extend" | diskpart | Out-Null
        }
    }
}

Function doContext(  $origine )
{
    #updateScriptServices $contextLetter
    log "* doContext d�marrage  $origine "
    
    extendPartitions $context
    setTimeZoneUtc $context
    renameComputer $context 
    runInitScripts
    runScriptContext "START_SCRIPT" "isStartScript.txt"
    runScriptContext "INSTALL_SCRIPT" "isInstallScript.txt" 

    if ( -not ( $vmMachine -eq "daily" ) )
    {
        log "* Set-Service wuauserv disable"
        try{
            Set-Service -Name wuauserv -StartupType Disabled  -errorAction SilentlyContinue
            log "* Set-Service wuauserv disable OK"
        }
        catch
        {
            log "wuauserv disable Error: $_.Exception.Message"
            log "wuauserv disable FailedItem: $_.Exception.ItemName"
        }
        log "* Set-Service fdHost enable"
        try{
            Set-Service -Name fdHost -StartupType Automatic -errorAction SilentlyContinue
            log "* Set-Service fdHost enable OK"
        }
        catch
        {
            log "fdHost disable Error: $_.Exception.Message"
            log "fdHost disable FailedItem: $_.Exception.ItemName"
        }
        log "* Set-Service FDResPub enable"
        try{
            Set-Service -Name FDResPub -StartupType Automatic  -errorAction SilentlyContinue
            log "* Set-Service FDResPub enable OK"
        }
        catch
        {
            log "FDResPub disable Error: $_.Exception.Message"
            log "FDResPub disable FailedItem: $_.Exception.ItemName"
        }
    }
    else
    {
        Set-Service wuauserv -StartupType Automatic -ErrorAction Ignore
        Set-Service BITS -StartupType Automatic -ErrorAction Ignore
 
        log "* Start-Service wuauserv"
        Start-Service wuauserv -ErrorAction Ignore
 
        log "* Start-Service BITS"
        Start-Service BITS  -ErrorAction Ignore
    }

    checkSaltMinionId "c:\salt"
    checkSaltMinionId "$env:ProgramData\Salt Project\Salt"
    
    $vmDaemon = $context["VM_DAEMON"]
    try
    {
        log "* ciBoucleContext a lancer "
        ciBoucleContext
    }
    Catch
    {
        $e = $_
        log "doContext Error: $e.Exception.Message"
        log "doContext FailedItem: $e.Exception.ItemName"
    }
    Log "* doContext fin"
}


Function doInstall()
{
    log "* doInstall d�but"
    if( $env:PROCESSOR_ARCHITECTURE -eq 'AMD64' )
    { 
        $nssm = 'C:\eole\nssm64.exe'
    }
    else
    { 
        $nssm = 'C:\eole\nssm32.exe'
    }
    
    $ServiceName = 'EoleCiTestContext'
    $ss = Get-Service $ServiceName
    $ss
    & $nssm stop $ServiceName
    # sans confirmation
    & $nssm remove $ServiceName confirm
    
    $ServicePath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
    $ServiceArguments = '-ExecutionPolicy Bypass -NoProfile -File "C:\eole\EoleCiTestContext.ps1"'
    
    "NSSM Install"
    & $nssm install $ServiceName $ServicePath $ServiceArguments
    & $nssm set $ServiceName AppDirectory c:\eole
    & $nssm set $serviceName AppNoConsole 1
    & $nssm set $ServiceName AppStdout "c:\eole\$ServiceName.log" 
    & $nssm set $serviceName AppStdoutCreationDisposition 4
    & $nssm set $ServiceName AppStderr "c:\eole\$ServiceName.err" 
    & $nssm set $serviceName AppStderrCreationDisposition 4
    & $nssm set $serviceName AppThrottle 1500
    & $nssm set $serviceName AppExit Default Exit
    & $nssm set $serviceName ObjectName "LOCALSYSTEM"
    & $nssm set $serviceName AppRotateFiles 1
    & $nssm set $serviceName AppRotateOnline 0
    & $nssm set $serviceName AppRotateSeconds 86400
    & $nssm set $serviceName AppRotateBytes 1048576    
    
    "NSSM status"
    # check the status... should be stopped
    & $nssm status $ServiceName
    
    "NSSM start"
    # start things up!
    & $nssm start $ServiceName
    
    "NSSM status"
    # verify it's running
    & $nssm status $ServiceName
    
    $ServiceName = 'EoleCiTestService'
    $ss = Get-Service $ServiceName
    $ss
    & $nssm stop $ServiceName
    # sans confirmation
    & $nssm remove $ServiceName confirm
    
    $ServicePath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
    $ServiceArguments = '-ExecutionPolicy Bypass -NoProfile -File "C:\eole\EoleCiTestService.ps1"'
    
    "NSSM Install"
    & $nssm install $ServiceName $ServicePath $ServiceArguments
    & $nssm set $ServiceName AppDirectory c:\eole
    & $nssm set $serviceName AppNoConsole 1
    & $nssm set $ServiceName AppStdout "c:\eole\$ServiceName.log" 
    & $nssm set $ServiceName AppStdoutCreationDisposition 4
    & $nssm set $ServiceName AppStderr "c:\eole\$ServiceName.err" 
    & $nssm set $ServiceName AppStderrCreationDisposition 4
    & $nssm set $serviceName AppThrottle 1500
    & $nssm set $serviceName AppExit Default Restart
    & $nssm set $serviceName AppRestartDelay 2000
    & $nssm set $serviceName AppRotateFiles 1
    & $nssm set $serviceName AppRotateOnline 0
    & $nssm set $serviceName AppRotateSeconds 86400
    & $nssm set $serviceName AppRotateBytes 1048576    
    
    [int]$versionMajor = [environment]::OSVersion.version.Major
    $compte=".\pcadmin"
    $pwd="eole"
    if( $versionMajor -lt 10)
    { 
        if ( $versionBuild -gt 8000 )
        { 
            $compte=".\Administrateur"
            $pwd="Eole123456"
        }
    }
    & $nssm set $serviceName ObjectName "$compte" "$pwd"
    
    "NSSM status"
    # check the status... should be stopped
    & $nssm status $ServiceName
    
    "NSSM start"
    # start things up!
    & $nssm start $ServiceName
    
    "NSSM status"
    # verify it's running
    & $nssm status $ServiceName

    " Imp�ratif, sinon le service de contextulization ne serait pas lanc� (car il est System)."
    " Le d�marrage rapide cr�e un 'snapshot' du d�marrage syst�me... avant de d�marrer les services r�seaux et autres ..."
    & reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t reg_dword /d 0 /f
    & powercfg /H OFF

    Log "* doInstall fin"
}

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['out-file:width'] = 2000
Write-Host "[$((Get-Date).TimeofDay)] Starting $($myinvocation.mycommand)"
[string]$systemDrive = "$env:SystemDrive"
[string]$computerName = "$env:computername"
[string]$ConnectionString = "WinNT://$computerName"
[int]$versionMajor = [environment]::OSVersion.version.Major
[int]$versionBuild = [environment]::OSVersion.version.Build
[string]$VersionWindows = "?"
$global:vmPreviousIp=""
$computerInfo = Get-WmiObject Win32_ComputerSystem
        
if ( -not ( Test-Path c:\eole ) ) 
{
    mkdir c:\eole 
}
Set-Location c:\eole | Out-Null
if ( -not ( Test-Path c:\eole\download ) )
{
    mkdir c:\eole\download
}
if ( -not ( Test-Path c:\eole\logs ) )
{
    mkdir c:\eole\logs
}

if( $versionMajor -lt 6)
{ 
    Log "OS non support�"
    return
}

if( $versionMajor -lt 10)
{ 
    Write-Host "versionBuild=$versionBuild"
    if ( $versionBuild -gt 7601 )
    { 
        $VersionWindows = "2012"
    }
    else
    { 
        $VersionWindows = "7"
    }
}
else
{
    $VersionWindows = 10
    
    if( $versionBuild -eq 16299)
    { 
        $VersionWindows = "10.1709"
    }
    
    if( $versionBuild -eq 15063)
    { 
        $VersionWindows = "10.1703"
    }

    if( $versionBuild -eq 14393)
    { 
        $VersionWindows = "10.1607"
    }

    if( $versionBuild -eq 17134)
    { 
        $VersionWindows = "10.1803"
    }

    if( $versionBuild -ge 17758)
    { 
        # 17763
        $VersionWindows = "10.1809"
    }

    if( $versionBuild -ge 18362)
    { 
        $VersionWindows = "10.1903"
    }

    if( $versionBuild -ge 18363)
    { 
        $VersionWindows = "10.1909"
    }        

    if( $versionBuild -ge 19041)
    { 
        $VersionWindows = "10.2004"
    }

    if( $versionBuild -ge 19042)
    { 
        $VersionWindows = "10.20H2"
    }        
    
    if( $versionBuild -ge 19043)
    { 
        $VersionWindows = "10.21H1"
    }

    if( $versionBuild -ge 19044)
    { 
        $VersionWindows = "10.21H2"
    }

    if( $versionBuild -ge 19045)
    { 
        $VersionWindows = "10.22H2"
    }

    if( $versionBuild -ge 22000)
    { 
        $VersionWindows = "11"
    }
    
    if( $versionBuild -ge 22621)
    { 
        $VersionWindows = "11.22H2"
    }
}

$contextDrive = Get-WMIObject Win32_Volume | ? { $_.Label -eq "CONTEXT" }
if ( -not ( $contextDrive ) ) 
{
    Log "* pas de context ! stop"
    return
}

$contextLetter     = $contextDrive.Name
$contextScriptPath = $contextLetter + "context.sh"

if( -not ( Test-Path $contextScriptPath ) )
{
    Log "* pas de ''context.sh'', stop"
    return 
}

$context = @{}
switch -regex -file $contextScriptPath {
    "^([^=]+)='(.+?)'$" {
        $name, $value = $matches[1..2]
        $context[$name] = $value
    }
}
$vmId            = $context["VM_ID"]
if ( -not ( $vmId ) )
{
    log "* pas de ''VM_ID'', stop"
    return 
}
 
$vmOwner         = $context["VM_OWNER"]
if ( -not ( $vmOwner ) )
{
    log "* pas de ''VM_OWNER'', stop"
    return 
}

$vmMachine         = $context["VM_MACHINE"]
if ( -not ( $vmMachine ) )
{
    log "* pas de ''VM_MACHINE'', continue (cas Daily, Vm, Fi)"
}

$vmName         = $context["VM_NAME"]
if ( -not ( $vmName ) )
{
    log "* pas de ''VM_NAME'', continue (cas Daily, Vm, Fi)"
}

$hostname = $context["SET_HOSTNAME"]
if ( ! $hostname) 
{
    $hostname = "PC-" + $vmId 
    log "* hostname = $hostname"
}

[string]$vmConfiguration = $context["VM_CONFIGURATION"]

if ( $debug )
{
    Log "* command=$command"
    Log "* systemDrive=$systemDrive"
    Log "* computerName = $computerName"
    Log "* ConnectionString= $ConnectionString"
    log "* versionMajor= $versionMajor"
    log "* versionBuild= $versionBuild"
    switch -regex -file $contextScriptPath {
    "^([^=]+)='(.+?)'$" {
        	$name, $value = $matches[1..2]
    	    if ( $name -eq "JNLPMAC" )
	        {
        	    Log "* $name=**********************************************"
    	    }
	        else
	        {
            	Log "* $name=$value"
            }
        }
    }
    log "* VersionWindows= $VersionWindows"
}

$ipEoleCiTest         = $context["VM_IP_EOLECITEST"]
if ( -not ( $ipEoleCiTest ) )
{
    $ipEoleCiTest = "192.168.0.253"
}

if ($command -eq "doContext" )
{
    Log "* chargement de EoleCiTestsCommon.ps1 doContext"
    doContext
    exit 0
}

if ($command -eq "doService" )
{
    Log "* chargement de EoleCiTestsCommon.ps1 doService"
    doService
    exit 0
}

if ($command -eq "doInstall" )
{
    Log "* chargement de EoleCiTestsCommon.ps1 doInstall"
    doInstall
    exit 0
}

#if ($command -eq "?" )
#{
#    Log "* chargement de EoleCiTestsCommon.ps1 doService pour debug !"
#    doService
#    exit 0
#}
