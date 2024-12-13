
Set-Location c:\eole

Write-Host "----------------------------------------------------------------------"
Write-Host "wait-idle :"

$lastWriteTimeContextLog = 0
$lastWriteTimeEoleScriptLog = 0
$EoleCiTestServicePresent = $false
$countCheckCpuIdle = 0
$i = 1
# 6/minutes ==> 180 = 30 minutes 
while ( $i -lt 180 )
{
    $i++
    Try
    {
        Start-Sleep -s 10
        
        # Secondes avec les millisecondes 
        Write-Host "$i " 
        
        $ProcessorPercentage = (Get-WmiObject Win32_PerfFormattedData_PerfOS_Processor -filter "Name='_Total'").PercentProcessorTime
        if ( $ProcessorPercentage -gt 10 )
        {
            Write-Output "cpu actif $ProcessorPercentage ($countCheckCpuIdle)"
            $countCheckCpuIdle = $countCheckCpuIdle - 1
        }
        else
        {
            Write-Output "cpu inactif"
            $countCheckCpuIdle = $countCheckCpuIdle + 1
        }
        
        $listU = (Get-WmiObject Win32_Process).commandLine 
        if ( $listProcess )
        {
            $interset = $listU | ?{ $listProcess -notcontains $_ }
            $interset
        }
        $listProcess = $listU
    
        if ( $countCheckCpuIdle -eq 10 )
        {
            Write-Host "pas de process actif, Ok, sortie"
            exit 0
        }
        
        if ( $countCheckCpuIdle -lt 0 )
        {
            $countCheckCpuIdle =  0
        }
    }
    catch
    {
        $_ | Out-Host
        Write-Host "wait-event " $_.Name
    }
}

exit 0
