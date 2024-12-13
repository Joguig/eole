
﻿@echo on
C:
CD C:\eole
SET SCRIPT=EoleCiTestService
IF EXIST z:\scripts\windows\EoleCiTestsCommon.ps1 COPY z:\scripts\windows\EoleCiTestsCommon.ps1 c:\eole\EoleCiTestsCommon.ps1
IF EXIST z:\scripts\windows\%SCRIPT%.ps1          COPY z:\scripts\windows\%SCRIPT%.ps1 c:\eole\%SCRIPT%.ps1

SC stop %SCRIPT%
DEL c:\eole\%SCRIPT%.log
DEL c:\eole\%SCRIPT%.err
SC start %SCRIPT%