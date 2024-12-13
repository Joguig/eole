#!/bin/bash

cp /mnt/eole-ci-tests/scripts/hook_dynlogon /root/hook_dynlogon
chmod 777 /root/hook_dynlogon

grep "hook_dynlogon" /etc/samba/smb.conf
if [ $? -eq 1 ]
then
	echo "installation"
	[ ! -f /etc/samba/smb.conf.old ] && cp /etc/samba/smb.conf /etc/samba/smb.conf.old
	sed -i '16i      root preexec = /root/hook_dynlogon ROOT_PREEXEC "%U" "%a" "%m" "%I" "%d" "%T" "%u" "%M" "%R" "%H"' /etc/samba/smb.conf
	sed -i '16i      root postexec = /root/hook_dynlogon ROOT_POSTEXEC "%U" "%a" "%m" "%I" "%d" "%T" "%u" "%M" "%R" "%H"'  /etc/samba/smb.conf
else
	echo "déja installé"
fi
service smbd restart
service nmbd restart
tail -f /tmp/dyn-logon