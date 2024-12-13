$vmConfiguration = $args[0]
$vmVersionMajeurCible = $args[1]
$compteAUtiliser = $args[2]
initializeContextDomain $vmConfiguration $vmVersionMajeurCible

if ( $compteAUtiliser -eq "admin" )
{
    Set-Autologon "$adDomain" "$compteAUtiliser" "$adPasswordAdmin"
}
else
{
    Set-Autologon "$adDomain" "$compteAUtiliser" "$adPasswordUser"
}

Write-Host "----------------------------------------------------------------------"
Write-Host "cf: https://techcommunity.microsoft.com/t5/ask-the-directory-services-team/a-treatise-on-group-policy-troubleshooting-8211-now-with-gpsvc/ba-p/400304"
Write-Host "prepare-autologon: prépare debug GPO pendant reboot"
if( -Not( Test-Path ( "C:\Windows\debug\" ) ) )
{
    Write-Host "prepare-autologon: create C:\Windows\debug"
    $d = New-Item -Path C:\Windows -Name debug -ItemType "directory" -ErrorAction SilentlyContinue
}
if( -Not( Test-Path ( "C:\Windows\debug\usermode" ) ) )
{
    Write-Host "prepare-autologon: create C:\Windows\debug\usermode"
    $d = New-Item -Path C:\Windows\debug -Name usermode -ItemType "directory" -ErrorAction SilentlyContinue
}
if ( Test-Path( "c:\Windows\debug\usermode\gpsvc.log" ) )
{
    Write-Host "prepare-autologon: rm C:\Windows\debug\usermode\gpsvc.log"
    Remove-Item "c:\Windows\debug\usermode\gpsvc.log"
}
if ( Test-Path( "c:\Windows\debug\usermode\gpmgmt.log" ) )
{
    Write-Host "prepare-autologon: rm C:\Windows\debug\usermode\gpmgmt.log"
    Remove-Item "c:\Windows\debug\usermode\gpmgmt.log"
}

$DiagnosticsParentRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\"
$DiagnosticsRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Diagnostics"
$DiagnosticsReg = Get-ItemProperty -Path $DiagnosticsRegPath -ErrorAction SilentlyContinue
if ( -not ( $DiagnosticsReg ) )
{
    Write-Host "prepare-autologon: create $DiagnosticsParentRegPath\Diagnostics"
    $DiagnosticsReg = New-Item -Path $DiagnosticsParentRegPath -Name Diagnostics -ErrorAction SilentlyContinue
}
if ( $DiagnosticsReg )
{
    $GPSvcDebugLevel = ($DiagnosticsReg).GPSvcDebugLevel
    if ( -Not( $GPSvcDebugLevel ) )
    {
        Write-Host "prepare-autologon: Prepare GPSvcDebugLevel = 0x00030002"
        $GPSvcDebugLevel = New-ItemProperty -Path $DiagnosticsParentRegPath -Name GPSvcDebugLevel -Value 0x00030002 -PropertyType DWord -ErrorAction SilentlyContinue
    }
    else
    {
        Write-Host "prepare-autologon: Set GPSvcDebugLevel = 0x00030002"
        Set-ItemProperty -Path $DiagnosticsParentRegPath -Name GPSvcDebugLevel -Value 0x00030002 -PropertyType DWord -ErrorAction SilentlyContinue
    }
    $GPMgmtTraceLevel = ($DiagnosticsReg).GPMgmtTraceLevel
    if ( -Not( $GPMgmtTraceLevel ) )
    {
        Write-Host "prepare-autologon: Prepare GPMgmtTraceLevel = 2"
        $GPSvcDebugLevel = New-ItemProperty -Path $DiagnosticsParentRegPath -Name GPMgmtTraceLevel -Value 2 -PropertyType DWord -ErrorAction SilentlyContinue
    }
    else
    {
        Write-Host "prepare-autologon: Set GPMgmtTraceLevel = 2"
        Set-ItemProperty -Path $DiagnosticsParentRegPath -Name GPMgmtTraceLevel -Value 2 -PropertyType DWord -ErrorAction SilentlyContinue
    }
    $GPMgmtLogFileOnly = ($DiagnosticsReg).GPMgmtLogFileOnly
    if ( -Not( $GPMgmtLogFileOnly ) )
    {
        Write-Host "prepare-autologon: Prepare GPMgmtLogFileOnly = 1"
        $GPSvcDebugLevel = New-ItemProperty -Path $DiagnosticsParentRegPath -Name GPMgmtLogFileOnly -Value 1 -PropertyType DWord -ErrorAction SilentlyContinue
    }
    else
    {
        Write-Host "prepare-autologon: Set GPMgmtLogFileOnly = 1"
        Set-ItemProperty -Path $DiagnosticsParentRegPath -Name GPMgmtLogFileOnly -Value 1 -PropertyType DWord -ErrorAction SilentlyContinue
    }
}

# supprime la clé pour vérifier s'elles est recrée pas gpupdate
$PoliciesSystemRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
Write-Host "prepare-autologon: Gci $PoliciesSystemRegPath"
Get-ItemProperty -Path $PoliciesSystemRegPath | Format-Table

Write-Host "prepare-autologon: Prepare test EnableLinkedConnection"
$EnableLinkedConnections = (Get-ItemProperty -Path $PoliciesSystemRegPath).EnableLinkedConnections
Write-Host "prepare-autologon: EnableLinkedConnections = $EnableLinkedConnections"
if ( $EnableLinkedConnections -ne 0 )
{
    Write-Host "prepare-autologon: RESET EnableLinkedConnections = 0"
    Set-ItemProperty -Path $PoliciesSystemRegPath -Name EnableLinkedConnections -Value 0  -ErrorAction SilentlyContinue
}

Write-Host "prepare-autologon: Prepare test SyncForegroundPolicy"
# supprime la clé pour vérifier s'elles est recrée pas gpupdate
$WinlogonRegPath = "HKLM:\Software\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon"
$WinlogonReg = Get-ItemProperty -Path $WinlogonRegPath -ErrorAction SilentlyContinue
if ( -not ( $WinlogonReg ) )
{
    Write-Host "prepare-autologon: $WinlogonRegPath manque --> OK (?)"
}
else
{
    $SyncForegroundPolicy = $WinlogonReg.SyncForegroundPolicy
    Write-Host "prepare-autologon: SyncForegroundPolicy = $SyncForegroundPolicy"
    if ( -Not( $SyncForegroundPolicy ) )
    {
        Write-Host "prepare-autologon: SyncForegroundPolicy manque --> OK"
    }
    else
    {
        if ( $SyncForegroundPolicy -ne 0 )
        {
            Write-Host "prepare-autologon: SyncForegroundPolicy != 0 --> RESET"
            Set-ItemProperty -Path $WinlogonRegPath -Name SyncForegroundPolicy -Value 0  -ErrorAction SilentlyContinue
        }
        else
        {
            Write-Host "prepare-autologon: SyncForegroundPolicy = 0 --> OK"
        }
    }
}

Write-Host "prepare-autologon: Prepare test AsyncScriptDelay"
# supprime la clé pour vérifier s'elles est recrée pas gpupdate
$SystemRegPath = "HKLM:\Software\Policies\Microsoft\Windows\System"
$SystemReg = Get-ItemProperty -Path $SystemRegPath -ErrorAction SilentlyContinue
if ( -not ( $SystemReg ) )
{
    Write-Host "prepare-autologon: $SystemRegPath manque --> OK (?)"
}
else
{
    $AsyncScriptDelay = $SystemReg.AsyncScriptDelay
    Write-Host "prepare-autologon: AsyncScriptDelay = $AsyncScriptDelay"
    if ( -Not( $AsyncScriptDelay ) )
    {
        Write-Host "prepare-autologon: AsyncScriptDelay manque --> OK"
    }
    else
    {
        if ( $AsyncScriptDelay -ne 0 )
        {
            Write-Host "prepare-autologon: AsyncScriptDelay != 5 --> RESET"
            Set-ItemProperty -Path $SystemRegPath -Name AsyncScriptDelay -Value 5  -ErrorAction SilentlyContinue
        }
        else
        {
            Write-Host "prepare-autologon: AsyncScriptDelay = 5 --> OK"
        }
    }
}

# https://www.winhelponline.com/blog/users-must-enter-a-user-name-and-password-to-use-this-computer-missing-windows-10/
$PasswordLessPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device"
$PasswordLessReg = Get-ItemProperty -Path $PasswordLessPath -ErrorAction SilentlyContinue
if ( -not ( $PasswordLessReg ) )
{
    Write-Host "prepare-autologon: $PasswordLessPath manque --> OK (?)"
}
else
{
    $DevicePasswordLessBuildVersion = $PasswordLessReg.DevicePasswordLessBuildVersion
    Write-Host "prepare-autologon: DevicePasswordLessBuildVersion = $DevicePasswordLessBuildVersion"
    if ( -Not( $DevicePasswordLessBuildVersion ) )
    {
        Write-Host "prepare-autologon: DevicePasswordLessBuildVersion manque --> OK"
    }
    else
    {
        if ( $DevicePasswordLessBuildVersion -ne 0 )
        {
            Write-Host "prepare-autologon: DevicePasswordLessBuildVersion != 0 --> RESET"
            Set-ItemProperty -Path $PasswordLessPath -Name DevicePasswordLessBuildVersion -Value 0  -ErrorAction SilentlyContinue
        }
        else
        {
            Write-Host "prepare-autologon: DevicePasswordLessBuildVersion = 0 --> OK"
        }
    }
}

if( Test-Path ( "C:\Users\$compteAUtiliser" ) )
{
    if( Test-Path ( "C:\Users\$compteAUtiliser\AppData\Local\Temp\eole_script.log" ) )
    {
        Remove-Item "C:\Users\$compteAUtiliser\AppData\Local\Temp\eole_script.log"
        Write-Output "supression C:\Users\$compteAUtiliser\AppData\Local\Temp\eole_script.log: ok"
    }
    else
    {
        Write-Output "C:\Users\$compteAUtiliser\AppData\Local\Temp\eole_script.log n'existe pas: ok"
    }
}
else
{
    Write-Output "L'utilisateur ne s'est pas encore connecté.  C:\Users\$compteAUtiliser n'existe pas: ok"
}

if( Test-Path ( "C:\Windows\TEMP\install-minion.log" ) )
{
    if( Test-Path ( "C:\Windows\TEMP\install-minion.log" ) )
    {
        Remove-Item "C:\Windows\TEMP\install-minion.log"
        Write-Output "supression C:\Windows\TEMP\install-minion.log: ok"
    }
    else
    {
        Write-Output "C:\Windows\TEMP\install-minion.log n'existe pas: ok"
    }
}
else
{
    Write-Output "Le PC n'a pas été redémarré.  C:\Windows\TEMP\install-minion.log n'existe pas: ok"
}

Write-Output "* nettoyage de tous les logs !"
Wevtutil.exe el | Foreach-Object { 
    if ( $_ -eq "Microsoft-Windows-LiveId/Analytic" -or $_ -eq "Microsoft-Windows-LiveId/Operational" )
    {
        Write-Output "$_ ignoré"
    }
    else
    {
        Wevtutil.exe cl $_
    }
}

"* powercfg /H OFF : Impératif, sinon le service de contextulization ne serait pas lancé (car il est System)."
"Le démarrage rapide crée un 'snapshot' du démarrage système... avant de démarrer les services réseaux et autres ..."
& reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t reg_dword /d 0 /f
& powercfg /H OFF
     
Write-Output "* fin"