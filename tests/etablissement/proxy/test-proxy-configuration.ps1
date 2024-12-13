<# 
Qu'est-ce que WPAD et comment ça marche ?
=========================================

Des techniques de dépannage WPAD complètes sont disponibles sur : http://technet.microsoft.com/en-us/library/cc302643.aspx

Si vous utilisez Microsoft Server 2008 ou une version plus récente, WPAD est automatiquement sur la liste de blocage DNS.
Pour supprimer WPAD de la liste de blocage DNS, consultez : https://technet.microsoft.com/en-gb/library/cc995158.aspx

Remarques et techniques supplémentaires pouvant aider à résoudre davantage les problèmes liés à WPAD :
======================================================================================================

1°) Testez si un client passe par le proxy en vous connectant à http://www.whatismyproxy.com/ à partir d'une machine cliente

2°) Lors de la configuration des paramètres de proxy, il existe une option pour utiliser "Détecter automatiquement les paramètres" ou 
"Utiliser un serveur proxy pour votre réseau local" - IP et port. 

Si ce dernier paramètre est utilisé et que l'ordinateur est un ordinateur portable qui va à la maison avec l'utilisateur,
l'utilisateur aura des problèmes pour accéder à Internet (car l'ordinateur enverra le trafic http à l'adresse IP et au port spécifiés).
Dans ces cas, il est préférable d'utiliser "Détecter automatiquement les paramètres" qui devrait découvrir le serveur proxy 
lorsqu'il est sur le réseau local, et lorsqu'il se trouve sur un autre réseau, il ne détectera pas le serveur proxy, 
ce qui entraînera l'utilisation de la passerelle par défaut

Remarque : N'utilisez PAS À LA FOIS Détecter automatiquement ET "Utiliser un serveur proxy pour ce réseau local" - 
Le navigateur essaiera d'abord WPAD et en cas d'échec, il utilisera le paramètre "Utiliser un serveur proxy" et 
ne pourra pas accéder au Internet lorsqu'un utilisateur est en dehors du réseau local

3°) Lorsqu'un navigateur Web a son paramètre de proxy défini sur "Détecter automatiquement les paramètres", 
le protocole WPAD est utilisé pour trouver un serveur Web qui servira un script de configuration appelé wpad.dat

4°) Chaque navigateur Web peut faire cela différemment. Tous les navigateurs Web essaient de se connecter à http://wpad/wpad.dat

Remarque : Pour se connecter à http://wpad/wpad.dat, la machine doit d'abord trouver un hôte sur le réseau appelé « WPAD » et résoudre son adresse IP. Une fois qu'il trouve l'adresse IP de l'hôte nommé "WPAD", il utilise http pour demander le document appelé wpad.dat

5°) La difficulté survient lorsque vous essayez de trouver un hôte appelé WPAD. Internet Explorer utilisera l'ordre suivant pour déterminer l'hôte :
        Requête DHCP (Option DHCP 252)
        Requête DNS
        NetBIOS

6°) Le serveur Webmonitor annonce qu'il est l'hôte WPAD utilisant NetBIOS. Cependant, de nombreuses organisations bloquent 
les diffusions NetBIOS sur les routeurs, donc si la machine cliente se trouve de l'autre côté de l'un de ces routeurs, 
elle peut ne pas être en mesure de résoudre l'hôte (à moins qu'elle ne puisse utiliser les autres options)

* De nombreux navigateurs (tels que Firefox) ne prennent en charge que NetBIOS et DNS. Cependant, tous les navigateurs prennent 
en charge le DNS, il est donc préférable d'ajouter un enregistrement d'alias DNS.

