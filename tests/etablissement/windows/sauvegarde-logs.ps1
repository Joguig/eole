$vmConfiguration = $args[0]
$vmVersionMajeurCible = $args[1]

try 
{
    Set-Location c:\eole

    $TempDir = [System.IO.Path]::GetTempPath()
    Write-Host "test-veyon: TempDir = '$TempDir' ..."

    Write-Output "sauvegarde-logs: copye logs"
    Set-Location $TempDir
    gci "$TempDir" -Filter "*.log" | foreach-object {
        try
        {
            $log=$_.Name
            $idx = $log.indexOf("mat-debug" )
            if ( $idx -lt 0 )
            {
                Copy-Item $_ Z:\output\$vmOwner\$vmId\$log
                Write-Output "EOLE_CI_PATH $log"
            }
        }
        Catch 
        {
            $_ | Out-Host
            Write-Host "ERREUR: sauvegarde-logs " $_.Name 
        }
    }
    gci "$TempDir" -Filter "*.png" | foreach-object {
        try
        {
            $log=$_.Name
            Copy-Item $_ Z:\output\$vmOwner\$vmId\$log
            Write-Output "EOLE_CI_PATH $log"
        }
        Catch 
        {
            $_ | Out-Host
            Write-Host "ERREUR: sauvegarde-logs " $_.Name 
        }
    }
    gci "$TempDir" -Filter "*.jpg" | foreach-object {
        try
        {
            $log=$_.Name
            Copy-Item $_ Z:\output\$vmOwner\$vmId\$log
            Write-Output "EOLE_CI_PATH $log"
        }
        Catch 
        {
            $_ | Out-Host
            Write-Host "ERREUR: sauvegarde-logs " $_.Name 
        }
    }

    try
    {
        (Get-WinEvent -ListProvider Microsoft-Windows-GroupPolicy).Events | Format-Table -AutoSize -Wrap Id, Description, Level| Out-File "Z:\output\$vmOwner\$vmId\Microsoft-Windows-GroupPolicy.log"
        Write-Output "EOLE_CI_PATH Microsoft-Windows-GroupPolicy.log"
    }
    Catch 
    {
        Write-Host "Warnings: sauvegarde event windows Microsoft-Windows-GroupPolicy impossible" 
    }
}
finally 
{
    Write-Output "sauvegarde-logs: fin"
    Set-PSDebug -Trace 0
}
