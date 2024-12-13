
Set-ExecutionPolicy RemoteSigned -scope CurrentUser
Write-Output "install-scoop: début"

Set-Location c:\eole
Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')

Write-Output "install-scoop: fin"