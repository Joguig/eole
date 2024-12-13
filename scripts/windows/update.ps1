
. z:\scripts\windows\EoleCiFunctions.ps1

Write-Output "Début Update.ps1"

Write-Output "* Set-ExecutionPolicy ByPass"
Set-ExecutionPolicy -ExecutionPolicy ByPass -Force

Write-Output "Active services"
Set-Service wuauserv -StartupType Automatic -ErrorAction Ignore
Set-Service BITS -StartupType Automatic -ErrorAction Ignore

Write-Output "* --- "
Write-Output "* Start services"
Start-Service wuauserv -ErrorAction Ignore
Start-Service BITS  -ErrorAction Ignore

[int]$versionBuild = [environment]::OSVersion.version.Build
Write-Output "* versionBuild= $versionBuild"
$usePSWindowsUpdate=$true
if( $versionMajor -ge 10)
{ 
    if( $versionBuild -ge 17134)
    {
        $usePSWindowsUpdate=$false 
    }
}
$usePSWindowsUpdate=$true
    
if ( $usePSWindowsUpdate )
{
    Write-Output "* --- "
    if( $versionMajor -ge 10)
    { 
        Write-Output "* Install NuGet Windows11"
        Install-Package -Name NuGet -Force

        Write-Output "* Install PSWindowsUpdate Windows11"
        Install-Module PSWindowsUpdate -Force
    }
    else
    {
        Write-Output "* Install NuGet + PSWindowsUpdate"
        Install-PackageProvider -Name NuGet -Force
        Install-Module PSWindowsUpdate -Force
    }

    #Write-Output "* --- "
    #Write-Output "* Get-Command -module PSWindowsUpdate"
    #Get-Command -module PSWindowsUpdate | Select-Object Name, ParameterSets

    Write-Output "* --- "
    Write-Output "* Get-WUApiVersion"
    Get-WUApiVersion

    #Write-Output "* --- "
    #Write-Output "* Hide-WUUpdate"
    #Hide-WUUpdate -Title "OneDrive" -MicrosoftUpdate
     
    Write-Output "* --- "
    Write-Output "* Add-WUServiceManager"
    Add-WUServiceManager -ServiceID "7971f918-a847-4430-9279-4a52d1efe18d" -AddServiceFlag 7 -Confirm:$false
    
    Write-Output "* --- "
    Write-Output "* Get-WUList"
    Get-WUList -MicrosoftUpdate -ErrorAction Ignore | select-object kb,size,MsrcSeverity,title
    
    Write-Output "* --- "
    Write-Output "* Get-WindowsUpdate"
    Get-WUInstall -MicrosoftUpdate -NotCategory "Drivers" -NotTitle "OneDrive" -IgnoreReboot -AcceptAll -Confirm:$false -ErrorAction Ignore | Select-Object KB, Title
}
else
{
    Write-Output "* --- "
    Get-Command -Module WindowsUpdateProvider
    
    Write-Output "* Import-Module WindowsUpdateProvider"
    Import-Module WindowsUpdateProvider -ErrorAction Ignore
    Get-Module WindowsUpdateProvider | select HelpInfoURI,Version 
    
        
    Write-Output "* --- "
    Write-Output "* Start-WUScan"
    $updates = Start-WUScan -SearchCriteria "Type='Software' AND IsInstalled=0"
    $updates
    foreach( $u in $updates)
    {
        Write-Output "* --- "
        Write-Output "* Install-WUUpdates $u"
        Install-WUUpdates -Update $u -ErrorAction SilentlyContinue
    }

    do 
    {
        Write-Output "* wait install (30s)"
        Start-Sleep -s 30
        $installerStatus = Get-WUInstallerStatus
    } while ($installerStatus.isBusy ) 

    Write-Output "* wait install (30s)"
    Write-Output "* --- "
    Write-Output "* Get-WUIsPendingReboot"
    Get-WUIsPendingReboot
}

Write-Output "* --- "
Write-Output "* Fin"

 