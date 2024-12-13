$vmConfiguration = $args[0]
$vmVersionMajeurCible = $args[1]
$userATester = $args[2]
. z:\scripts\windows\EoleCiFunctions.ps1
initializeContextDomain $vmConfiguration $vmVersionMajeurCible

$userSessionAttendue="$adDomain\$userATester"
$PoliciesSystemRegPath="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$SystemRegPath="HKLM:\Software\Policies\Microsoft\Windows\System"
$WinlogonRegPath="HKLM:\Software\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon"

Set-Location c:\eole

Write-Host "----------------------------------------------------------------------"
Write-Host "wait-event-gpo :"

$ok = $false
$dansDomain = $false
$installMinionPresent = $false
$sessionOuverte = $false
$eoleScriptLogPresent = $false
$lastWriteTimeInstallMinionLog = 0
$lastWriteTimeEoleScriptLog = 0
$nbOkBeforeExit = 0
for ($i = 1; $i -lt 1000 ; $i++)
{
    Try
    {
        Start-Sleep -s 5
        
        # Secondes avec les millisecondes 
        Write-Host "$i " 
                
        $ok = $true
        
        if( 1,3,4,5 -contains ($computer.DomainRole) )
        {
            if( -Not( $dansDomain ) )
            {
                Write-Host " Ok dans le domaine"
                $dansDomain = $true
            }
        }
        else
        {
            $ok = $false
        }
    
        # doit être créer apres le reboot, mais on peut arriver ici avant l'execution !
        if( Test-Path ( "C:\Windows\TEMP\install-minion.log" ) )
        {
            $fichier = Get-Item "C:\Windows\TEMP\install-minion.log" 
            if( -Not( $installMinionPresent ) )
            {
                Write-Host " install-minion.log apparait"
                $installMinionPresent = $true
                $lastWriteTimeInstallMinionLog = $fichier.LastWriteTime 
            }
            else
            {
                if ( $lastWriteTimeInstallMinionLog -lt $fichier.LastWriteTime )
                {
                    Write-Host " install-minion.log modifié"
                    $lastWriteTimeInstallMinionLog = $fichier.LastWriteTime
                    $ok = $false 
                } 
            }
        }
        else
        {
            $ok = $false
        }
    
        $listU = Get-Process -IncludeUserName | Select-Object UserName,SessionId | Where-Object { $_.UserName -eq $userSessionAttendue } | Sort-Object UserName,SessionId -Unique  
        if ( $listU.Count -ne 0 )
        {
            if( -Not( $sessionOuverte ) )
            {
                Write-Host " Session '$userSessionAttendue' ouverte"
                $sessionOuverte = $true
            }
        }
        else
        {
            $ok = $false
        }

        $listU = (Get-WmiObject Win32_Process).commandLine 
        # | Where-Object { $_.Name -match 'Salt*' }
        if ( $listProcess )
        {
	        $interset = $listU | ?{ $listProcess -notcontains $_ }
	        $interset
        }
        else
        {
            $ok = $false
        }
        $listProcess = $listU
    
        if( Test-Path ( "C:\Users\${userATester}\AppData\Local\Temp\eole_script.log" ) )
        {
            $fichier = Get-Item "C:\Users\${userATester}\AppData\Local\Temp\eole_script.log"
            if( -Not( $eoleScriptLogPresent ) )
            {
                Write-Host " eole_script.log apparait"
                $eoleScriptLogPresent = $true
                $lastWriteTimeEoleScriptLog = $fichier.LastWriteTime 
            }
            else
            {
                if ( $lastWriteTimeEoleScriptLog -lt $fichier.LastWriteTime )
                {
                    Write-Host " eole_script.log modifié"
                    $lastWriteTimeEoleScriptLog = $fichier.LastWriteTime
                    $ok = $false 
                    $nbOkBeforeExit = 0 
                } 
            }
        }
        else
        {
            $ok = $false
        }
        
        Write-Host $message
        if( $ok )
        {
            if( $nbOkBeforeExit -eq 50 )
            {
                Write-Host "Ok, sortie"
                Write-Host " DansDomain = $dansDomain"
                Write-Host " InstallMinionPresent = $installMinionPresent"
                Write-Host " SessionOuverte = $sessionOuverte"
                Write-Host " EoleScriptLogPresent = $eoleScriptLogPresent"
                exit 0
            }
            else
            {
                $nbOkBeforeExit = $nbOkBeforeExit + 1
                Write-Host "Ok, delay"
            }
        }
    }
    catch
    {
        $_ | Out-Host
        Write-Host "wait-event " $_.Name
    }
}
Write-Host "Ok, sortie mais en erreur !"
Write-Host " DansDomain = $dansDomain"
Write-Host " InstallMinionPresent = $installMinionPresent"
Write-Host " SessionOuverte = $sessionOuverte"
Write-Host " EoleScriptLogPresent = $eoleScriptLogPresent"

Get-Process -IncludeUserName | Format-Table -AutoSize -Wrap
exit 0
