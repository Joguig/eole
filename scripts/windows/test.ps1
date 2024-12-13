$userSessionAttendue="ETB3\admin1"
Write-Host "* est-ce que la session '$userSessionAttendue' est ouverte ?"
$listU = Get-Process -IncludeUserName | Select-Object UserName,SessionId | Where-Object { $_.UserName -eq $userSessionAttendue } | Sort-Object UserName,SessionId -Unique  
Write-Host "---------------"
$listU | Write-Host
if ( $listU.Count -ne 0 )
{
    Write-Host "* La session '$userSessionAttendue' est ouverte : OK"
}
else
{
    Write-Host "ERREUR: La session '$userSessionAttendue' n'est pas ouverte par autologon"
}
