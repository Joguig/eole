@echo off
IF EXIST X:\ModuleEole.yaml GOT :eof

SET VM_IP_EOLECITEST=192.168.0.253
FOR /F "usebackq tokens=1,2 delims==" %%f IN (d:\context.sh) DO CALL :setIp %%f %%g
ECHO "Utilise VM_IP_EOLECITEST=%VM_IP_EOLECITEST%"
NET USE X: /DELETE
NET USE X: \\%VM_IP_EOLECITEST%\eolecitests  eole /USER:root /PERSITENT:YES
GOTO :eof

:setIp
IF NOT "%1" == "VM_IP_EOLECITEST" GOTO :eof
SET VM_IP_EOLECITEST=%2
SET VM_IP_EOLECITEST=%VM_IP_EOLECITEST:~1,-1%
GOTO :eof
:eof