7°) Pour dépanner la capacité d'une machine cliente (dans un sous-réseau de votre réseau) à résoudre le script WPAD, procédez comme suit :
7.1 : Ouvrez le navigateur IE (décochez tous les paramètres de proxy afin que le navigateur ne cache pas le script)
7.2 : Testez pour voir si Webmonitor sert le script wpad.dat en tapant dans le navigateur : http://Webmon_IP_Address/wpad.dat 
      (Remarque : remplacez WebMon_IP_Address par l'adresse IP réelle du serveur WebMonitor)
      
7.2.1 : Si l'étape 7.2 ci-dessus réussit, testez pour voir si le navigateur peut trouver le serveur WPAD en tapant dans le navigateur : http://wpad/wpad.dat
    - Si cela réussit, WPAD fonctionnera pour l'ordinateur sur lequel se trouve ce navigateur. Alternativement, à partir de la ligne de commande, vous pouvez utiliser la commande "ping WPAD" pour voir si elle résout l'adresse IP
    - Si http://wpad/wpad.dat ne renvoie pas de script, vous savez que la machine cliente ne peut pas résoudre l'IP de l'hôte WPAD

7.2.2 : Tapez dans le navigateur : http://<WebmonHostName>/wpad.dat pour vous assurer que DNS peut résoudre le serveur WebMonitor 
(Remarque : remplacez WebMonHostName par le nom du serveur WebMonitor).

* Si http://<WebmonHostName>/wpad.dat fonctionne, mais que http://wpad/wpad.dat ne fonctionne toujours pas, le client ne peut pas résoudre l'adresse IP du nom d'hôte WPAD. 
Dans ce cas il y a 3 options :

a) Ajoutez des enregistrements DNS pour le serveur WPAD. Il s'agira d'un enregistrement A pour le serveur GFI WebMonitor et d'un enregistrement d'alias (CNAME) pour WPAD. 
Voici comment procéder : http://technet.microsoft.com/en-us/library/cc995062.aspx
Remarque : Cette option est préférable car certains navigateurs (Firefox) ne supportent pas la résolution par DHCP

b) Ajouter une option DHCP 252 : http://technet.microsoft.com/en-us/library/cc940962(WS.10).aspx

c) Si tout le reste échoue, vous pouvez ajouter une entrée dans le fichier Windows\System32\Drivers\Etc\hosts

