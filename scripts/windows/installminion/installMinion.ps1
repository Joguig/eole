param(
    [switch]$debug=$false
)

function log($t)
{
    Write-Host "installMinion: $t"
}

function logDebug($t)
{
    if ( $debug )
    {
       log "DEBUG: $t"
    }
}

# tips: https://stackoverflow.com/questions/35260354/powershell-wget-protocol-violation
function Set-UseUnsafeHeaderParsing
{
    param(
        [Parameter(Mandatory,ParameterSetName='Enable')]
        [switch]$Enable,

        [Parameter(Mandatory,ParameterSetName='Disable')]
        [switch]$Disable
    )

    $ShouldEnable = $PSCmdlet.ParameterSetName -eq 'Enable'

    $netAssembly = [Reflection.Assembly]::GetAssembly([System.Net.Configuration.SettingsSection])

    if($netAssembly)
    {
        $bindingFlags = [Reflection.BindingFlags] 'Static,GetProperty,NonPublic'
        $settingsType = $netAssembly.GetType('System.Net.Configuration.SettingsSectionInternal')

        $instance = $settingsType.InvokeMember('Section', $bindingFlags, $null, $null, @())

        if($instance)
        {
            $bindingFlags = 'NonPublic','Instance'
            $useUnsafeHeaderParsingField = $settingsType.GetField('useUnsafeHeaderParsing', $bindingFlags)

            if($useUnsafeHeaderParsingField)
            {
              $useUnsafeHeaderParsingField.SetValue($instance, $ShouldEnable)
            }
        }
    }
}

function doDownload( $url1, $file1)
{
    [string]$url = $url1.ToString()
    [string]$file = $file1.ToString()
    if( Test-Path $file )
    {
        Remove-Item -Path $file
    }

    try
    {
        $global:ProgressPreference = 'SilentlyContinue'
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
        $wc = New-Object Net.WebClient
        $wc.UseDefaultCredentials = $true
        $wc.Proxy = $null
        #$wc.Proxy.Credentials = $wc.Credentials
        $wc.Encoding = [System.Text.Encoding]::UTF8
        $wc.CachePolicy = New-Object Net.Cache.HttpRequestCachePolicy([System.Net.Cache.HttpRequestCacheLevel]::NoCacheNoStore)

        log "Download WebClient $url"
        $wc.DownloadFile($url, $file)
    }
    catch
    {
        $_ | Out-Host # Output the thread pipeline error
        $StatusCode = $_.Exception.Response.StatusCode.value__
        log "StatusCode = $StatusCode"
        log "ERROR: download WebClient '$url'. Stop!"
    }
    
    if( !(Test-Path $file ))
    { 
        # Win 7, 8, 2012 ... <= Win 10 !
        try
        {
            # avec DisableKeepAlive ! 
            log "Invoke-WebRequest $url"
            $r = Invoke-WebRequest -Uri $url -OutFile $file -Method Get -DisableKeepAlive -UseDefaultCredentials -useBasicParsing
            $StatusCode = $Response.StatusCode
            log "StatusCode = $StatusCode"
        }
        catch
        {
            $_ | Out-Host # Output the thread pipeline error
            $StatusCode = $_.Exception.Response.StatusCode.value__
            log "StatusCode = $StatusCode"
            log "ERROR: download Invoke-WebRequest '$url'. Stop!"
        }
    }
    
    if( !(Test-Path $file ))
    { 
        log "ERROR: download '$url'. Stop!"
        return 1 
    }
    else
    { 
        log "'$file1' downloaded"
        return 0
    }
}

