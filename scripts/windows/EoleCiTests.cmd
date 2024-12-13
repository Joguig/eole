
﻿@echo on

set VM_ID=%1
set VM_OWNER=%2
set VM_STEP=%3
IF %VM_ID%.==. GOTO :erreur
IF %VM_OWNER%.==. GOTO :erreur

SET VM_DIR=z:\output\%VM_OWNER%\%VM_ID%
IF NOT EXIST %VM_DIR% @MKDIR %VM_DIR%

SET VM_DONE=%VM_DIR%\DONE
IF NOT EXIST %VM_DONE% @MKDIR %VM_DONE%

IF %VM_STEP%.==.     SET OUTPUT_FILE=%VM_DIR%\windowsInstall
IF NOT %VM_STEP%.==. SET OUTPUT_FILE=%VM_DONE%\%VM_STEP%

IF EXIST %VM_DIR%\postinstall.env DEL %VM_DIR%\postinstall.env
IF EXIST %OUTPUT_FILE%.log DEL %OUTPUT_FILE%.log

IF NOT EXIST c:\Eole @MKDIR c:\eole
IF NOT EXIST c:\Eole\download @mkdir c:\eole\download
COPY /Y z:\scripts\windows\*.* c:\eole

wmic os get /value >%VM_DIR%\wmic_os.txt

SET ISW2012=non
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
ECHO %version%

:set_security
REM pas de test apres, c'est uniquement pour W2012R2 !
IF NOT %version%.==6.3. GOTO :install
NET USER pcadmin Eole12345! /ADD

:install
NET USER pcadmin eole /ADD

COPY z:\scripts\windows\EoleCiTestsCommon.ps1 c:\eole\EoleCiTestsCommon.ps1
COPY z:\scripts\windows\EoleCiTestContext.ps1 c:\eole\EoleCiTestContext.ps1
COPY z:\scripts\windows\EoleCiTestService.ps1 c:\eole\EoleCiTestService.ps1

SET COMPTE=pcadmin
SET PASS=eole

IF %USERNAME%.==Administrateur. SET COMPTE=Administrateur
IF %USERNAME%.==Administrateur. SET PASS=Eole123456
powershell -ExecutionPolicy Unrestricted -file c:\eole\AddAccountToLogonAsService.ps1 -accountToAdd %COMPTE%
IF ERRORLEVEL 1 GOTO :erreur

powershell -ExecutionPolicy Unrestricted -file c:\eole\EoleCiTestsCommon.ps1 doInstall
IF ERRORLEVEL 1 GOTO :erreur
set RESULT=0
goto :sortie

:erreur
set RESULT=%ERRORLEVEL%
echo "ERREUR %RESULT%!"
goto :sortie

:sortie
echo %RESULT% >%OUTPUT_FILE%.exit
echo %RESULT% >%VM_DIR%\vnc.exit
set >%VM_DIR%\postinstall.env
exit /B %%RESULT%%
