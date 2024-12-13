$OutputEncoding = [Console]::OutputEncoding

#
# Cas 1 : on choisit le plus récent
#
$Error.clear()
$localFile = Get-Item "C:\eole\EoleCiTestsCommon.ps1"
$contextFile = Get-Item "D:\EoleCiTestsCommon.ps1"
if ($contextFile.LastWriteTime -gt $localFile.LastWriteTime)
{
    try
    {
        . "D:\EoleCiTestsCommon.ps1"
        doContext
        exit 0
    }
    Catch
    {
        "EoleCiTestContext # Error: $_.Exception.Message"
        "EoleCiTestContext # FailedItem: $_.Exception.ItemName"
        $Error | ForEach-Object { Write-Host $_ }
    }
    finally
    {
        # Flush all leftover events (There may be some that arrived after we exited the while event loop, but before we unregistered the events)
        $events = Get-Event | Remove-Event
        "EoleCiTestContext # Exiting"
    }
}

#
# Cas 2 : 1er fallback
#
$Error.clear()
try
{
    . "C:\eole\EoleCiTestsCommon.ps1"
    doContext
    exit 0
}
Catch
{
    "EoleCiTestContext # Error: $_.Exception.Message"
    "EoleCiTestContext # FailedItem: $_.Exception.ItemName"
    $Error | ForEach-Object { Write-Host $_ }
}
finally
{
    # Flush all leftover events (There may be some that arrived after we exited the while event loop, but before we unregistered the events)
    $events = Get-Event | Remove-Event
    "EoleCiTestContext # Exiting"
}

#
# Cas 3 : 2nd fallback !!
#
try
{
    . "D:\EoleCiTestsCommon.ps1"
    doContext
    exit 0
}
Catch
{
    "EoleCiTestContext # Error: $_.Exception.Message"
    "EoleCiTestContext # FailedItem: $_.Exception.ItemName"
    $Error | ForEach-Object { Write-Host $_ }
}
finally
{
    # Flush all leftover events (There may be some that arrived after we exited the while event loop, but before we unregistered the events)
    $events = Get-Event | Remove-Event
    "EoleCiTestContext # Exiting"
}
