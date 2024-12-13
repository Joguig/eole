# WMI query to list all properties and values of the Win32_BIOS class
# This PowerShell script was generated using the WMI Code Generator, Version 1.30
# http://www.robvanderwoude.com/updates/wmigen.html

param( [string]$strComputer = "." )

#$instance = get-ciminstance cim_computersystem
#foreach($property in $instance.psobject.properties.name) {
#                $pUpper = $property.ToUpper()
#                $pLower = $property.ToLower()
#                [string]$pLowerValue = $pinstance.$pLower -join ","
#                [string]$pUpperValue = $pinstance.$pUpper -join ","
#                $pLowerValue | should be $pUpperValue
#}
#$instance.GetCimSessionInstanceId()

$colItems = get-wmiobject -class "Win32_BIOS" -namespace "root\CIMV2" -computername $strComputer
foreach ($objItem in $colItems) {
   write-host "Name                           :" $objItem.Name
   write-host "Version                        :" $objItem.Version
   write-host "Manufacturer                   :" $objItem.Manufacturer
   write-host "SMBIOSBIOS Version             :" $objItem.SMBIOSBIOSVersion
   write-host
}
