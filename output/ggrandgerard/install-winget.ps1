
Write-Output "install-winget: début"
[int]$versionMajor = [environment]::OSVersion.version.Major
if( $versionMajor -lt 10)
{ 
    Log "OS non supporté"
    return
}

Set-ExecutionPolicy Bypass -Scope Process -Force
Set-Location c:\eole
if ( Test-Path c:\eole\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle )
{
    wget https://github.com/microsoft/winget-cli/releases/download/v0.1.4331-preview/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle
}    
Add-AppxPackage -Path c:\eole\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle -Register 

Write-Output "install-winget: fin"