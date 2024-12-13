
﻿@echo on
C:
CD C:\eole
IF EXIST z:\scripts\windows\EoleCiTestsCommon.ps1 COPY z:\scripts\windows\EoleCiTestsCommon.ps1 c:\eole\EoleCiTestsCommon.ps1
powershell -ExecutionPolicy Unrestricted -file c:\eole\EoleCiTestsCommon.ps1 doInstall