Start-Transcript -Path "$env:temp\eole_script.log" -Append
Set-PSDebug -Trace 1

$before_netuse = @()
$after_netuse = @()

function read_logon_script($path) {

    if(test-path $path) {
        Write-Host "found", $path
        $is_before = $true
        Get-Content $path | ForEach-Object {
            if ( $_ -eq "%%NetUse%%" -or  $_ -eq "%NetUse%"  ) {
                $is_before = $false
            } elseif ( $is_before -eq $true) {
                $global:before_netuse += [System.Environment]::ExpandEnvironmentVariables($_)
            } else {
                $global:after_netuse += [System.Environment]::ExpandEnvironmentVariables($_)
            }
       }
    }
    else {
        Write-Host "not found $path"
    }
}

function execute_cmd($items) {
    if($items.length -gt 1) {
        $cmd, $args = $items[1].split(' ', 2, [System.StringSplitOptions]::RemoveEmptyEntries)
        if($cmd) {
            $hide = $false
            $wait = $true
            if ($items.length -gt 2) {
                $option = $items[2].Trim().ToUpper()
                if($option -eq "HIDDEN") {
                    $hide = $true
                } elseif ($option -eq "NOWAIT") {
                    $wait = $false
                } else {
                    Write-Host "Unknown option $option for cmd $items"
                    return
                }
            }
            if($items.length -gt 3) {
                $option = $items[3].Trim().ToUpper()
                if($option -eq "HIDDEN") {
                    $hide = $true
                } elseif ($option -eq "NOWAIT") {
                    $wait = $false
                } else {
                    Write-Host "Unknown option $option for cmd $items"
                    return
                }
            }
            if($hide) {
                $windowstyle = "Hidden"
            } else {
                $windowstyle = "Normal"
            }
            if($args) {
                Write-Host "Launch command $cmd with arguments $args"
                Start-Process -FilePath $cmd -WindowStyle $windowstyle -Wait:$wait -ArgumentList $args.split(' ')
            }
            else {
                Write-Host "Launch command $cmd WindowStyle:$windowstyle Wait:$wait"
                Start-Process -FilePath $cmd -WindowStyle $windowstyle -Wait:$wait
            }
        }
        else {
             Write-Host "Invalid line $items"
        }
    }
    else {
        Write-Host "Invalid line $items"
    }

}

function execute_drive($items) {
    if($items.length -ne 3) 
    {
       Write-Host "Invalid line '$items', ignore !"
       return 
    }
    
    Try {
        # si l'utilisateur a saisi R: --> R
        $argLetter = $items[1] -replace ':' , ''
        #Write-Host "Map drive '$argLetter'"
        [ValidatePattern('^[a-zA-Z]$')]$letter = $argLetter
    }
    catch 
    {
        Write-Host "Invalid letter for unit in '$items', ignore !"
        return 
    }

    Try {
        $unc = $items[2]
        Write-Host "Map drive '$unc' in '$letter'"
        New-SmbMapping -LocalPath "${letter}:" -RemotePath "$unc"
    }
    catch 
    {
        $string_err = $_ | Out-String
        return
    }
}

function execute($line) {
    $items = $line.Split(',')
    $type = $items[0]
    if( $type -eq 'cmd' ) {
        execute_cmd $items
    }
    elseif ( $type -eq 'lecteur' ) {
        execute_drive $items
    }
    else {
        Write-Host "unknown action type $_"
    }
}

#FIXME : $servername = $env:USERDNSDOMAIN
#ou si serveur de logon : $env:LOGONSERVER
$scripts_path = "$env:LOGONSERVER\sysvol\$env:USERDNSDOMAIN\scripts"

# Personal script
$user = $env:USERNAME
$path = "$scripts_path\users\$user.txt"
read_logon_script $path

# pour raison de compatibilité
$path = "$scripts_path\os\Vista.txt"
read_logon_script $path

$major = [Environment]::OSVersion.Version.Major
$path = "$scripts_path\os\$major.txt"
read_logon_script $path

$build = [Environment]::OSVersion.Version.Build
$path = "$scripts_path\os\$major\$build.txt"
read_logon_script $path

# pour raison de compatibilité
$path = "$scripts_path\os\Vista\users\$user.txt"
read_logon_script $path
$path = "$scripts_path\os\$major\users\$user.txt"
read_logon_script $path
$path = "$scripts_path\os\$major\$build\users\$user.txt"
read_logon_script $path

# Groups scripts
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)

$Groups = $Identity.Groups | ForEach-Object { $_.Translate([Security.Principal.NTAccount]) }

$Groups |ForEach {
    $group = $_.toString()
    if ($group.StartsWith("$env:USERDOMAIN\")) {
        $group = $group.Split('\', 2)[1]
        $path = "$scripts_path\groups\$group.txt"
        read_logon_script $path
        # pour raison de compatibilité
        $path = "$scripts_path\os\Vista\groups\$group.txt"
        read_logon_script $path
        $path = "$scripts_path\os\$major\groups\$group.txt"
        read_logon_script $path
        $path = "$scripts_path\os\$major\$build\groups\$group.txt"
        read_logon_script $path
    }
}

$path = "$scripts_path\machines\$env:COMPUTERNAME.txt"
read_logon_script $path

$before_netuse |ForEach {
    execute $_
}
$after_netuse |ForEach {
    execute $_
}

Stop-Transcript
