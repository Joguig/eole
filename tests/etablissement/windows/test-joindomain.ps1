$vmConfiguration = $args[0]
$vmVersionMajeurCible = $args[1]
$displayConnection = $args[2]
. z:\scripts\windows\EoleCiFunctions.ps1
initializeContextDomain $vmConfiguration $vmVersionMajeurCible

function diagConnection()
{
    Write-Output "* diagConnection"
    try
    {
        & z:\tests\etablissement\windows\dcdiag.ps1 $vmConfiguration $vmVersionMajeurCible true
    }
    catch
    {
    }
}
    
function eoleJoinDomain() 
{
    Write-Output "* JoinDomain domain=$adRealm, user=$adDomainAndUserAdmin, pwd=$adPasswordAdmin"
    $sethPasswd = ConvertTo-SecureString $adPasswordAdmin -AsPlainText -Force
    $sethCredential = New-Object System.Management.Automation.PSCredential ($adDomainAndUserAdmin, $sethPasswd)
    try
    {
        Write-Output "* Add Computer to $adRealm"
        Set-ExecutionPolicy Bypass -Scope Process -Force
        $Error.clear()
        
        Write-Output "* ConfirmPreference $ConfirmPreference"
        Write-Output "* SupportsShouldProcess $SupportsShouldProcess"
        
        $ConfirmPreference = "lower"
        Write-Output "* ConfirmPreference $ConfirmPreference"
        
        #cf. https://docs.microsoft.com/fr-fr/troubleshoot/windows-server/identity/troubleshoot-errors-join-computer-to-domain
        #cf. https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/joindomainorworkgroup-method-in-class-win32-computersystem
        
        # cf. https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/add-computer?view=powershell-5.1
        Add-Computer -DomainName $adRealm -Credential $sethCredential -ErrorAction Stop 
        if ( $Error.HasSucceeded )
        {
            Write-Output "* Pc join au domaine OK!"
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultDomainName" -Value "$adRealm"
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableFirstLogonAnimation" -Value "0"
        }
        else
        {
            $Error | Write-Output
        }
        
    }
    catch
    {
        # pas trouvé d'autre moyen pour faire cela !!!
        $e = $_
        switch -regex ($e.Exception.Message) 
        {
          ".*car il se trouve*" 
             { 
                Write-Output "l'ordinateur est déjà inscrit !" 
                $vmId | Out-File -Encoding ASCII -FilePath "$systemDrive\eole\domain-jointed.txt"
                $Error.clear()
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
             $e.Exception.Message | Write-Output 
             }
        }
        Write-Output "* ------------ " 
    }

    if( Test-Path ( "C:\Windows\debug\NetSetup.LOG" ) )
    {
        Copy-Item C:\Windows\debug\NetSetup.LOG Z:\output\$vmOwner\$vmId\NetSetup.LOG
        Write-Output "EOLE_CI_PATH NetSetup.LOG"
    }
    else
    {
        Write-Host "* C:\Windows\debug\NetSetup.LOG N'EXISTE PAS (bizarre) !"
    }
}


if ( $versionWindows -eq "7" )
{
    if ( $vmVersionMajeurCible -lt "2.8" )
    {
        Write-Host "HACK: test-joindomain.ps1 Windows 7 -> test service salt-minion résiduel... " 
        $pss = Get-Service 'salt-minion' 
        if ( $pss )
        {
            $pss.Status

            $TempDir = [System.IO.Path]::GetTempPath()
            Write-Host "test-joindomain.ps1: TempDir = '$TempDir' ..."
            Set-Location $TempDir

            Write-Host "test-joindomain.ps1: sc delete salt-minion... "
            CMD.EXE /C "sc delete salt-minion" | Write-Host 
        }
    }
}

try 
{
    if ( $versionWindows -gt "11" )
    {    
        Write-Output "* Pc win 11 disable ipv6"
        Get-NetAdapter | foreach { Disable-NetAdapterBinding -InterfaceAlias $_.Name -ComponentID ms_tcpip6 }
        Get-NetAdapter | foreach { Get-NetAdapterBinding -InterfaceAlias $_.Name -ComponentID ms_tcpip6 }
    }
    
    Write-Output "* ------------------------------- "
    Write-Output "* ------------------------------- "
    Write-Output "* ------------------------------- "
    eoleJoinDomain
    if ( -Not ( $Error ) )
    {
        Write-Output "* Pc join au domaine OK!"
        return $true
    }
    else
    {
        Write-Output "ERREUR: IMPOSSIBLE DE JOINDRE LE PC AU DOMAIN "
        diagConnection
        return $false
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
