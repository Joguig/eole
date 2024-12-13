function log($t) {
    Write-Output $t
}

function copyAll($p) {
    if ( Test-Path $p )
    {
        log "copie répertoire $p"
        Get-ChildItem -path $p -File | ForEach-Object ` {
                Copy-Item -Path $_.fullname -Destination c:\eole\download   
            }  
    }
    else
    {
        log "pas de répertoire $p"
    }
    return 0
}

function doCopyFolder( $source, $destination)
{
    try 
    {
        if ( -Not ( Test-Path $source ) )
        {
           return 
        } 

        if ( -Not ( Test-Path $destination ) )
        {
           New-Item -Path $destination -ItemType directory -force
        } 
        
        Get-ChildItem -path $source -File | ForEach-Object ` {
             Write-Output "* Copy " + $_.fullname
             try
             {
                 Copy-Item -Path $_.fullname -Destination $destination   
             }  
             Catch
             {
                Write-Output " Impossible de copier " + $_.fullname
             }       
        }          
    }
    catch
    {
        $_ | Write-Output
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

    # cas normal, pas de log
    #log "mountUnit unitDisk='$unitDisk', share='$share', pathToTest='$pathToTest' "
    try
    {
        if( Test-Path $pathToTest )
        {
            return 0
        }
        $pass = "eole"| ConvertTo-SecureString -AsPlainText -Force
        $Cred = New-Object System.Management.Automation.PsCredential('root',$pass)

        $driveZ = New-PSDrive -Name "$unitDisk" -PSProvider FileSystem -Root "$share" -Credential $Cred -Scope Global
        if( Test-Path $pathToTest )
        {
            # cas normal, pas de log
            return 0
        }
        
        $driveZ = New-PSDrive -Name "$unitDisk" -PSProvider FileSystem -Root "$share" -Credential $Cred 
        if( Test-Path $pathToTest )
        {
            log "mountUnit $unitDisk 2 : ok,"
            return 0
        }
        
        $driveZ = New-PSDrive -Name "$unitDisk" -PSProvider FileSystem -Root "$share"  -Scope Global
        if( Test-Path $pathToTest )
        {
            log "mountUnit $unitDisk 3 : ok"
            return 0
        }

        $driveZ = New-PSDrive -Name "$unitDisk" -PSProvider FileSystem -Root "$share" 
        if( Test-Path $pathToTest )
        {
            log "mountUnit $unitDisk 4 : ok"
            return 0
        }

        log "* mountUnit $unitDisk : erreur"
        return 2
    }
    catch
    {
        log "* mountUnit $unitDisk : Erreur.."
        log "* mountUnit $unitDisk : $_.Exception.Message"
        return 2
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
    try
    {
        <#
            Add dangerous code here that might produce exceptions.
            Place as many code statements as needed here.
            Non-terminating errors must have error action preference set to Stop to be caught.
        #>
        Write-Output "********************************************"
        $Error.clear()
    
        [string]$url = $url1.ToString()
        $file="$env:TEMP\$file1"
        Write-Output "doDownload: $url1 -> $file"
        if( Test-Path $file )
        {
            Remove-Item -Path $file
        }
    
        $StatusCode = 0 
        try
        {
            $ProgressPreference = 'SilentlyContinue'
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
            $wc = New-Object Net.WebClient
            $wc.UseDefaultCredentials = $true
            $wc.Proxy = $null
            $wc.Encoding = [System.Text.Encoding]::UTF8
            $wc.CachePolicy = New-Object Net.Cache.HttpRequestCachePolicy([System.Net.Cache.HttpRequestCacheLevel]::NoCacheNoStore)
    
            Write-Output "doDownload: essai DownloadFile $url dans $file1"
            $wc.DownloadFile($url, $file)
        }
        catch
        {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            if ( $debug )
            {
                $_ | Out-Host # Output the thread pipeline error
            }
        }
    
        if( !(Test-Path $file ))
        { 
            # Win 7, 8, 2012 ... <= Win 10 !
            try 
            {
                #############################################################################
                # Préparation Invoke hhtprequest pour avoir un debug
                #############################################################################
                Set-UseUnsafeHeaderParsing -Enable

                # avec DisableKeepAlive ! 
                Write-Output "doDownload: essai avec Invoke-WebRequest $url"
                $r = Invoke-WebRequest -Uri $url -OutFile $file -Method Get -DisableKeepAlive -UseDefaultCredentials -useBasicParsing
                $StatusCode = $r.StatusCode
                if ( $StatusCode -ne "200" )
                {
                    log "------------------------------------------------"
                    log "Headers:"
                    $r.Headers
                    log "------------------------------------------------"
                }
            }
            catch
            {
                $StatusCode = $_.Exception.Response.StatusCode.value__
                if ( $debug )
                {
                    $_ | Out-Host # Output the thread pipeline error
                    log "StatusCode = $StatusCode"
                }
            }
        }
        Write-Output "doDownload: StatusCode = $StatusCode"
            
        if( !(Test-Path $file ))
        { 
            Write-Output "doDownload: Impossible de downloader '$url'. Stop!"
            return 1 
        }
        else
        { 
            Write-Output "doDownload: '$url' downloaded"
            Write-Output "doDownload: Unblock-File $file"
            Unblock-File $file
            return 0
        }
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
        Write-Output "Caught an exception:" -ForegroundColor Red
        Write-Output "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
        Write-Output "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
        return -1
    }
    finally
    {
        Write-Output "********************************************"
        Write-Output " "
    }
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

function Get-StatusFromValue
{
 Param($SV)
 switch($SV)
  {
   0 { " Disconnected" }
   1 { " Connecting" }
   2 { " Connected" }
   3 { " Disconnecting" }
   4 { " Hardware not present" }
   5 { " Hardware disabled" }
   6 { " Hardware malfunction" }
   7 { " Media disconnected" }
   8 { " Authenticating" }
   9 { " Authentication succeeded" }
   10 { " Authentication failed" }
   11 { " Invalid Address" }
   12 { " Credentials Required" }
   Default { "Not connected" }
  }
}

#usage: Test-UserCredential -username UserNameToTest -password (Read-Host)

Function Test-UserCredential { 
    Param($username,
          $password) 
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement 
    $ct = [System.DirectoryServices.AccountManagement.ContextType]::Machine, $env:computername 
    $opt = [System.DirectoryServices.AccountManagement.ContextOptions]::SimpleBind 
    $principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ct 
    if ($null -eq $principalContext) 
    {
        Write-Output "$Domain\$User - AD Authentication failed"
    }
    else
    {
        if ($principalContext.ValidateCredentials($User, $Password))
        {
            Write-Output -ForegroundColor green "$Domain\$User - AD Authentication OK"
        }
        else
        {
            Write-Output "$Domain\$User - AD Authentication failed credential"
        }
    }
} 

function Test-ADAuthentication {
    Param(
        [Parameter(Mandatory)]
        [string]$User,
        [Parameter(Mandatory)]
        $Password,
        [Parameter(Mandatory = $false)]
        $Server,
        [Parameter(Mandatory = $false)]
        [string]$Domain = $env:USERDOMAIN
    )
  
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    
    $contextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
    
    $argumentList = New-Object -TypeName "System.Collections.ArrayList"
    $null = $argumentList.Add($contextType)
    $null = $argumentList.Add($Domain)
    if($null -ne $Server){
        $argumentList.Add($Server)
    }
    
    $principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $argumentList -ErrorAction SilentlyContinue
    if ($null -eq $principalContext) 
    {
        Write-Output "$Domain\$User - AD Authentication failed"
    }
    else
    {
        if ($principalContext.ValidateCredentials($User, $Password))
        {
            Write-Output -ForegroundColor green "$Domain\$User - AD Authentication OK"
        }
        else
        {
            Write-Output "$Domain\$User - AD Authentication failed credential"
        }
    }
}

function initializeContextDomain($vmConfiguration, $vmVersionMajeurCible)
{
    $vmConfiguration="$vmConfiguration".Trim()
    Write-Output "initializeContextDomain [vmConfiguration = $vmConfiguration, vmVersionMajeurCible = $vmVersionMajeurCible]" 
    $global:adUserAdmin="admin"
    $global:adPasswordAdmin = "Eole12345!"
    $global:adPasswordUser = "Eole12345!"
    $global:adRealm="${vmConfiguration}.ac-test.fr"
    $global:adRealmDN="DC=${vmConfiguration},DC=ac-test,DC=fr"
    $global:adDomain=${vmConfiguration}.ToUpper()
    $global:proxyHost=""
    $global:proxyPort=""

    switch ( $vmConfiguration )
    {
      domseth
              {
                $global:adDNSServers="192.168.0.5 192.168.0.6"
                $global:proxyHost=""
                $global:proxyPort=""
              }
              
      etb3 
              {
                $global:adDNSServers="10.3.2.5"
                $global:adRealm="etb3.lan"
                $global:adRealmDN="DC=etb3,DC=lan"
                $global:proxyHost="10.3.2.2"
                $global:proxyPort="3128"
              }
          
      dompedago 
              {
                $global:adDNSServers="10.1.3.11"
                $global:adRealm="dompedago.etb1.lan"
                $global:adRealmDN="DC=dompedago,DC=etb1,DC=lan"
                $global:proxyHost="10.1.2.1"
                $global:proxyPort="3128"
              }
          
      domadmin
              {
                $global:adDNSServers="10.1.1.10"
                $global:adRealm="domadmin.etb1.lan"
                $global:adRealmDN="DC=domadmin,DC=etb1,DC=lan"
                $global:proxyHost=""
                $global:proxyPort=""
              }
          
      domscribe
              {
                $global:adDNSServers="192.168.0.30"
                $global:proxyHost=""
                $global:proxyPort=""
              }

      default 
              {
                Write-Output "* default !"
              }
    }

    if ( $vmVersionMajeurCible -lt "2.7" )
    {
       # avant 2.7, toujours 'eole'
       $global:adPasswordAdmin = "eole"
       $global:adPasswordUser = "eole"
       Write-Output "* Exception 1 : $vmVersionMajeurCible $adDomain -> pwdAdmin=$global:adPasswordAdmin, pwdUser=$global:adPasswordUser"
    }
    else
    {
        if ( $vmVersionMajeurCible -lt "2.8.0" )
        {
            # avant 2.8, si ScribeAD ou HorusAD -> seul admin/eole !
            if ( -Not( $adDomain -eq "DOMSETH" ) )
            {
                $global:adPasswordAdmin = "eole"
                Write-Output "* Exception 3 : $vmVersionMajeurCible $adDomain -> pwdAdmin=$global:adPasswordAdmin, pwdUser=$global:adPasswordUser"
            }
            else
            {
                Write-Output "* Exception 4 : $vmVersionMajeurCible $adDomain -> pwdAdmin=$global:adPasswordAdmin, pwdUser=$global:adPasswordUser"
            }
        }
        else
        {
            Write-Output "* Exception 5 : $vmVersionMajeurCible $adDomain -> pwdAdmin=$global:adPasswordAdmin, pwdUser=$global:adPasswordUser"
        }
    }

    #$global:adDomainAndUserAdmin="$adDomain\admin"
    $global:adDomainAndUserAdmin="admin@$adRealm"
    $global:adSecurePasswordAdmin = ConvertTo-SecureString $adPasswordAdmin -AsPlainText -Force
    if ( $debug )
    {
        Write-Output "* adUserAdmin=$adUserAdmin"
        Write-Output "* adDomainAndUserAdmin=$adDomainAndUserAdmin"
        Write-Output "* adPasswordAdmin=$adPasswordAdmin"
        Write-Output "* adPasswordUser=$adPasswordUser"
        Write-Output "* adRealm=$adRealm"
        Write-Output "* adRealmDN=$adRealmDN"
        Write-Output "* adDomain=$adDomain"
        Write-Output "* adDNSServers=$adDNSServers"
        Write-Output "* proxyHost=$proxyHost"
        Write-Output "* proxyPort=$proxyPort"
    }
}

function Set-Proxy( $server, $port)
{
    if ( $server -eq "" )
    {
        Write-Output "Pas de proxy"
        return
    }
     
    If ((Test-NetConnection -ComputerName $server -Port $port).TcpTestSucceeded) 
    {
        Write-Output "Set proxy server :  $($server):$($port)"
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyServer -Value "$($server):$($port)"
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyEnable -Value 1
    }
    Else
    {
        Write-Error -Message "Invalid proxy server address or port:  $($server):$($port)"
    }
}

function Set-AutoLogon($Domain, $User, $Password)
{
    $WinlogonRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    Set-ItemProperty -Path $WinlogonRegPath -Name "AutoAdminLogon"    -Value "1"         -type String
    Set-ItemProperty -Path $WinlogonRegPath -Name "DefaultDomainName" -Value "$Domain"   -type String
    Set-ItemProperty -Path $WinlogonRegPath -Name "DefaultUsername"   -Value "$User"     -type String
    Set-ItemProperty -Path $WinlogonRegPath -Name "DefaultPassword"   -Value "$Password" -type String
    $WinlogonReg = Get-ItemProperty -Path $WinlogonRegPath -ErrorAction SilentlyContinue
    $DefaultDomainName = ($WinlogonReg).DefaultDomainName
    $DefaultUsername = ($WinlogonReg).DefaultUsername
    $DefaultPassword = ($WinlogonReg).DefaultPassword
    $AutoAdminLogon = ($WinlogonReg).AutoAdminLogon
    Write-Output "Autologon : AutoAdminLogon=$AutoAdminLogon DefaultDomainName=$DefaultDomainName DefaultUsername=$DefaultUsername DefaultPassword=$DefaultPassword"
}



function Get-ScreenCapture
{
    param(    
    [Switch]$OfWindow,
    [String]$path
    )

    begin {
        Add-Type -AssemblyName System.Drawing
        $jpegCodec = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | 
            Where-Object { $_.FormatDescription -eq "JPEG" }
    }
    process {
        Start-Sleep -Milliseconds 250
        if ($OfWindow) {            
            [Windows.Forms.Sendkeys]::SendWait("%{PrtSc}")
        } else {
            [Windows.Forms.Sendkeys]::SendWait("{PrtSc}")
        }
        if ( -Not($path) ) {
            $path = $PWD
        }
        Start-Sleep -Milliseconds 250
        $bitmap = [Windows.Forms.Clipboard]::GetImage()
        $ep = New-Object Drawing.Imaging.EncoderParameters  
        $ep.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality, [long]100)  
        $screenCapturePathBase = "$path\ScreenCapture"
        $c = 0
        while (Test-Path "${screenCapturePathBase}${c}.jpg")
        {
            $c++
        }
        $bitmap.Save("${screenCapturePathBase}${c}.jpg", $jpegCodec, $ep)
    }
}

function Take-ScreenShot
{
    param(    
    [String]$path
    )

    begin {
        [Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
    }
    
    process {
        $width = 0;
        $height = 0;
        $workingAreaX = 0;
        $workingAreaY = 0;

        $screen = [System.Windows.Forms.Screen]::AllScreens;

        foreach ($item in $screen)
        {
            if($workingAreaX -gt $item.WorkingArea.X)
            {
                $workingAreaX = $item.WorkingArea.X;
            }

            if($workingAreaY -gt $item.WorkingArea.Y)
            {
                $workingAreaY = $item.WorkingArea.Y;
            }

            $width = $width + $item.Bounds.Width;

            if($item.Bounds.Height -gt $height)
            {
                $height = $item.Bounds.Height;
            }
        }

        $bounds = [Drawing.Rectangle]::FromLTRB($workingAreaX, $workingAreaY, $width, $height); 
        $bmp = New-Object Drawing.Bitmap $width, $height;
        $graphics = [Drawing.Graphics]::FromImage($bmp);

        $graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size);

        $bmp.Save($path);

        $graphics.Dispose();
        $bmp.Dispose();
    }
}

function runElevated()
{
    log "* runElevated: " $script:MyInvocation.MyCommand.Path
    # Get the ID and security principal of the current user account
    $myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent();
    $myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID);
        
    # Get the security principal for the administrator role
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator;
        
    # Check to see if we are currently running as an administrator
    if ($myWindowsPrincipal.IsInRole($adminRole))
    {
        log "* runElevated: in elevated session "
    }
    else 
    {
        log "* runElevated: We are not running as an administrator, so relaunch as administrator "
        $cdu = "-1"
        try
        {
            $Error.Clear()
            
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.Verb = "runas"
            $pinfo.RedirectStandardError = $true
            $pinfo.RedirectStandardOutput = $true
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true
            $pinfo.FileName = "powershell.exe"
            $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -c & '" + $script:MyInvocation.MyCommand.Path + "'"
    
            $Process = New-Object system.Diagnostics.Process
            $Process.StartInfo = $pinfo
            $Process.Start() 
            
            Start-Sleep -s 1
            do
            {
               $ligne = $Process.StandardOutput.ReadLine()
               Log $ligne 
               Start-Sleep -MilliSeconds 50
            }
            while (!$Process.HasExited)
            
            while (!$Process.StandardOutput.EndOfStream)
            {
               $ligne = $Process.StandardOutput.ReadLine()
               Log $ligne
            }
    
            while (!$Process.StandardError.EndOfStream)
            {
               $ligne = $Process.StandardError.ReadLine()
               Log $ligne
            }
    
            $cdu = $Process.ExitCode
            Log "ExitCode ==> $cdu" 
        }
        Catch
        {
            $Error | Write-Output
            $Error.Clear()
        }
        finally
        {
            $cdu
        }
        Exit;
    }
}  

function runSystem()
{
    log "* runSystem: " $script:MyInvocation.MyCommand.Path
    # Get the ID and security principal of the current user account
    $myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent();
    $myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID);
        
    # Get the security principal for the administrator role
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator;
        
    # Check to see if we are currently running as an administrator
    if ($myWindowsPrincipal.IsInRole($adminRole))
    {
        log "* runSystem: in elevated session "
        # We are running as an administrator, so change the title and background colour to indicate this
    }
    else 
    {
        log "* runSystem: We are not running as an administrator, send ps1 to System "
        $baseNamePs1 = $script:MyInvocation.MyCommand
        $baseName = $baseNamePs1 -replace ".ps1", ""
        $todo = "C:\eole\todo\${baseNamePs1}"
        $running = "C:\eole\running\${baseNamePs1}"
        $exit = "C:\eole\done\${baseName}.exit"
        $log = "C:\eole\done\${baseName}.log"
        
        Remove-Item -Path $exit -ErrorAction SilentlyContinue
        Remove-Item -Path $running -ErrorAction SilentlyContinue
        Remove-Item -Path $todo -ErrorAction SilentlyContinue

        Copy-Item $script:MyInvocation.MyCommand.Path $todo 
        
        $state = 0
        $count = 200
        $reader = $null
        $cdu = -1
        $LastFilePos = 0
        do
        {
            $count = $count - 1
            Start-Sleep -s 10
            if ( Test-Path $todo )
            {
                log "* attente prise en charge"
            }

            if ( Test-Path $log )
            {
                try
                {
                    $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList (New-Object -TypeName IO.FileStream -ArgumentList ($log, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([IO.FileShare]::Delete, ([IO.FileShare]::ReadWrite))))
                    $null = $reader.BaseStream.Seek($LastFilePos, [System.IO.SeekOrigin]::Begin)
                    while ( $null -ne ($line = $reader.ReadLine()) )
                    {
                        Log $line
                        $count = 20
                    }
                    $LastFilePos = $reader.BaseStream.Position
                }
                finally
                {
                    if ( $reader )
                    {
                        $reader.Close()
                        $reader.Dispose()
                    }
                }
            }
            if ( Test-Path $exit )
            { 
                $cdu = Get-Content $exit
                log "RunSystem Get-Content $exit ==> $cdu"
                Break
            }
        }
        while( $count -gt 0 )
        Remove-Item -Path $exit -ErrorAction SilentlyContinue
        Remove-Item -Path $running -ErrorAction SilentlyContinue
        Remove-Item -Path $log -ErrorAction SilentlyContinue
        log "RunSystem ExitCode ==> $cdu"
        Exit
    }
}    

