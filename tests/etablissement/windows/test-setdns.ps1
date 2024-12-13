$vmConfiguration = $args[0]
$vmVersionMajeurCible = $args[1]
. z:\scripts\windows\EoleCiFunctions.ps1
initializeContextDomain $vmConfiguration $vmVersionMajeurCible

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


function doSetDnsDomain( $nic, $dnsServersString, $realm, $dynamicDNSRegistration )
{
    if ( ! $nic )
    {
        return 
    }
    Write-Host "-------------------------------"
    Write-Host "Configuring Network Settings: " + $nic.Description.ToString()
    
    $ip = $nic.IPAddress
    
    $dnsServers = $dnsServersString -split " "
    $dnsServerSearchOrder = $nic.DNSServerSearchOrder
    if ( "$dnsServerSearchOrder" -ne "$dnsServersString" )
    {
        Write-Output "* Set dns to '${dnsServers}' " 
        $ret = $nic.SetDNSServerSearchOrder($dnsServers)
        checkReturnValue $ret 
    }
    else
    {
        Write-Output "- Dns est déjà '$dnsServerSearchOrder'"
    }

    # Set Primary DNS Domain
    $dnsDomain = $nic.DNSDomain
    if ( $dnsDomain -ne $realm )
    {
        Write-Output "- Set Primary DNS Domain to '$realm'"
        $ret = $nic.SetDNSDomain($realm)
        checkReturnValue $ret 
    }
    else
    {
        Write-Output "- Primary DNS Domain est déjà '$dnsDomain'"
    }

    # Set Dynamic DNS Registration
    Write-Host "- Set Dynamic DNS Registration"
    $domainDNSRegistrationEnabled = $nic.DomainDNSRegistrationEnabled
    Write-Output "- Dynamic DNS Registration est Domain='$domainDNSRegistrationEnabled' et Full='$fullDNSRegistrationEnabled'"
    if ($domainDNSRegistrationEnabled -eq $domainDNSRegistrationEnabled )
    {
        Write-Host "  SetDynamicDNSRegistration ok  $domainDNSRegistrationEnabled"
    }
    else
    {
        Write-Host "  SetDynamicDNSRegistration a changer en $domainDNSRegistrationEnabled"
        $ret = $nic.SetDynamicDNSRegistration($domainDNSRegistrationEnabled)
    }
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
    
    $dnsDomainSuffixSearchOrder = $nic.DNSDomainSuffixSearchOrder
    if ( $dnsDomainSuffixSearchOrder -ne $realm )
    {
        # Set DNS Suffix Search Order
        Write-Output "- Set DNS Suffix Search Order to '$realm' "
        $ret = ([WMIClass]"Win32_NetworkAdapterConfiguration").SetDNSSuffixSearchOrder(($realm))
        checkReturnValue $ret 
    }
    else
    {
        Write-Output "- DNS Suffix Search Order est déjà '$dnsDomainSuffixSearchOrder'"
    }
}


try 
{
    Write-Output "* utilise dns=$adDNSServers, domain=$adRealm"
    $dnsServers = $adDNSServers -split " "
    if ( $adDNSServers -eq "" )
    {
        Write-Output "* pas de modification !"
    }
    else
    {
        if( $versionWindows -ne "7" )
        {
            Write-Host "* Disable ipV6 ! -------------------"
            Get-NetAdapter | foreach { Disable-NetAdapterBinding -InterfaceAlias $_.Name -ComponentID ms_tcpip6 }
            Get-NetAdapter | foreach { Get-NetAdapterBinding -InterfaceAlias $_.Name -ComponentID ms_tcpip6 }
            Write-Host "* Disable ipV6 --------------------- "
        }

        $adapters = Get-WMIObject Win32_NetworkAdapterConfiguration | where {$_.IPEnabled -eq "TRUE" }
        $adapters | ForEach-Object {
            $nic = $_ 
            $nic | Write-Output
#            $ret = $nic.ReleaseDHCPLease()
#            If ($ret.ReturnValue) 
#            {
#                log ("  ... Failed: " + $ret.ReturnValue.ToString())
#            }
#            Else 
#            {
#                log "  ... Success"
#            }
            
            doSetDnsDomain $nic $adDNSServers $adRealm $true
        }
        
        Write-Host "******************************************************"
        Write-Host "* si j'ai modifié les paramétres DNS --> flushdns "
        Write-Host "* - ipconfig /flushdns"
        CMD.EXE /C "ipconfig /flushdns"
        Write-Host "* - ipconfig /registerdns"
        CMD.EXE /C "ipconfig /registerdns"
        
        Write-Host "******************************************************"
        For ($i=0; $i -le 10; $i++) 
        {
            Sleep 10
            if ( Test-Connection salt -Count 1 )
            {
                Write-Host "* Test Connection 'salt' OK"
                break
            }
            else
            {
                Write-Host "* Test Connection 'salt' NOK"
            }
        }
    }
}
catch
{
    $_ | Write-Output 
}
finally
{
    Set-PSDebug -Trace 0
}
