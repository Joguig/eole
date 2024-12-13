$vmConfiguration = $args[0]
$vmVersionMajeurCible = $args[1]
. c:\eole\EoleCiFunctions.ps1
initializeContextDomain $vmConfiguration $vmVersionMajeurCible

Set-Location c:\eole

try 
{
    Set-ExecutionPolicy Bypass -Scope Process -Force
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
    $OutputEncoding = [ System.Text.Encoding]::UTF8  

    if ( -Not( Test-Path( "Z:\output\$vmOwner\$vmId" ) ) )
    {
        $d = New-Item -Path Z:\output\ -Name $vmOwner -ItemType "directory" -ErrorAction SilentlyContinue
        $d = New-Item -Path Z:\output\$vmOwner -Name $vmId -ItemType "directory" -ErrorAction SilentlyContinue
    }
    
    if ( -Not( Test-Path( "c:\Program Files\Veyon" ) ) )
    {
        Write-Host "ERREUR: test-veyon: VEYON n'est pas installé !"
        exit 1
    }
    else
    {
        Set-Location "c:\Program Files\Veyon"
        gci "c:\Program Files\Veyon"

        $TempDir = [System.IO.Path]::GetTempPath()
        Write-Host "test-veyon: TempDir = '$TempDir' ..."

        Write-Output "test-veyon: veyon-cli.exe ldap query computers" 
        $log="$TempDir\ldap.log"
        if( Test-Path ( $log ) )
        {
            Remove-Item $log
        }
        CMD.EXE /C "veyon-cli.exe ldap query computers >$log"
        if( Test-Path ( "$log" ) )
        {
            $content = Get-Content "$log"
            "$content" | Write-Output
            if ( "$content" -eq "[OK]" )
            {
                Write-Host "ERREUR: test-veyon: ldap query vide ! (seulement OK) "
            }
        }
        else
        {
            Write-Host "ERREUR: test-veyon: $log manque !"
        }
        
        try
        {
           Write-Output "test-veyon: Query AD Computers (REALM=$adRealm)" 
           #$Search = [adsisearcher]"(&(objectCategory=Computer))"
           #$search.searchRoot = [adsi]"LDAP://$adRealm"
           #$search.PropertiesToLoad.AddRange(('cn','location','operatingSystem'))
           #$Search.FindAll() | Foreach-Object {
           #   $prop=$_.properties
           #   Write-Output "$($prop.cn): location='$($prop.location)', operatingSystem='$($prop.operatingSystem)'"
           #}
        }
        Catch 
        {
            $_ | Out-Host
            Write-Host "err test-veyon " $_.Name 
        }

        Write-Output "test-veyon: veyon-cli.exe config export c:\eole\config.json" 
        CMD.EXE /C "veyon-cli.exe config export c:\eole\config.json" | Write-Output
        if( Test-Path ( "c:\eole\config.json" ) )
        {
            Copy-Item c:\eole\config.json Z:\output\$vmOwner\$vmId\config.json
            Write-Output "EOLE_CI_PATH config.json"
            Get-Content c:\eole\config.json | Write-Output 
        }
        else
        {
            Write-Host "ERREUR: test-veyon: config.json manque !"
            exit 1
        }
        
    }
    exit 0
}
catch
{
    $Error | Write-Output
    Write-Output "Caught an exception:"
    Write-Output "Exception Type: $($_.Exception.GetType().FullName)"
    Write-Output "Exception Message: $($_.Exception.Message)"
    exit -1
}
finally 
{
    Write-Output "test-salt-minion: fin"
    Set-PSDebug -Trace 0
}