function runZPath()
{
    mountUnit "Z" $partage "Z:\ModulesEole.yaml"
    Z:
    if ( $debug )
    {
        GCI 
    }
    if ( -Not( Test-Path( "Z:\output\$vmOwner\$vmId" ) ) )
    {
        $d = New-Item -Path Z:\output\ -Name $vmOwner -ItemType "directory" -ErrorAction SilentlyContinue
        $d = New-Item -Path Z:\output\$vmOwner -Name $vmId -ItemType "directory" -ErrorAction SilentlyContinue
    }
    $env:Path += ";${mypath}"
    Set-Location $myHome
}

function displayJoinStatus()
{
    Write-Output "displayJoinStatus: Get-ADComputer status " 
    Write-Output "----------------------------------------------------"
    $computer = Get-WmiObject win32_computersystem
    $computer
    Switch ($computer.DomainRole)
    {
      0     { Write-Output "displayJoinStatus: DomainRole = Stand-alone workstation"}
      1     { Write-Output "displayJoinStatus: DomainRole = Member workstation"}
      2     { Write-Output "displayJoinStatus: DomainRole = Stand-alone server"}
      3     { Write-Output "displayJoinStatus: DomainRole = Member server"}
      4     { Write-Output "displayJoinStatus: DomainRole = Domain controller"}
      5     { Write-Output "displayJoinStatus: DomainRole = Pdc emulator domain controller"}
    }
    
    if(1,3,4,5 -contains ($computer.DomainRole) )
    { 
       Write-Output "displayJoinStatus: Machine dans le domaine OK"
    }
    else
    {
       Write-Output "ERROR: check-joindomain: Machine n'est pas dans le domaine"
    }
}

function doChocoInstall( $soft )
{
    $Date = Get-Date
    $now += "{0:00}:{1:00}:{2:00}" -f $Date.Hour, $Date.Minute, $Date.Second
    log "***********************************"
    log "* choco install $soft ($now)"
    choco install --no-progress --yes --nocolor $soft 
    choco upgrade --no-progress --yes --nocolor $soft
    log "***********************************"
}

function downloadIfNeeded($u, $f) {
    log "Download $f"
    if( -not ( test-Path c:\eole\download\$f ) )
    {
		$client = New-Object System.Net.WebClient
        $client.DownloadFile( $u, "c:\eole\download\$f" )
    }
}

function ciPingHost( $nom )
{
    Write-Output "******************************************************"
    log "* ciPingHost: ping $nom" 
    Test-Connection -Count 3 -ComputerName $nom -ErrorAction SilentlyContinue | Format-Table -Property PSComputerName,ResponseTime,ReplyInconsistency,ResolveAddressNames | Write-Output
}

function ciPingIp( $ip )
{
    Write-Output "******************************************************"
    Write-Output "* ciPingIp: ping $ip" 
    Test-Connection -Count 3 $ip -ErrorAction SilentlyContinue  | Format-Table -Property PSComputerName,ResponseTime,ReplyInconsistency,ResolveAddressNames | Write-Output
}

