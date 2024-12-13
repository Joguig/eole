Set-ExecutionPolicy Bypass -Scope Process -Force

try
{
    Import-PackageProvider ChocolateyGet
    choco install autoit
}
Catch
{
}

$source = @"
[global]
admin = admin
ip = 192.168.0.26
domaine = domaca
serveur = scribe
passwd = ZW9sZQ== 
veille = True 
showext = True
"@


function runCommand( [string] $ExeToRun )
{
  $chocTempDir = Join-Path $env:TEMP "test-joineole"
  
  $startInfo = new-object System.Diagnostics.ProcessStartInfo
  $startInfo.FileName = $exeToRun
  $startInfo.Arguments = "/SILENT"
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  $startInfo.UseShellExecute = $false
  
  $process = New-Object System.Diagnostics.Process
  $process.StartInfo = $startInfo
  $process.Start() | Out-Null
  $errorFile = Join-Path $chocTempDir "$($process.Id)-error.stream"
  $outputFile = Join-Path $chocTempDir "$($process.Id)-output.stream"
  $process.StandardOutput.ReadToEnd() | Out-File $outputFile
  $process.StandardError.ReadToEnd() | Out-File $errorFile
  $process.WaitForExit()

  if ($process.ExitCode -ne 0 )
  {
    try 
    {
      $innerError = Import-CLIXML $errorFile | ? { $_.GetType() -eq [String] } | Out-String
    }
    catch
    {
      $innerError = Get-Content $errorFile | Out-String
    }
    $errorMessage = "[ERROR] Running $exeToRun with $statements was not successful. Exit code was `'$($process.ExitCode)`' Error Message: $innerError."
    Remove-Item $errorFile -Force -ErrorAction SilentlyContinue
    throw $errorMessage
   }
}


function uninstallClientScribe ( $p )
{
    if ( Test-Path $p )
    { 
       Get-ChildItem $p | ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object { $_.DisplayName -Match "^Client Scribe*" -and !$_.SystemComponent -and !$_.ReleaseType -and !$_.ParentKeyName -and ($_.UninstallString -or $_.NoRemove) } | ForEach-Object {
            $DisplayName = $_.DisplayName
            $UninstallString = $_.UninstallString
            Write-Host "Uninstall $DisplayName with '$UninstallString'"
            runCommand $UninstallString
       }
    }
}

$servscribe = Get-Service servscribe -ErrorAction SilentlyContinue
if ( $servscribe )
{
    If(!([Diagnostics.Process]::GetCurrentProcess().Path -match '\\syswow64\\' )) 
    {
        uninstallClientScribe HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*
        uninstallClientScribe HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*
        uninstallClientScribe HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*
        uninstallClientScribe HKCU:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*
    }
    else 
    {
        “You are running 32-bit Powershell on 64-bit system. Please run 64-bit Powershell instead.” | Write-Host -ForegroundColor Red
        exit 1
    }
}
Set-PSDebug -Trace 0


