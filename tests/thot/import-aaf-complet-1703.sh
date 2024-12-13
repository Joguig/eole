#!/bin/bash

# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh

echo "$0 : copie depuis aaf-VE1512/complet/*.xml "
rm -rf /var/tmp/aaf-complet
mkdir -p /var/tmp/aaf-complet
cp -v "$VM_DIR_EOLE_CI_TEST"/dataset/AAF-VE1703/complet/*.xml /var/tmp/aaf-complet
sed -e 's/\/home\//\/var\/tmp\//' -i /etc/aaf.conf
#cat >> /etc/aaf.conf << EOF
#dbtype="sqlite"
#aaf_type="samba4"
#dbfilename="/home/eoleaaf.sql"
#EOF
echo "$0 : /usr/sbin/aaf-complet"
# bash car reconfigure fait un exit !
bash /usr/sbin/aaf-complet
result="$?"

echo "run-aaf-complet.sh : cat /var/log/eole/aafexceptions.log"
[ -f /var/log/eole/aafexceptions.log ] && cat /var/log/eole/aafexceptions.log

echo "result=$result"
exit $result
