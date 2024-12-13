
$location = get-location

# tache: MicrosoftEdgeUpdateTaskMachineCore
#        MicrosoftEdgeUpdateTaskMachineUA

Write-Host "désactivation edgeupdate !"
#taskkill.exe /f /im "edgeupdate.exe"
#taskkill.exe /F /IM "edge.exe"

Get-Package -name "*Microsoft Edge*" | Uninstall-Package

Get-AppxPackage -name "*MicrosoftEdge*" | Format-Table

$EdgeVersion = (Get-AppxPackage "Microsoft.MicrosoftEdge" -AllUsers).Version
if ( -not( $EdgeVersion ) )
{
    return
}
$EdgeVersion

$MicrosoftPathX86 = ${env:ProgramFiles(x86)} + '\Microsoft'
#gci $MicrosoftPathX86 | ft
$MicrosoftPathX86Edge = $MicrosoftPathX86 + '\Edge'
#gci $MicrosoftPathX86Edge | ft

$MicrosoftPathX86EdgeApplication = $MicrosoftPathX86Edge + '\Application'
#gci $MicrosoftPathX86EdgeApplication | ft

$MicrosoftPathX86EdgeCore = $MicrosoftPathX86 + '\EdgeCore'
Get-ChildItem -Path $MicrosoftPathX86EdgeCore | Foreach-Object {
    Write-Host $_.FullName
    $versionPath = $MicrosoftPathX86EdgeCore + '\' + $_ 
    
    $installerPath = $versionPath + '\Installer\setup.exe'
    if ( test-Path $installerPath )
    {
        Write-Host $versionPath
        cd $versionPath
        #.\Installer\setup.exe --uninstall --system-level --verbose-logging --force-uninstall
    }
}

$MicrosoftPathX86EdgeUpdate = $MicrosoftPathX86 + '\EdgeUpdate'
gci $MicrosoftPathX86EdgeUpdate | Ft

$EdgeVersion = (Get-AppxPackage "Microsoft.MicrosoftEdge.Stable" -AllUsers).Version
if ( $EdgeVersion )
{
    $EdgeLstVersion=$EdgeVersion[-1]
    $EdgeSetupPath = $MicrosoftPathX86 + '\Edge\Application\' + $EdgeLstVersion
    #gci $EdgeSetupPath
    cd $EdgeSetupPath
    .\Installer\setup.exe --uninstall --system-level --verbose-logging --force-uninstall

    $WebView2SetupPath = $MicrosoftPathX86 + '\EdgeWebView\Application\' + $EdgeLstVersion + '\Installer'
    #gci $WebView2SetupPath
    cd $WebView2SetupPath
    .\setup.exe --uninstall --msedgewebview --system-level --verbose-logging

    set-location $location

    Set-item -Path "HKLM:\Software\Microsoft\EdgeUpdate"
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\EdgeUpdate" -Name DoNotUpdateToEdgeWithChromium -Type "DWORD" -Value 1 -Force

    Get-AppxPackage -AllUsers "*edge*"|select Name,PackageFullName
    Get-AppxPackage -allusers -Name Microsoft.MicrosoftEdge.Stable_103.0.1264.37_neutral__8wekyb3d8bbwe | Remove-AppxPackage -AllUsers
}
Write-Host "* déactivation Edgeupdate finie"

