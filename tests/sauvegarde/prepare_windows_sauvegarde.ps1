
Write-Host "* création répertoire"
New-Item "C:\sauvegardes" -type directory -ErrorAction silentlycontinue

Write-Host "* création partage"
New-SMBShare -Name "sauvegardes" -Path "C:\sauvegardes" -FullAccess pcadmin 

Write-Host "* liste partage"
Get-SmbShare
