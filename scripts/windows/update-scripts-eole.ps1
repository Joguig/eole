$OutputEncoding = [Console]::OutputEncoding
try
{
    $Error.clear()
    Write-Host "* update-script-eole.ps1 début"
    [Console]::OutputEncoding = [Text.UTF8Encoding]::ASCII
    
    if ( -not ( Test-Path c:\eole ) ) 
    {
        mkdir c:\eole 
    }
    
    Write-Host "* Copy scripts ps1"
    Get-ChildItem -path Z:\scripts\windows -File | ForEach-Object ` {
         Write-Host "* Copy scripts " + $_.fullname
         try
         {
             Copy-Item -Path $_.fullname -Destination c:\eole   
         }  
         Catch
         {
            Write-Host " Impossible de copier " + $_.fullname
         }       
    }

}
Catch
{
    "# Error: $_.Exception.Message"
    "# FailedItem: $_.Exception.ItemName"
    $Error | ForEach-Object { Write-Host $_ }
}
finally
{
    $events = Get-Event | Remove-Event
    Write-Host "* update-script-eole.ps1 fin"
}

0
