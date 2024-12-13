REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Diagnostics" /v GPSvcDebugLevel /t REG_DWORD /d 0x00030002 /f

REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\EnableLinkedConnections" /f

REG QUERY "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /s
REG QUERY "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLinkedConnections

mkdir %WINDIR%\debug\usermode
del %WINDIR%\debug\usermode\gpsvc.log
gpupdate /force 

start Notepad %WINDIR%\debug\usermode\gpsvc.log
del c:\eole\gpresult.html
gpresult /H c:\eole\gpresult.html
start c:\eole\gpresult.html
rem firefox http://www.sysprosoft.com/policyreporter.shtml

REG QUERY "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /s
REG QUERY "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLinkedConnections
