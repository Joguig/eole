@echo on

IF NOT EXIST c:\Eole @MKDIR c:\eole
IF NOT EXIST c:\Eole\download @mkdir c:\eole\download
COPY /Y z:\scripts\windows\*.* c:\eole

:fin

