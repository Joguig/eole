Write-Host "* install-gpo-rennes.ps1 début"

if ( -Not ( Test-Path c:\eole\SqueletteGPO ) )
{
    Write-Host "* Expand-Archive SqueletteGPO.1.8.6.zip"
    Expand-Archive -Path SqueletteGPO.1.8.6.zip -DestinationPath c:\eole
    
    Write-Host "* Rename-Item c:\eole\SqueletteGPO.1.8.6 c:\eole\SqueletteGPO"
    Rename-Item c:\eole\SqueletteGPO.1.8.6 c:\eole\SqueletteGPO
}

Write-Host "* GCI c:\eole\SqueletteGPO"
GCI c:\eole\SqueletteGPO

Write-Host "* patch c:\eole\SqueletteGPO\Import-GPO-Dijon.ps1"
Copy-Item Installation-GPO.1.8.6-dijon c:\eole\SqueletteGPO\Installation-GPO.1.8.6.ps1
Unblock-File c:\eole\SqueletteGPO\Installation-GPO.1.8.6.ps1

Write-Host "* install-gpo-rennes.ps1 fin"