function doInstallMinion()
{
    Set-ExecutionPolicy Bypass -Scope Process -Force
    
    #############################################################################
    # Phase 1 : check environement
    #############################################################################
    $major = $PSVersionTable.PSVersion.Major
    log "ps version : $Major"
    if ($Major -le 4)
    {
        log "You must use PowerShell 4.0 or above."
        return -1
    }

    $build = $PSVersionTable.PSVersion.Build
    log "OS Build : $build"
    log "Attention: Install Minion 2024-11-29"
    
    $release = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Release
    log ".NetFramework release = $release"
    $NetFramework  = "$(
      switch ($release) {
        ({ $_ -ge 533320 }) { '4.8.1'; break }
        ({ $_ -ge 528040 }) { '4.8'; break }
        ({ $_ -ge 461808 }) { '4.7.2'; break }
        ({ $_ -ge 461308 }) { '4.7.1'; break }
        ({ $_ -ge 460798 }) { '4.7'; break }
        ({ $_ -ge 394802 }) { '4.6.2'; break }
        ({ $_ -ge 394254 }) { '4.6.1'; break }
        ({ $_ -ge 393295 }) { '4.6'; break }
        ({ $_ -ge 379893 }) { '4.5.2'; break }
        ({ $_ -ge 378675 }) { '4.5.1'; break }
        ({ $_ -ge 378389 }) { '4.5'; break }
        default { '4.5+ not installed.' }
    }
    )"
    
    log "NetFramework = $NetFramework"
    
    Set-Location $env:TEMP
    
    #############################################################################
    # Phase 1b : check os 
    #############################################################################
    # 1 you are on a workstation OS.
    # 2 you're on a domain controller.
    # 3 you're on a server that is not a domain controller.
    log "Check is os type ?"    
    $osInfo = Get-WmiObject -Class Win32_OperatingSystem
    $productType = $osInfo.ProductType
    log "ProductType = $productType"
    if ( $productType -ne 1 )
    {
        log "La machine n'est pas une station de travail, je l'ignore. exit=0"
        return 0
    } 
    
    #############################################################################
    # Phase 1c : check elevated
    #############################################################################
    log "check is elevated session ?"    
    $isAdmin=([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ( -Not( $isAdmin ) )
    {
        log "Vous n'êtes pas 'Administrateur' ou dans une session 'Elevated', exit=-2"
        return -2
    }
    else
    {
        log "Vous êtes dans une session 'Elevated', Ok"
    }
    
    #############################################################################
    # Phase 2 : check Slat dns
    #############################################################################
    log "check 'salt' dns resolution ?"    
    $i=1
    $testConnection = Test-Connection -ComputerName salt -Count 1 -ErrorAction SilentlyContinue
    while( $i -le 3 -and -Not( $testConnection ))
    {
        $i++
        log "La résolution du nom 'salt' n'est pas fonctionnelle, (essai = $i)"
        Start-Sleep -s 2
        $testConnection = Test-Connection -ComputerName salt -Count 1 -ErrorAction SilentlyContinue
    }
    if ( $testConnection )
    {
        log "La résolution du nom 'salt' est fonctionnelle, Ok"
    }
    else
    {
        log "La résolution du nom 'salt' n'est pas fonctionnelle. Configurer l'enregistrement DNS sur le serveur DNS. exit=-3"
        return -3
    }

    $ip = $testConnection.IPV4Address
    $ipSaltMaster = $ip.IPAddressToString
    if( -Not ($ipSaltMaster) )
    {
        log "L'adresse ip du nom 'salt' n'est pas correcte. exit=-3"
        return -3
    }
    else
    {
        log "ipSaltMaster = $ipSaltMaster"
    }

    #############################################################################
    # Préparation Invoke hhtprequest pour avoir un debug
    #############################################################################
    Set-UseUnsafeHeaderParsing -Enable
    
    #############################################################################
    # Phase 3 : téléchargement de 'installMinion.conf' depuis le scribe
    #############################################################################
    log "---"
    $saltMinionConfFile="$env:TEMP\installMinion.conf"
    $saltMinionConfUrl="http://$ipSaltMaster/joineole/installMinion.conf"
    $cdu = doDownload -url1 $saltMinionConfUrl -file1 $saltMinionConfFile
    if( $cdu -eq 1)
    {
        return -4
    }
    
    # protection si le firewall/filtrage renvoi autre chose ...
    $content = Get-Content $saltMinionConfFile -Raw
    $idx = $content.ToLower().indexOf("guardian")
    if ( $idx -gt 0 )
    {
        log "La réponse du serveur n'est pas la bonne"
        log "Vérifier votre configuration de filtrage. exit=-4"
        return -4 
    } 
    
    $context = @{}
    switch -regex -file $saltMinionConfFile {
        "^#.*" {
            #Write-Host "commentaire"
        }
        "^([^=]+)=(.+?)$" {
            $name, $value = $matches[1..2]
            $context[$name] = $value
            log "context $name = $value"
        }
    }
    
    [string]$debugCtx = $context["debug"]
    if ( $debugCtx -eq "1" )
    {
        $debug = $true
        Set-PSDebug -Trace 1
    }
    
    #############################################################################
    # Phase 4 : identification de l'éxécutable à télécharger
    #############################################################################
    # salt-version contient la version + l'architecture
    if( [System.Environment]::Is64BitOperatingSystem )
    { 
        [string]$saltVersion = $context["salt-version-amd64"]
        if ( -Not ( $saltVersion ) )
        {
            log "La variable de configuration 'salt-version-amd64' n'existe pas. exit=-2"
            return -2
        }
        $saltInstallDir="c:\Program Files\Salt Project\Salt"
    }
    else
    { 
        [string]$saltVersion = $context["salt-version-x86"]
        if ( -Not ( $saltVersion ) )
        {
            log "La variable de configuration 'salt-version-x86' n'existe pas. exit=-2"
            return -2
        }
        $saltInstallDir="c:\Program Files (x86)\Salt Project\Salt"
    }
    log "saltVersion= $saltVersion"
    if ( $saltVersion -gt "3004" )
    {
        log "salt APRES 3004"
        $saltRootDir=$env:ProgramData + "\Salt Project\Salt"
    }
    else
    {
        log "Salt AVANT 3004"
        $saltInstallDir="c:\salt"
        $saltRootDir="c:\salt"
    }
    log "saltInstallDir=$saltInstallDir"
    log "saltRootDir=$saltRootDir"
    
    #############################################################################
    # Phase 5 : identification du minion installé (s'il existe)
    #############################################################################
    $doUninstall = $false
    $doInstall = $false
    $installersSalt = ((Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall") |
                        Where-Object { $_.GetValue( "DisplayName" ) -like "*Salt Minion*" } );
    if ( $installersSalt.Length -eq 0 )
    {
        if ( $env:PROCESSOR_ARCHITECTURE -eq 'AMD64' )
        {
            $installersSalt = ((Get-ChildItem "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall") |
                                Where-Object { $_.GetValue( "DisplayName" ) -like "*Salt Minion*" } );
        }
    }
    
    if ( $installersSalt.Length -eq 0 )
    {
        $installedSaltVersion = $null
        log "salt-minion n'est pas installé d'après Uninstall"
        $doInstall = $true
        
        #############################################################################
        # nous allons tester s'il reste des scories d'un ancien Salt
        $serviceSalt = ((Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\services" -ErrorAction SilentlyContinue) |
                        Where-Object { $_.GetValue( "DisplayName" ) -like "*Salt*" } );
        if ( $serviceSalt.Length -ne 0 )
        {
            log "le service salt-minion existe, mais je ne connais pas l'installeur !"
            if (!(Test-Path $saltInstallDir))
            {
                log "le service salt-minion existe, mais pas de répertoire $saltInstallDir ==> sc delete !"
                CMD.EXE /C "sc delete salt-minion"
            }    
        }
        else
        {
            log "le service salt-minion n'existe pas dans le registre."
        }
    }
    else
    {
        if ( $debug )
        {
           $installersSalt[0] | Out-Host
        }
        [string]$installedSaltVersion = $installersSalt[0].GetValue( "DisplayVersion" )
        [string]$uninstallMinion = $installersSalt[0].GetValue( "UninstallString" ) 
        log "installedSaltVersion = $installedSaltVersion"
        log "uninstallMinion = $uninstallMinion"
        if ( $saltVersion.startsWith($installedSaltVersion) )
        {
            log "la version de salt est déjà installée"
        }
        else
        {
            log "la version de salt doit être upgradée"
            $doUninstall = $true
            $doInstall = $true
        }
    }

    if ( $doInstall )
    {
        #############################################################################
        # Phase 6 : téléchargemenet de l'éxécutable
        #############################################################################
        $saltMinionSetupName="Salt-Minion-$saltVersion-Setup.exe"
        $saltMinionSetupUrl="http://$ipSaltMaster/joineole/saltstack/$saltMinionSetupName"
        $saltMinionSetupFile="$env:TEMP\$saltMinionSetupName"
        
        if (!(Test-Path $saltMinionSetupFile))
        {
            log "download '$saltMinionSetupUrl' ..."
            $cdu = doDownload -url1 $saltMinionSetupUrl -file1 $saltMinionSetupFile
            if( $cdu -eq 1)
            { 
                log "Impossible de télécharger '$saltMinionSetupUrl'. exit=-5"
                return -5 
            } 
            Unblock-File $saltMinionSetupFile
        }
    }

    if ( $doUninstall )
    {
        #############################################################################
        # Phase 7 : uninstall du service ?
        #############################################################################
        log "uninstall $uninstallMinion..."
        try
        {
            # l'uninstaller démarre lance un autre exe et s'arrete tout de suite ....
            CMD.EXE /C "$uninstallMinion" /S
            
            # il faut donc attendre un peu
            $i=1
            Do 
            { 
                if ( $debug )
                {
                    $installersSalt[0] | Out-Host
                }
                [string]$uninstalledSaltVersion = $installersSalt[0].GetValue( "DisplayVersion" ) 
                if ( -Not( $uninstalledSaltVersion ))
                {
                    break
                }
                Write-Host "attente uninstall $i"
                $i++
                Start-Sleep -s 10
            }
            while ($i -le 10)
            
            log "uninstall done"

            log "Clean minion configuration"
            if ( $installedSaltVersion -gt "3004" )
            {
                logDebug "Remove $saltRootDir\conf\minion file"
                Remove-Item -path "$saltRootDir\conf\minion"

                logDebug "Remove $saltRootDir\conf\minion.d directory"
                Remove-Item -recurse -path "$saltRootDir\conf\minion.d\"
            }
            else
            {
                logDebug "Remove c:\salt\conf\minion file"
                Remove-Item -path "c:\salt\conf\minion"

                logDebug "Remove c:\salt\conf\minion.d directory"
                Remove-Item -recurse -path "c:\salt\conf\minion.d\"
            }

            log "Move minion configuration ?"
            if ( $installedSaltVersion -lt "3004" )
            {
                if ( $saltVersion -gt "3004" )
                {
                    log "version actuelle $installedSaltVersion, et nouvelle $saltVersion --> déplacement conf"
                    if ( -Not( Test-Path( $saltRootDir )) )
                    {
                        New-Item -Path $saltRootDir -ItemType Directory -ErrorAction SilentlyContinue
                    }
                    $conf = Move-Item -Path C:\salt\conf\ -Destination $saltRootDir -PassThru
                    if ( $conf )
                    {
                        log "conf déplacée dans '$conf'"
                    }
                    else
                    {
                        log "ERREUR: 'conf' n'est pas déplacé !"
                    }
                    $var = Move-Item -Path C:\salt\var\ -Destination $saltRootDir -PassThru
                    if ( $var )
                    {
                        log "var déplacé dans '$var'"
                    }
                    else
                    {
                        log "ERREUR: 'var' n'est pas déplacée !"
                    }
                }
                else
                {
                    log "version actuelle $installedSaltVersion, et nouvelle $saltVersion --> pas de déplacement conf"
                }
            }
            else
            {
                log "version actuelle $installedSaltVersion --> Pas de déplacement du répertoire de conf Salt"
            }
        }
        catch
        {
            $_ | Out-Host # Output the thread pipeline error
            log "ERROR: uninstall failed"
            return -9
        }
    }

    if ( $doInstall )
    {
        #############################################################################
        # Phase 7 : install du service ?
        #############################################################################
        $pss = Get-Service 'salt-minion' -ErrorAction SilentlyContinue
        if ( $pss -eq $null )
        {
            log "service salt-minion n'existe pas, je l'installe ..."
            CMD.EXE /C "$saltMinionSetupFile" /S
            $pss = Get-Service 'salt-minion' -ErrorAction SilentlyContinue
            if ( $pss -eq $null )
            {
                log "Le service salt-minion n'existe pas après l'installation. C'est une erreur grave. exit=-6"
                return -6
            }
        }
        else
        {
            log "service salt-minion existe !"
        }

    }
        
    #############################################################################
    # Phase 7c : check présence salt-call.bat/exe
    #############################################################################
    $saltCallPath="$saltInstallDir\salt-call.bat"
    if (!(Test-Path "$saltCallPath" ))
    {
        $saltCallPath="$saltInstallDir\salt-call.exe"
        if (!(Test-Path "$saltCallPath" ))
        {
            log "Le script '$saltInstallDir\salt-call.exe/bat' n'existe pas. exit=-2"
            return -2
        }
        else
        {
            log "Le script '$saltInstallDir\salt-call.exe' existe."
        }
    }
    else
    {
        log "Le script '$saltInstallDir\salt-call.bat' existe."
    }
    
    #############################################################################
    # Phase 8 : configuration du minion avant re démarrage
    #############################################################################
    $startupConfPath="$saltRootDir\conf\minion.d\startup.conf"
    if (!(Test-Path $startupConfPath ))
    {
        log "---"
        log "Ecriture de '$startupConfPath'"
        & "$saltCallPath" --local file.write "$startupConfPath" 'startup_states: hightstate'

        log "Ajout des rôles ad/member, veyon/master et veyon/client"
        & "$saltCallPath" --local grains.append roles '["ad/member", "veyon/master", "veyon/client"]'

        #############################################################################
        # Phase 9 : redémarrage
        #############################################################################
        log "stop salt-minion..."
        Stop-Service -Name 'salt-minion' -ErrorAction SilentlyContinue
        log "start salt-minion..."
        Restart-Service 'salt-minion' -ErrorAction SilentlyContinue
    }
    else
    {
        log "salt-minion est déjà configuré."
    }

    #############################################################################
    # Phase 10 : vérification
    #############################################################################
    log "Lecture de '$startupConfPath'"
    & "$saltCallPath" --local file.read "$startupConfPath" | Write-Host

    log "Get-Content '$startupConfPath'"
    Get-Content "$startupConfPath" | Write-Host

    log "salt-minion ok"
    return 0
}

if ( $debug )
{
    Set-PSDebug -Trace 1
}
else
{
    Set-PSDebug -Trace 0
}
Start-Transcript -Path "$env:TEMP\install-minion.log"
$cdu = 255
try 
{
    $cdu = doInstallMinion
}
catch
{
    $_ | Out-Host # Output the thread pipeline error
}
finally
{
    Set-PSDebug -Trace 0
    Stop-Transcript -ErrorAction SilentlyContinue
}
exit $cdu
