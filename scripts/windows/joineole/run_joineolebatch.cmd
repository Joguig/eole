@echo on
C:
chdir C:\eole
IF NOT EXIST c:\eole\joineole MKDIR c:\eole\joineole

set PATH=c:\python27;%PATH%
:boucle
set PYTHONPATH=c:\python27
XCOPY /S /D \\EOLECITEST\wpkg\binaries\py\*.* c:\eole\download\py

:install0
IF EXIST "c:\Python27\python.exe" GOTO :install1
START /WAIT "Python27" msiexec /i c:\eole\download\py\python-2.7.11.msi ALLUSERS=1 
IF ERRORLEVEL 1 GOTO :erreur 
 
:install1
IF EXIST "c:\wxWidgets" GOTO :install11
START /WAIT "wxWidgets3" c:\eole\download\py\wxWidgets3.0-devel-win32-3.0.2.0.exe /SILENT /NORESTART  /SP- 
IF ERRORLEVEL 1 GOTO :erreur 

:install11
IF EXIST "c:\Python27\Lib\site-packages\wx-3.0-msw" GOTO :install2
START /WAIT "wxPython3" c:\eole\download\py\wxPython3.0-win32-3.0.2.0-py27.exe /SILENT /NORESTART  /SP- 
IF ERRORLEVEL 1 GOTO :erreur 

:install2
IF EXIST "c:\python27\Lib\site-packages\win32com" GOTO :install3
START /WAIT c:\eole\download\py\pywin32-219.win32-py2.7.exe -quiet /SP-
IF ERRORLEVEL 1 GOTO :erreur 

:install3
IF EXIST "c:\python27\Lib\site-packages\wmi.py" GOTO :install4
START /WAIT c:\eole\download\py\WMI-1.4.9.win32.exe -quiet /SP-
IF ERRORLEVEL 1 GOTO :erreur 
 
:install4
COPY \\EOLECITEST\eolecitests\scripts\windows\run_joineolebatch.cmd c:\eole\run_joineolebatch.cmd
XCOPY /Q /Y \\EOLECITEST\eolecitests\scripts\windows\joineole c:\eole\joineole
cd c:\eole\joineole

FOR /F "usebackq delims== tokens=1,2" %%i IN ( D:\context.sh ) DO @SET %%i=%%j
SET NOM=PC%VM_ID:~1,-1%
echo [global]>c:\eole\joineole\%NOM%.cfg
echo admin = admin>>c:\eole\joineole\%NOM%.cfg
echo passwd = ZW9sZQ==>>c:\eole\joineole\%NOM%.cfg
echo hostname = %NOM% >>c:\eole\joineole\%NOM%.cfg

IF %VM_MACHINE%=='etb1.pcadmin' GOTO :zoneadmin1
IF %VM_MACHINE%=='etb1.pceleve' GOTO :zonepedago1
IF %VM_MACHINE%=='etb1.pcprofs' GOTO :zonepedago1
IF %VM_MACHINE%=='etb2.pcadmin' GOTO :zoneadmin2
IF %VM_MACHINE%=='etb2.pceleve' GOTO :zonepedago2
IF %VM_MACHINE%=='etb2.pcprofs' GOTO :zonepedago2
IF %VM_MACHINE%=='etb3.pceleve' GOTO :zonepedago3
IF %VM_MACHINE%=='etb3.pcprofs' GOTO :zonepedago3
SET
PAUSE
GOTO :eof

:zoneadmin1
echo ip = 10.1.1.10>>c:\eole\joineole\%NOM%.cfg
echo domaine = DOMADMIN >>c:\eole\joineole\%NOM%.cfg
echo serveur = HORUS >>c:\eole\joineole\%NOM%.cfg
echo scribe = non >>c:\eole\joineole\%NOM%.cfg
GOTO :doJoinBatch

:zonepedago1
echo ip = 10.1.3.5>>c:\eole\joineole\%NOM%.cfg
echo domaine = DOMPEDAGO >>c:\eole\joineole\%NOM%.cfg
echo serveur = SCRIBE >>c:\eole\joineole\%NOM%.cfg
echo scribe = oui >>c:\eole\joineole\%NOM%.cfg
GOTO :doJoinBatch

:zoneadmin2
echo ip = 10.2.1.10>>c:\eole\joineole\%NOM%.cfg
echo domaine = DOMADMIN >>c:\eole\joineole\%NOM%.cfg
echo serveur = HORUS >>c:\eole\joineole\%NOM%.cfg
echo scribe = non >>c:\eole\joineole\%NOM%.cfg
GOTO :doJoinBatch

:zonepedago2
echo ip = 10.2.3.5>>c:\eole\joineole\%NOM%.cfg
echo domaine = DOMPEDAGO >>c:\eole\joineole\%NOM%.cfg
echo serveur = SCRIBE >>c:\eole\joineole\%NOM%.cfg
echo scribe = oui >>c:\eole\joineole\%NOM%.cfg
GOTO :doJoinBatch

:zonepedago3
echo ip = 10.3.1.2>>c:\eole\joineole\%NOM%.cfg
echo domaine = DOMPEDAGO >>c:\eole\joineole\%NOM%.cfg
echo serveur = SCRIBE >>c:\eole\joineole\%NOM%.cfg
echo scribe = oui >>c:\eole\joineole\%NOM%.cfg
GOTO :doJoinBatch

:doJoinBatch
echo # >>c:\eole\joineole\%NOM%.cfg
type c:\eole\joineole\%NOM%.cfg
c:\python27\python.exe joineolebatch.py --cfg c:\eole\joineole\%NOM%.cfg --installClient --reboot 
echo %ERRORLEVEL%
pause
goto :boucle


:erreur
echo ERRORLEVEL= %ERRORLEVEL%
pause
goto :boucle