function diagnoseNetwork()
{
    Write-Output "******************************************************"
    Write-Output "* diagnoseNetwork : début"

    # pas de fonction Get-DnsClient sur Win7 ! 
    if ( $versionWindows -ne "7" )
    {
        Write-Output "* diagnoseNetwork: Get-DnsClient" 
        Get-DnsClient

        Write-Output "* diagnoseNetwork: Get-DnsClientGlobalSetting" 
        Get-DnsClientGlobalSetting
    
        Write-Output "* diagnoseNetwork: Get-DnsClientServerAddress" 
        Get-DnsClientServerAddress | Format-Table -Property AddressFamily,InterfaceAlias,ElementName,Address 
    }
    
    Write-Output "---"
    Write-Output "* diagnoseNetwork: win32_networkadapter status"
    Get-WmiObject -Class win32_networkadapter -computer '.' |
        Select-Object Name, @{LABEL="Status";EXPRESSION={Get-StatusFromValue $_.NetConnectionStatus}}
    
    Write-Output "---"
    Write-Output "* diagnoseNetwork: ipconfig /all"
    CMD.EXE /C "ipconfig /all"

    Write-Output "---"
    Write-Output "* diagnoseNetwork: route PRINT"
    CMD.EXE /C "route PRINT"
    
    Write-Output "---"
    Write-Output "* diagnoseNetwork: Get-NetRoute -AddressFamily IPv4 -PolicyStore PersistentStore"
    Get-NetRoute -AddressFamily IPv4 -PolicyStore PersistentStore | Write-Output
    
    Write-Output "---"
    Write-Output "* diagnoseNetwork: Pc win 11 registre Tcpip\parameters"
    try
    {
        Get-ItemProperty Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Tcpip\parameters\ | Write-Output
    }
    catch
    {
        Write-Output "* -- Erreur !"
    }

    Write-Output "---"
    Write-Output "* diagnoseNetwork: Pc win 11 registre Tcpip\parameters\PersistentRoutes"
    try
    {
        Get-ItemProperty Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Tcpip\parameters\PersistentRoutes  | Write-Output
    }
    catch
    {
        Write-Output "* -- Erreur !"
    }
    
    Write-Output "---"
    Write-Output "* diagnoseNetwork: Pc win 11 registre Netlogon\Parameters"
    try
    {
        Get-ItemProperty Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Netlogon\Parameters  | Write-Output
    }
    catch
    {
        Write-Output "* -- Erreur !"
    }
    
    
    Write-Output "---"
    Write-Output "* diagnoseNetwork: ping salt"
    ciPingHost salt 

    Write-Output "---"
    Write-Output "* diagnoseNetwork: AVANT: wmic ComputerSystem get PartOfDomain,Domain" 
    wmic ComputerSystem get PartOfDomain

    Write-Output "* diagnoseNetwork : fin"
    Write-Output "******************************************************"
}

