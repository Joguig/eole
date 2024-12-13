@echo on
REM https://www.catalog.update.microsoft.com/Search.aspx?q=KB4458469
REM https://www.catalog.update.microsoft.com/Search.aspx?q=KB4457136
C:
CD C:\eole
call C:\eole\update_scripts_eole.cmd
DEL C:\eole\joineole
MKDIR C:\eole\joineole

NET USE X: \\SCRIBE\admin /USER:admin eole /PERSISTENT:NO
COPY X:\perso\integrDom C:\eole\joineole
NET USE X: /DELETE

CD C:\eole\joineole
echo passwd = ZW9sZQ== >>joineole.cfg
echo veille = True >>joineole.cfg
echo showext = True >>joineole.cfg
C:\eole\joineole\joineole.exe
