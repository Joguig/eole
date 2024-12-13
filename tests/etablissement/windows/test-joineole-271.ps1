try 
{
    Set-ExecutionPolicy Bypass -Scope Process -Force
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
    $OutputEncoding = [ System.Text.Encoding]::UTF8  
    
    $debug=$false
    $mode="EXE"
    
    . z:\scripts\windows\EoleCiFunctions.ps1
    
    if ( $args.count -gt 0 )
    {
        if( $args[0] -eq "debug" )
        {
            $debug=$true
        }
        if ( $args.count -gt 1 )
        {
            $mode=$args[1]
        }
    }
    Write-Output "Debug=$debug"
    Write-Output "Mode=$mode"

    if ( $mode -eq 'EXE' )
    {
        $file = "installMinion.exe"
    }
    else
    {
        $file = "installMinion.ps1"
    }

    $url="http://salt/joineole/$file"

    if ($PSVersionTable.PSVersion.Major -le 4)
    {
        Write-Output "* test-joineole-271: You must use PowerShell 4.0 or above."
        exit -1
    }
    Write-Output "* test-joineole-271: " $PSVersionTable.PSVersion

    $TempDir = [System.IO.Path]::GetTempPath()
    Write-Output "* test-joineole-271: TempDir = '$TempDir' ..."
    Set-Location "$TempDir"

    Write-Output "* test-joineole-271: test service salt-minion résiduel... " 
    $pss = Get-Service 'salt-minion' -ErrorAction SilentlyContinue 
    if ( $pss )
    {
        $pss.Status
        Write-Output "* test-joineole-271: sc delete salt-minion... " 
        CMD.EXE /C "sc delete salt-minion" | Write-Output 
    }

    diagnoseNetwork
 
    Write-Output "* test-joineole-271: essai de téléchargement de installMinion.conf avant appel à Joineole (qui le fera...)" 
    doDownload -url1 "http://salt/joineole/installMinion.conf" -file1 "installMinion.conf"
    
    if( -Not ( Test-Path "$TempDir\installMinion.conf" ) )
    {
        Write-Output "ERREUR: impossible de télécharger installMinion.conf, stop!"
        exit 1 
    }
    Get-Content "$TempDir\installMinion.conf"

    $context = @{}
    switch -regex -file "$TempDir\installMinion.conf" {
        "^#.*" {
            #Write-Output "commentaire"
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
            exit -2
        }
    }
    else
    { 
        [string]$saltVersion = $context["salt-version-x86"]
        if ( -Not ( $saltVersion ) )
        {
            log "La variable de configuration 'salt-version-x86' n'existe pas. exit=-2"
            exit -2
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
    }
    log "saltInstallDir=$saltInstallDir"
    log "saltRootDir=$saltRootDir"
    
    $cdu = doDownload -url1 $url -file1 $file
    if( $cdu -eq 1)
    { 
        exit -4 
    } 

    $installMinionLog = "$TempDir\install-minion.log"
    if( Test-Path $installMinionLog )
    {
        Remove-Item -Path $installMinionLog
    }
    
    Write-Output "---"
    Write-Output "HACK: test-joindomain: route print 192. (avant)"
    CMD.EXE /C "route print 192.*"
    
    Write-Output "HACK: test-joindomain: route delete 192.168.253.1"
    CMD.EXE /C "route delete 0.0.0.0 192.168.253.1"
    
    Write-Output "HACK: test-joindomain: route print 192. (apres)"
    CMD.EXE /C "route print 192.*"
    
    Write-Output "* test-joineole-271: Appel de l'executable '$file' ..."
    if ( $mode -eq 'EXE' )
    {
       CMD.EXE /C "$TempDir\$file" 2>&1 | Out-Host
       $cdu=$LASTEXITCODE
    }
    else
    {
       & "$TempDir\$file" | Out-Host
       $cdu=$LASTEXITCODE
    }
    if ( $cdu -ne 0 )
    {
        Write-Output "ERREUR: LASTEXITCODE = $cdu"
    }
    else
    {
        Write-Output "${file} LASTEXITCODE = $cdu, OK"
    }
    Write-Output "* test-joineole-271: dir '$saltInstallDir'"
    if ( -Not( Test-Path ( $saltInstallDir ) ) )
    {
       Write-Output "* test-joineole-271: $file ==> NOK"
       exit 1
    } 

    Write-Output "* test-joineole-271: $file ==> OK"

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
    
    Write-Output "* test-joineole-271: $saltCallPath --version" 
    & "$saltCallPath" --version | Write-Output 

    Write-Output "* test-joineole-271: APRES: wmic ComputerSystem get PartOfDomain,Domain" 
    wmic ComputerSystem get PartOfDomain
   
    Write-Output "* test-joineole-271: inject log-level" 
    if ( Test-Path( $saltRootDir ) )
    {
        $minionDConf = "$saltRootDir\conf\minion.d"
        if ( -Not(  Test-Path( $minionDConf ) ) )
        {
            New-Item -Path "$minionDConf" -ItemType Directory
        }
        if ( -Not(  Test-Path( "$minionDConf" ) ) )
        {
            Write-Output "ERREUR: test-joineole-271: impossible de créer '$dir' !! "
        }
        else
        {
            $logConf = "$minionDConf\log_level.conf"
            if ( -Not(  Test-Path( $logConf ) ) )
            {
                & "$saltCallPath" --local file.write "$logConf" 'log_level: debug'
                Write-Output "ATTENTION: test-joineole-271: $logConf injecté !! "
                
                Write-Output "test-joineole-271 : stop salt-minion..."
                Stop-Service -Name 'salt-minion' -ErrorAction SilentlyContinue
                
                Write-Output "test-joineole-271 : start salt-minion..."
                Restart-Service 'salt-minion' -ErrorAction SilentlyContinue
            }
            else
            {
                Write-Output "ATTENTION: test-joineole-271: $logConf existe !! "
            }
            
            Write-Output "-----------------------------------------------------------"
            Write-Output "'$saltCallPath' --local file.read $logConf"
            & "$saltCallPath" --local file.read "$logConf"
            Write-Output "-----------------------------------------------------------"
        }
    }
    else
    {   
        Write-Output "ERREUR: test-joineole-271: pas de repertoire '$saltRootDir' !! "
    }
   
   Write-Output "* test-joineole-271: exit => " $cdu
   exit $cdu
}
catch
{
    $Error | Out-Host
    Write-Output "Caught an exception:" -ForegroundColor Red
    Write-Output "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
    Write-Output "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
    exit -1
}