function disableWindowsUpdate()
{
    # avant de déactiver WindowsUpdate, je m'assure que l'auto upgrade de l'OS est déactivé au cas ou l'une des maj l'aurais réactivé !
    $WindowsUpdateKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
    $Update_Never    = 1
    $Update_Check    = 2
    $Update_Download = 3
    $Update_Auto     = 4
    Set-ItemProperty -Path $WindowsUpdateKey -Name AUOptions       -Value $Update_Never -Force -Confirm:$false
    Set-ItemProperty -Path $WindowsUpdateKey -Name CachedAUOptions -Value $Update_Never -Force -Confirm:$false

    Write-Output "Désactive services wuauserv"
    Stop-Service -Name wuauserv
    Set-Service -Name wuauserv -StartupType Disabled

    Write-Output "Désactive services BITS"
    Stop-Service -Name BITS
    Set-Service -Name BITS -StartupType Disabled
}

function enableWindowsUpdate()
{
    # avant d activer WindowsUpdate, je m'assure que l'auto upgrade de l'OS est déactivé !
    $WindowsUpdateKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
    $Update_Never    = 1
    $Update_Check    = 2
    $Update_Download = 3
    $Update_Auto     = 4
    Set-ItemProperty -Path $WindowsUpdateKey -Name AUOptions       -Value $Update_Never -Force -Confirm:$false
    Set-ItemProperty -Path $WindowsUpdateKey -Name CachedAUOptions -Value $Update_Never -Force -Confirm:$false

    # réactivation
    Write-Output "Active services wuauserv"
    Set-Service -Name wuauserv -StartupType Automatic  -ErrorAction Ignore
    Start-Service -Name wuauserv  -ErrorAction Ignore
    
    Write-Output "Active services BITS"
    Set-Service -Name BITS -StartupType Automatic  -ErrorAction Ignore
    Start-Service BITS  -ErrorAction Ignore

    #$mgr = New-Object -ComObject Microsoft.Update.ServiceManager -Strict
    #$mgr.ClientApplicationID = "installer"
    #$mgr.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"")
}