$exit = 1
try
{
    Set-PSDebug -Trace 1
    if ( -not ( test-Path C:\eole\joineole ) )
    {
       mkdir c:\eole\joineole
    }
    
    $pass = "eole"| ConvertTo-SecureString -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PsCredential('admin',$pass)
    $drive = New-PSDrive -Name "X" -PSProvider FileSystem -Root "\\SCRIBE\admin" -Credential $Cred -Scope Global
    
    $childItems = Get-ChildItem X:\perso\integrDom
    $childItems | ForEach-Object {
        Write-Host "* Copy-Item $_"
        Copy-Item -Path $_.FullName -Destination C:\eole\joineole -Force
    }
    remove-PSDrive -Name "X" -Force
    
    Set-Location C:\eole\joineole
    
    $source | Out-File -Encoding ASCII C:\eole\joineole\joineole.cfg

    Remove-Item c:\eole\joineole\joinlog.log -ErrorAction SilentlyContinue
            
    #clean
    Get-ChildItem $env:TEMP | ForEach-Object {
        #Write-Host "* Temp $_"
        if ( $_.Attributes -match 'Directory' )
        { 
            #Write-Host "* Temp dir $_"
            $p = $_.FullName + "\joineole.exe.log"
            if ( Test-Path $p )
            {
                Write-Host "$p existe"
                Remove-Item $p
            }
        }
    }
    
    
    Set-Location C:\eole\joineole\
    
    $ProgramFiles = (${env:ProgramFiles(x86)}, ${env:ProgramFiles} -ne $null)[0]
    $ProgramFiles
    
    # AUTOIT3 
    Import-Module ($ProgramFiles + "\AutoIt3\AutoItX\AutoItX.psd1")
    Initialize-AU3
    
    Set-AU3Option -Option "TrayIconDebug" -Value 1
    
    Set-PSDebug -Trace 1
    $state = 0
    For ($i=0; $i -le 100; $i++) 
    {
        try
        {
            $cdu1 = Get-AU3WinState -Title "Errors occurred"
            $cdu2 = Get-AU3WinState -Title "Erreur"
            if ( ($cdu1 -ne 0) -or ($cdu2 -ne 0)  )
            {
                Write-Host "trouve joineole.exe.log"
                Set-PSDebug -Trace 0
                $env:TEMP
                Get-ChildItem $env:TEMP | ForEach-Object {
                    if ( $_.Attributes -match 'Directory' )
                    { 
                        $p = $_.FullName + "\joineole.exe.log"
                        if ( Test-Path $p )
                        {
                            Write-Host "$p existe"
                            Get-Content $p
                        }
                    }
                }
                Set-PSDebug -Trace 1
                
                Write-Host "Erreur $cdu"
                Invoke-AU3ControlClick -Title Erreur -Control "Button1" -NumClicks 1
                Sleep -Seconds 2
                $exit = 2
                break
            }
                
            $cdu = Get-AU3WinState -Title "joineole"
            $cdu
            if ( $cdu -eq 0)
            {
                if( $state -eq 0 )
                {
                    Invoke-AU3Run -Program "c:\eole\joineole\joineole.exe" -Dir "c:\eole\joineole\" -ErrorAction Stop
                    $state = 1
                }
                if( $state -gt 3 )
                {
                    Write-Host "Joineole quitté !!"
                    $exit = 1
                }
            }
            else
            {
                $status = Get-AU3StatusbarTexT -Title "joineole"
                Write-Host "$status"
                if ( "$status" -like "Installation termin*" )
                {
                    $exit = 0
                    break
                } 
                if ( $cdu -eq 15)
                {
                    if( $state -eq 1 )
                    {
                        Wait-AU3Win -Title joineole -Timeout 5 -ErrorAction Stop
                        Write-Host "Joineole démarré"
                        $state = 2
                    }
                    elseif( $state -eq 2 )
                    {
                        Wait-AU3WinActive -Title joineole -Timeout 10 -ErrorAction Stop
                        Write-Host "Joineole visible"
                        $state = 3
                    }
                    elseif( $state -eq 3 )
                    {
                      
                        Set-AU3ControlText -Title joineole -Control "Edit3" -NewText "eole" -ErrorAction Stop
                        Write-Host "mot de passe saisi"
                        Sleep -Seconds 2
                        
                        Invoke-AU3ControlClick -Title joineole -Control "Button2" -NumClicks 1  -ErrorAction Stop
                        Write-Host "redémarrage décoché"
                        Sleep -Seconds 2
                        
                        Invoke-AU3ControlClick -Title joineole -Control "Button3" -NumClicks 1  -ErrorAction Stop
                        Write-Host "submit"
                        $state = 4
                    }
                    elseif( $state -eq 7)
                    {
                        Write-Host "fin d'install OK"
                        $exit = 0
                        break
                    }
                }
                elseif ( $cdu -eq 7)
                {
                     Write-Host "install en cours (client scribe + service maj)"
                     $state = 5
                }
            }
            
            $cduClient = Get-AU3WinState -Title "Installation - Client Scribe"
            if ( $cduClient -eq 15)
            {
                Write-Host "install en cours client scribe"
                if( $state -eq 5 )
                {
                    $state = 6
                }
            }
            else
            {
                $cduClient
            }

            $cduMaj    = Get-AU3WinState -Title "Installation - Client Scribe - Service"
            if ( $cduMaj -eq 15)
            {
                {
                    Write-Host "install en cours service maj"
                    if( $state -eq 6 )
                    {
                        $state = 7
                    }
                }
            }
            else
            {
                $cduMaj
            }
            
            Sleep -Seconds 3
        }
        Catch 
        {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            $ErrorMessage
            $FailedItem
        }
    }

    Close-AU3Win -Title joineole -ErrorAction Stop
    Wait-AU3WinClose -Title joineole -ErrorAction Ignore
    if ( Test-Path c:\eole\joineole\joinlog.log )
    {
        Write-Host "content c:\eole\joineole\joinlog.log"
        Get-Content c:\eole\joineole\joinlog.log
        $exit = 0
    }
    else
    {
        Write-Host "c:\eole\joineole\joinlog.log manquant, bizarre"
        $exit = 1
    } 

}
Catch 
{
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    $ErrorMessage
    $FailedItem
}
Write-Host "exit $exit"
Set-PSDebug -Trace 0
exit $exit