Remarque : Si http://Webmon_IP_Address/wpad.dat est résolu à partir de la machine cliente, une autre option consiste à définir les paramètres de proxy 
du navigateur pour cette machine sur "Utiliser le script de configuration automatique" avec l'adresse : http://Webmon_IP_Address/wpad.dat
(Remarque : remplacez WebMon_IP_Address par l'adresse IP réelle du serveur WebMonitor) au lieu d'utiliser "Détecter automatiquement les paramètres"

Remarques:

* WebMonitor utilise le port 80 pour servir le script wpad.dat au navigateur. De plus, si IIS est en cours d'exécution et utilise le port 80 
pour les sites Web par défaut (ou autres), WebMonitor ne pourra pas utiliser le port. Désactivez IIS ou modifiez les ports utilisés pour le(s) site(s) Web

* WebMonitor prend le script (situé dans le répertoire d'installation de WebMonitor, fichier Proxypac.pac) et le sert comme wpad.dat

* Le port utilisé par Webmonitor pour publier WPAD ne peut pas être modifié

* Si le pare-feu Windows est activé, ajoutez une exception pour le port 80 (en plus, ajoutez 8080 comme exception de pare-feu,
  puisque 8080 est le port proxy par défaut pour GFI WebMonitor)

Notes complémentaires:

* Comment empêcher les sites Web de passer par le proxy WebMonitor ? http://kb.gfi.com/articles/SkyNet_Article/KBID003673

* Internet Explorer met en cache le proxy dans son cache de résultat de proxy automatique. 
  Cela peut causer des problèmes (en particulier avec des scripts WPAD complexes) et est bien couvert dans l'article suivant : https://jdebp.eu/FGA/web-browser-auto-proxy-configuration.html
  
* Internet Explorer ne parvient pas à récupérer une nouvelle configuration wpad.dat : http://kb.gfi.com/articles/SkyNet_Article/Internet-Explorer-is-unable-to-retrieve-a-new-wpad-dat-configuration

* La désactivation de la mise en cache automatique des résultats du proxy à des fins de test OU de manière permanente est traitée dans l'article Microsoft : http://support.microsoft.com/kb/271361 

#> 


function Get-InternetProxy
 { 
    <# 
            .SYNOPSIS 
                Determine the internet proxy address
            .DESCRIPTION
                This function allows you to determine the the internet proxy address used by your computer
            .EXAMPLE 
                Get-InternetProxy
            .Notes 
                Author : Antoine DELRUE 
                WebSite: http://obilan.be 
    #> 

    $proxies = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings').proxyServer

    if ($proxies)
    {
        if ($proxies -ilike "*=*")
        {
            $proxies -replace "=","://" -split(';') | Select-Object -First 1
        }

        else
        {
            "http://" + $proxies
        }
    }    
}

Function Get-UserInternetSettings {
<#
 .SYNOPSIS
    function used to get :
    - all information regarding your basic internet settings used by Internet Explorer/Edge or third party browser like Goole Chrome/Chromium
    - wpad settings
 
    .DESCRIPTION
    function used to get :
    - all information regarding your basic internet settings used by Internet Explorer/Edge or third party browser like Goole Chrome/Chromium
    - wpad settings
      
 .OUTPUTS
        TypeName : System.Management.Automation.PSCustomObject
 
        Name MemberType Definition
        ---- ---------- ----------
        Equals Method bool Equals(System.Object obj)
        GetHashCode Method int GetHashCode()
        GetType Method type GetType()
        ToString Method string ToString()
        Force Disable WPAD NoteProperty bool Force Disable WPAD=False
        User Proxy NoteProperty bool User Proxy=False
        User Proxy Autoconfig URL NoteProperty object User Proxy Autoconfig URL=null
        User Proxy HTTP1.1 NoteProperty bool User Proxy HTTP1.1=False
        User Proxy Migrate NoteProperty bool User Proxy Migrate=True
        User Proxy server NoteProperty string User Proxy server=proxy.xx.yyyyyyyyyyyyyyy.io:8080
        User Proxy WPAD NoteProperty bool User Proxy WPAD=False
        WPAD Service Status NoteProperty ServiceControllerStatus WPAD Service Status=Running
 
    .EXAMPLE
    Get all information regarding your basic internet settings
    C:\PS> Get-UserInternetSettings
#>
    [CmdletBinding()]            
    Param()  
    $Results=[PSCustomObject]@{}
    try {
        $InternetSettings = Get-Item "hkcu:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    } catch {
        $InternetSettings = $null
    } finally {
        if ($InternetSettings) 
        {
            try {
                [bool]$booltmp = $InternetSettings.GetValue("ProxyEnable")
                $Results | add-member -MemberType NoteProperty -Name "User Proxy" -Value $booltmp
            } catch {
                $Results | add-member -MemberType NoteProperty -Name "User Proxy" -Value $false
            } 
            try {
                [bool]$booltmp2 = $InternetSettings.GetValue("ProxyHTTP1.1")
                $Results | add-member -MemberType NoteProperty -Name "User Proxy HTTP1.1" -Value $booltmp2
            } catch {
                $Results | add-member -MemberType NoteProperty -Name "User Proxy HTTP1.1" -Value $false
            } 
            $Results | add-member -MemberType NoteProperty -Name "User Proxy server" -Value $InternetSettings.GetValue("ProxyServer")
            $Results | add-member -MemberType NoteProperty -Name "User Proxy Autoconfig URL" -Value $InternetSettings.GetValue("AutoConfigURL")
            try {
                [bool]$booltmp3 = $InternetSettings.GetValue("AutoDetect")
                $Results | add-member -MemberType NoteProperty -Name "User Proxy WPAD" -Value $booltmp3
            } catch {
                $Results | add-member -MemberType NoteProperty -Name "User Proxy WPAD" -Value $false
            }
            try {
                [bool]$booltmp4 = $InternetSettings.GetValue("MigrateProxy")
                $Results | add-member -MemberType NoteProperty -Name "User Proxy Migrate" -Value $booltmp4
            } catch {
                $Results | add-member -MemberType NoteProperty -Name "User Proxy Migrate" -Value $false
            }
        }
    }
    try {
       $WPADSettings = Get-Item "hkcu:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\WPAD"
       $WpadOverride = $WPADSettings.GetValue("WpadOverride")
       $Results | add-member -MemberType NoteProperty -Name "Force Disable WPAD" -Value $WpadOverride
    } catch {
       $Results | add-member -MemberType NoteProperty -Name "Force Disable WPAD" -Value $false
    }
    try {
       $WPADServiceStatus = (Get-Service WinHttpAutoProxySvc).status
       $Results | add-member -MemberType NoteProperty -Name "WPAD Service Status" -Value $WPADServiceStatus
    } catch {
       $Results | add-member -MemberType NoteProperty -Name "WPAD Service Status" -Value "N/A"
    } 
    return $results
}

Function Get-WinHttpProxy {
<#
 .SYNOPSIS
    function used to retrieve proxy set for local machine web layer aka winhttp
 
    .DESCRIPTION
    retrieve proxy set for local machine web layer aka winhttp
      
 .OUTPUTS
        TypeName : System.Management.Automation.PSCustomObject
 
        Name MemberType Definition
        ---- ---------- ----------
        Equals Method bool Equals(System.Object obj)
        GetHashCode Method int GetHashCode()
        GetType Method type GetType()
        ToString Method string ToString()
        Winhttp proxy NoteProperty string Winhttp proxy=Direct Access
        Winhttp proxy bypass list NoteProperty string Winhttp proxy bypass list=(none)
        
    .EXAMPLE
    Get all information about winhttp proxy
    C:\PS> Get-WinHttpProxy
#>              
    [CmdletBinding()]            
    Param()                       
       try {
           $Conprx = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" -Name WinHttpSettings).WinHttpSettings
       } catch {
            $Conprx = $null
       } finally {
            if ($Conprx) 
            {
                $proxylength = $Conprx[12]            
                if ($proxylength -gt 0) {            
                    $proxy = -join ($Conprx[(12+3+1)..(12+3+1+$proxylength-1)] | ForEach-Object {([char]$_)})            
                    $bypasslength = $Conprx[(12+3+1+$proxylength)]            
                    if ($bypasslength -gt 0) {            
                        $bypasslist = -join ($Conprx[(12+3+1+$proxylength+3+1)..(12+3+1+$proxylength+3+1+$bypasslength)] | ForEach-Object {([char]$_)})            
                    } else {            
                        $bypasslist = '(none)'            
                    }            
                    $result = [PSCustomObject]@{
                        "Winhttp proxy" = $proxy
                        "Winhttp proxy bypass list" = $bypasslist
                    }                 
                } else {                                
                    $result = [PSCustomObject]@{
                        "Winhttp proxy" = "Direct Access"
                        "Winhttp proxy bypass list" = "(none)"
                    } 
                }
            } else {
                $result = [PSCustomObject]@{
                    "Winhttp proxy" = "error - not able to read registry entry"
                    "Winhttp proxy bypass list" = "error - not able to read registry entry"
                } 
            }
       }
       return $result                  
}

Function Get-UserconnectionProxy {
<#
 .SYNOPSIS
    function used to retrieve proxy information for all network connection used by the current user context
 
    .DESCRIPTION
    retrieve proxy information for all network connection used by the current user context
      
 .OUTPUTS
        TypeName : System.Management.Automation.PSCustomObject
 
        Name MemberType Definition
        ---- ---------- ----------
        Equals Method bool Equals(System.Object obj)
        GetHashCode Method int GetHashCode()
        GetType Method type GetType()
        ToString Method string ToString()
        User proxy NoteProperty string User proxy=proxy.cc.dddddd.io:8080
        User proxy bypass list NoteProperty string User proxy bypass list=test;<local>)
        User proxy connection name NoteProperty string User proxy connection name=SavedLegacySettings
        User proxy PAC NoteProperty string User proxy PAC=http://xxxxxx.yy.zzzz.io:8080/
 
    .EXAMPLE
    Get all information about user connections
    C:\PS> Get-UserconnectionProxy
#>  
    [CmdletBinding()]            
    Param()                       
    try {
        $Conprx = Get-Item "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections"
    } catch {
        $Conprx = $null
    } finally {
        $results = @()
        if ($Conprx) {
                $ConRegValues = $Conprx.GetValueNames()
            foreach ($value in $ConRegValues) {
                $result = [PSCustomObject]@{
                    "User proxy connection name" = $value
                }
                $tmpvalue = $Conprx.GetValue($value)
                $pacentr = $null
                for($i=0;$i -le $tmpvalue.length;$i++){
                    if (($tmpvalue[$i] -eq 36) -or ($tmpvalue[$i] -eq 41)) {
                        $pacentr = $i
                        break
                    }
                }
                if ($pacentr) {        
                    $proxypac = -join ($tmpvalue[($pacentr+3+1)..($pacentr+3+1+$tmpvalue.length-1)] | ForEach-Object {([char]$_)})
                    $Result | add-member -MemberType NoteProperty -Name "User proxy PAC" -Value $proxypac                  
                } else {
                    $Result | add-member -MemberType NoteProperty -Name "User proxy PAC" -Value "none" 
                }
                $proxylength = $tmpvalue[12]            
                if ($proxylength -gt 0) {            
                    $proxy = -join ($tmpvalue[(12+3+1)..(12+3+1+$proxylength-1)] | ForEach-Object {([char]$_)})            
                    $bypasslength = $tmpvalue[(12+3+1+$proxylength)]            
                    if ($bypasslength -gt 0) {            
                        $bypasslist = -join ($tmpvalue[(12+3+1+$proxylength+3+1)..(12+3+1+$proxylength+3+1+$bypasslength)] | ForEach-Object {([char]$_)})            
                    } else {            
                        $bypasslist = '(none)'            
                    }            
                    $Result | add-member -MemberType NoteProperty -Name "User proxy" -Value $proxy
                    $Result | add-member -MemberType NoteProperty -Name "User proxy bypass list" -value $bypasslist                 
                } else {            
                    $Result | add-member -MemberType NoteProperty -Name "User proxy" -value "Direct Access"
                    $Result | add-member -MemberType NoteProperty -Name "User proxy bypass list" -value "(none)"      
                }
                $results += $result
            }
        } else {
            $result = [PSCustomObject]@{
                "User connection proxy" = "error - not able to read registry entry"
            }
            $results += $result
        }
    }
    return $results
}

$vmConfiguration = $args[0]
$vmVersionMajeurCible = $args[1]
. c:\eole\EoleCiFunctions.ps1
initializeContextDomain $vmConfiguration $vmVersionMajeurCible
Set-Proxy $proxyHost $proxyPort

$cdu=255
try 
{
    displayContext

    Set-ExecutionPolicy Bypass -Scope Process -Force
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
    #[Console]::OutputEncoding = [Text.UTF8Encoding]::ASCII
    
    if ($PSVersionTable.PSVersion.Major -le 4)
    {
        Write-Host "test-proxy-configuration: You must use PowerShell 4.0 or above."
        exit -1
    }
    Write-Host  "test-proxy-configuration: " $PSVersionTable.PSVersion

    Set-Location $env:TEMP
    $ProgressPreference = 'SilentlyContinue'
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

    Write-Host "--------------------------------------------------------------"
    Write-Host  "test-proxy-configuration: GetDefaultProxy"
    [System.Net.WebProxy]::GetDefaultProxy() 
    
    Write-Host "--------------------------------------------------------------"
    Write-Host  "test-proxy-configuration: registry 'Internet Settings'"
    Get-ItemProperty 'Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings' | Select-Object *Proxy*
    
    Write-Host "--------------------------------------------------------------"
    Write-Host  "test-proxy-configuration: Get-WinHttpProxy"
    Get-WinHttpProxy
    
    Write-Host "--------------------------------------------------------------"
    Write-Host  "test-proxy-configuration: Get-UserconnectionProxy"
    Get-UserconnectionProxy

    Write-Host "--------------------------------------------------------------"
    Write-Host  "test-proxy-configuration: Get-UserInternetSettings"
    Get-UserInternetSettings

    Write-Host "--------------------------------------------------------------"
    Write-Host  "test-proxy-configuration: Get-InternetProxy"
    Get-InternetProxy
    
    Write-Host "#############################################################"
    Write-Host "#############################################################"
    Write-Host "#############################################################"
    
    Write-Host "test-proxy-configuration: Test-Connection 192.168.0.1"
    Test-Connection 192.168.0.1  -ErrorAction SilentlyContinue | Format-Table -Property PSComputerName,ResponseTime,ReplyInconsistency,ResolveAddressNames
    
    Write-Host "test-proxy-configuration: Test-Connection $adRealm"
    Test-Connection "$adRealm" -ErrorAction SilentlyContinue | Format-Table -Property PSComputerName,ResponseTime,ReplyInconsistency,ResolveAddressNames
    
    Write-Host "test-proxy-configuration: Test-Connection wpad"
    Test-Connection wpad -ErrorAction SilentlyContinue | Format-Table -Property PSComputerName,ResponseTime,ReplyInconsistency,ResolveAddressNames

    if( $versionMajor -lt 10)
    {
        Write-Host "test-proxy-configuration: pas de Resolve-DnsName sur win7/2012"
    }
    else
    {
        Write-Host "test-connectivite: Resolve-DnsName $adRealm"
        Resolve-DnsName "$adRealm" -ErrorAction SilentlyContinue

        Write-Host "test-connectivite: Resolve-DnsName wpad.$adRealm"
        Resolve-DnsName "wpad.$adRealm" -ErrorAction SilentlyContinue

    }
    
    Write-Host "--------------------------------------------------------------"
    Write-Host  "test-proxy-configuration: http://wpad/wpad.dat"
    $fichierTemp="$env:TEMP\wpad.dat"
    $cdu = doDownload http://wpad/wpad.dat $fichierTemp
    $cdu
    if ( $cdu -eq "0" )
    { 
        Write-Host "ok"
        Get-Content $fichierTemp
    }
    else
    {
        Write-Host "nok"
    }
    
    Write-Host "--------------------------------------------------------------"
    Write-Host "test-proxy-configuration: wpad realm http://wpad.$adRealm/wpad.dat"
    $cdu = doDownload http://wpad.$adRealm/wpad.dat $fichierTemp
    $cdu  
    if ( $cdu -eq "0" )
    { 
        Write-Host "ok"
        Get-Content $fichierTemp
    }
    else
    {
        Write-Host "nok"
    }

    Write-Host "--------------------------------------------------------------"
    $cdu=255
    if ( $vmMachine -eq "etb1.pceleve" )
    {
        $urlWpad="http://wpad.etb1.lan/wpad.dat"
    }
    if ( $vmMachine -eq "etb3.pceleve" )
    {
        $urlWpad="http://wpad.etb3.lan/wpad.dat"
    }
    if ( $urlWpad )
    {
        Write-Host  "test-proxy-configuration: wpad Etablissement : $urlWpad"
        $cdu = doDownload $urlWpad $fichierTemp
        $cdu
        if ( $cdu -eq "0" )
        { 
            Write-Host "ok"
            Get-Content $fichierTemp
        }
        else
        {
            Write-Host "nok"
        }
    }
    
    
    Write-Host  "test-proxy-configuration: http://www.whatismyproxy.com/"
    $cdu = doDownload http://www.whatismyproxy.com/ $fichierTemp
    $cdu
    if ( $cdu -eq "0" )
    { 
        Write-Host "ok"
        Get-Content $fichierTemp
    }
    else
    {
        Write-Host "nok"
    }
    "0"
}
catch
{
    <#
        You can have multiple catch blocks (for different exceptions), or one single catch.
        The last error record is available inside the catch block under the $_ variable.
        Code inside this block is used for error handling. Examples include logging an error,
        sending an email, writing to the event log, performing a recovery action, etc.
        In this example I'm just printing the exception type and message to the screen.
    #>
    $Error | Out-Host
    write-host "test: Caught an exception:" -ForegroundColor Red
    write-host "test: Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
    write-host "test: Exception Message: $($_.Exception.Message)" -ForegroundColor Red
    "1"
}