function checkInstallRsatComponent( $appx )
{
   Get-WindowsCapability -Online | ? Name -like "$appx*" | Foreach ` {
      $n = $_.Name
      if ( $_.State -ne 'Installed' )
      { 
         log "Install RSAT: $n to install..."
         Add-WindowsCapability -online -name $n
         log "Install RSAT: $n installed"
      }
      else
      { 
         log "Install RSAT: $n is present"
      }
      
   }
}

function displayContext()
{
    Log "* systemDrive=$systemDrive"
    Log "* computerName = $computerName"
    Log "* ConnectionString= $ConnectionString"
    log "* versionMajor= $versionMajor"
    log "* versionBuild= $versionBuild"
    log "* VersionWindows= $VersionWindows"
    log "* vmId= $vmId"
    log "* vmOwner= $vmOwner"
    log "* vmMachine= $vmMachine"
    log "* debugLevel = $debugLevel"
    log "* myArgs = $myArgs"
    log "* myPath = $myPath"
    log "* myHome = $myHome"
    log "-------------------------" 
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
    log "-------------------------"
}

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
[string]$systemDrive = "$env:SystemDrive"
[string]$computerName = "$env:computername"
[string]$ConnectionString = "WinNT://$computerName"
[int]$versionMajor = [environment]::OSVersion.version.Major
[int]$versionBuild = [environment]::OSVersion.version.Build
[string]$VersionWindows = "?"
$computer = Get-WmiObject win32_computersystem

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
    Log "OS non supporté"
    return
}

if( $versionMajor -lt 10)
{ 
	if( $versionBuild -eq 7600)
	{ 
	    $VersionWindows = "2012"
    }
    if( $versionBuild -eq 7601 )
    { 
        $VersionWindows = "7"
    }
	if( $versionBuild -eq 9600)
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

if ( $VersionWindows -eq "?" )
{
	Log "* VersionWindows inconnue : $versionBuild $versionMajor"
	$VersionWindows = $versionMajor
}
#log "* VersionWindows= $VersionWindows"

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

$vmMachine       = $context["VM_MACHINE"]
if ( -not ( $vmMachine ) )
{
    log "* pas de ''VM_MACHINE'"
}

$ipEoleCiTest    = $context["VM_IP_EOLECITEST"]
if ( -not ( $ipEoleCiTest ) )
{
    $ipEoleCiTest = "192.168.0.253"
    log "* ipEoleCiTest= $ipEoleCiTest"
}

$partage = "\\$ipEoleCiTest\eolecitests"

$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent();
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID);
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator;

$global:adUserAdmin=""
$global:adDomainAndUserAdmin=""
$global:adPasswordAdmin = ""
$global:adPasswordUser = ""
$global:adRealm=""
$global:adRealmDN=""
$global:adDomain=""
$global:adUserAdmin=""
$global:adDNSServers=""
$global:proxyHost=""
$global:proxyPort=""

$vmDebug = $context["VM_DEBUG"]
if ( $vmDebug )
{
    $debug = $vmDebug
}

if ( $debug )
{
    displayContext
}

if ( $args.count -gt 0 )
{
    Write-Output "Appel avec $($args.count) argument(s)"
    for ( $i = 0; $i -lt $args.count; $i++ )
    {
        Write-Output "Argument $i : $($args[$i])"
    } 
}
if ( Test-Path( "Z:\output\" ) )
{
    $vmDir = "Z:\output\$vmOwner\$vmId"
    if ( -Not( Test-Path( $vmDir ) ) )
    {
        $d = New-Item -Path Z:\output\ -Name $vmOwner -ItemType "directory" -ErrorAction SilentlyContinue
        $d = New-Item -Path Z:\output\$vmOwner -Name $vmId -ItemType "directory" -ErrorAction SilentlyContinue
    }
    Write-Output "Repertoire partage Vm : $vmDir"
}