try 
{
    Set-ExecutionPolicy Bypass -Scope Process -Force
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
    $OutputEncoding = [ System.Text.Encoding]::UTF8  

    . z:\scripts\windows\EoleCiFunctions.ps1
    
    Write-Host "test-salt-minion: Test-Connection 'salt'"
    Test-Connection salt -ErrorAction SilentlyContinue | Format-Table -Property PSComputerName,ResponseTime,ReplyInconsistency,ResolveAddressNames
    
    #$TempDir = [System.IO.Path]::GetTempPath()
    $TempDir = "C:\WINDOWS\TEMP\"
    Write-Output "* test-joineole-271: TempDir = '$TempDir' ..."
    Set-Location "$TempDir"
    
    Write-Output "ATTENTION test-salt-minion.ps1: téléchargement de installMinion.conf" 
    doDownload -url1 "http://salt/joineole/installMinion.conf" -file1 "$TempDir\installMinion.conf"

    if( -Not ( Test-Path "$TempDir\installMinion.conf" ) )
    {
        Write-Output "ERREUR: impossible de télécharger installMinion.conf, stop!"
        exit 1 
    }
    Get-Content "$TempDir\installMinion.conf"

    $context = @{}
    switch -regex -file "$TempDir\installMinion.conf" {
        "^#.*" {
            #Write-Host "commentaire"
        }
        "^([^=]+)=(.+?)$" {
            $name, $value = $matches[1..2]
            $context[$name] = $value
            log "context $name = $value"
        }
    }
    
    if( [System.Environment]::Is64BitOperatingSystem )
    { 
        [string]$saltVersion = $context["salt-version-amd64"]
        if ( -Not ( $saltVersion ) )
        {
            log "La variable de configuration 'salt-version-amd64' n'existe pas. exit=-2"
            return -2
        }
    }
    else
    { 
        [string]$saltVersion = $context["salt-version-x86"]
        if ( -Not ( $saltVersion ) )
        {
            log "La variable de configuration 'salt-version-x86' n'existe pas. exit=-2"
            return -2
        }
    }
    log "saltVersion= $saltVersion"
    if ( $saltVersion -gt "3004" )
    {
        $saltInstallDir="c:\Program Files\Salt Project\Salt"
        $saltRootDir=$env:ProgramData + "\Salt Project\Salt"
    }
    else
    {
        $saltInstallDir="c:\salt"
        $saltRootDir="c:\salt"

        $Folder = "C:\salt"
        $User = "pcadmin"
        $permission = (Get-Acl $Folder -errorAction SilentlyContinue).Access | ?{$_.IdentityReference -match $User} | Select IdentityReference,FileSystemRights
        If ($permission)
        {
            $permission | % {Write-Host "User $($_.IdentityReference) has '$($_.FileSystemRights)' rights on folder $folder"}
        }
        Else
        {
            Write-Host "$User Doesn't have any permission on $Folder"
        
            Write-Output "test-salt-minion: donne les droits c:\salt a pcadmin !"
            CMD.EXE /C "icacls C:\salt /grant pcadmin:(OI)(CI)F /T" | Out-File c:\eole\salt_icacls.log 
            Copy-Item c:\eole\salt_icacls.log Z:\output\$vmOwner\$vmId\salt_icacls.log
            Write-Output "EOLE_CI_PATH salt_icacls.log"
        }
    }
    log "saltRootDir=$saltRootDir"
    if ( Test-Path( $saltRootDir ) )
    {
        Gci $saltRootDir
    }
    else
    {
        log "pas de répertoire : $saltRootDir"
    }
    
    log "saltInstallDir=$saltInstallDir"
    if ( Test-Path( $saltInstallDir ) )
    {
        Gci $saltInstallDir
        
        $saltCallPath="$saltInstallDir\salt-call.bat"
        if (!(Test-Path "$saltCallPath" ))
        {
             $saltCallPath="$saltInstallDir\salt-call.exe"
             if (!(Test-Path "$saltCallPath" ))
             {
                log "Le script '$saltInstallDir\salt-call.exe/bat' n'existe pas"
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
    }
    else
    {
        log "pas de répertoire : $saltInstallDir"
        $saltCallPath="salt-call"
    }
    Write-Output "test-salt-minion: $saltCallPath --version (avec PATH !)" 
    $v = & "$saltCallPath" --version
    Write-Output $v 
    
    log "* salt call version : $v" 
    if ( $saltVersion.indexOf("3004") -ge 0 )
    {
        if ( $v ) 
        {
            if ( $v.indexOf("3004") -gt 0 )
            {
                log "Version Salt : '$v' == attendue '$saltVersion', OK"
            }
            else
            {
                log "ERREUR: Version Salt : '$v' != attendue '$saltVersion', NOK"
            }
        }
        else
        {
            log "ERREUR: Version Salt : '$v' != attendue '$saltVersion', NOK"
        }
    }
    else
    {
        log "Version Salt : '$v', attendue '$saltVersion'"
    }
    
    log "* salt-call --local --versions-report"
    & "$saltCallPath" --local --versions-report
    
    Write-Output "test-salt-minion: get log "
    if ( test-Path( "$saltRootDir\var\log\salt\minion" ))
    { 
        Copy-Item "$saltRootDir\var\log\salt\minion" Z:\output\$vmOwner\$vmId\salt_minion.log
        Write-Output "EOLE_CI_PATH salt_minion.log"
    }
    else
    {
        log "ERREUR: test-salt-minion: pas de log !"
    }

    Write-Host "displayJoinStatus"
    displayJoinStatus
    if( -Not( 1,3,4,5 -contains ($computer.DomainRole) ))
    { 
        Write-Host "ERREUR: pas dans le domaine, exit 1"
        exit 1
    }
}
catch
{
    $Error | Write-Output
    Write-Output "test-salt-minion: catch exception:"
    Write-Output "test-salt-minion: $($_.Exception.GetType().FullName)"
    Write-Output "ERREUR: test-salt-minion: $($_.Exception.Message)"
    exit -1
}
finally 
{
    Write-Output "test-salt-minion: fin"
    Set-PSDebug -Trace 0
}
