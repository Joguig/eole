@echo on
IF EXIST G:\ModuleEole.yaml GOT :eof

Winget install WinFsp.WinFsp --accept-package-agreements --accept-source-agreements
Winget install SSHFS-Win --accept-package-agreements --accept-source-agreements

NET USE G: /DELETE
NET USE G: \\sshfs.r\root@192.168.253.1\mnt  eole /USER:root 
