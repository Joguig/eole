
﻿@echo on
C:
CD C:\eole
SET SCRIPT=EoleCiTestContext
IF EXIST z:\scripts\windows\EoleCiTestsCommon.ps1 COPY z:\scripts\windows\EoleCiTestsCommon.ps1 c:\eole\EoleCiTestsCommon.ps1
IF EXIST z:\scripts\windows\%SCRIPT%.ps1 COPY z:\scripts\windows\%SCRIPT%.ps1 c:\eole\%SCRIPT%.ps1

rem Impératif, sinon le service de contextulization ne serait pas lancé (car il est System).
rem Le démarrage rapide crée un "snapshot" du démarrage système... avant de démarrer les services réseaux et autres ...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t reg_dword /d 0 /f
powercfg /H OFF

SC stop %SCRIPT%
DEL c:\eole\%SCRIPT%.log
DEL c:\eole\%SCRIPT%.err
SC start %SCRIPT%