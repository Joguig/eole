#!/bin/bash

# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh
#echo "* Maj-Auto -D "
#ciMonitor maj_auto_dev
#ciCheckExitCode $?

echo "* install paquet python-eoleaaf + sqlite3"
apt-get install -y python-eoleaaf sqlite3
ciCheckExitCode $?

echo "* reconfigure"
ciMonitor reconfigure
ciCheckExitCode $?

echo "* copie depuis aaf-VE1512/complet/*.xml "
rm -rf /var/tmp/aaf-complet
mkdir -p /var/tmp/aaf-complet
cp -v "$VM_DIR_EOLE_CI_TEST"/dataset/aaf-VE1512/complet/*.xml /var/tmp/aaf-complet
sed -e 's/\/home\//\/var\/tmp\//' -i /etc/aaf.conf
cat >> /etc/aaf.conf << EOF
dbtype="sqlite"
aaf_type="samba4"
dbfilename="/home/eoleaaf.sql"
EOF

echo "* cat /etc/aaf.conf"
cat /etc/aaf.conf

echo "* /usr/sbin/aaf-complet"
# bash car reconfigure fait un exit !
cd /usr || exit 1
bash /usr/sbin/aaf-complet
result="$?"

echo "* cat /var/log/eole/aafexceptions.log"
[ -f /var/log/eole/aafexceptions.log ] && cat /var/log/eole/aafexceptions.log

echo "* result=$result"
exit $result
