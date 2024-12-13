@echo off
IF EXIST E:\ModuleEole.yaml GOT :eof

SET VM_IP_EOLECITEST=192.168.0.253
FOR /F "usebackq tokens=1,2 delims==" %%f IN (d:\context.sh) DO CALL :setIp %%f %%g
ECHO "Utilise VM_IP_EOLECITEST=%VM_IP_EOLECITEST%"
NET USE E: /DELETE
rem "C:\Program Files\SSHFS-Win\bin\sshfs-win.exe" svc \sshfs.r\pcadmin=root@%VM_IP_EOLECITEST%\mnt\eole-ci-tests E:
(echo "eole"; echo "eole" ) |"C:\Program Files\SSHFS-Win\bin\sshfs.exe" root@%VM_IP_EOLECITEST%:/mnt/eole-ci-tests E: -p22 -ovolname=eolecitests -odebug -ologlevel=debug1 -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oidmap=user -ouid=-1 -ogid=-1 -oumask=000 -ocreate_umask=000 -omax_readahead=1GB -oallow_other -olarge_read -okernel_cache -ofollow_symlinks -oPreferredAuthentications=password -opassword_stdin
GOTO :eof

:setIp
IF NOT "%1" == "VM_IP_EOLECITEST" GOTO :eof
SET VM_IP_EOLECITEST=%2
SET VM_IP_EOLECITEST=%VM_IP_EOLECITEST:~1,-1%
GOTO :eof
:eof