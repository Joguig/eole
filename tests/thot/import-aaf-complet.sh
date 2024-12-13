#!/bin/bash

# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh

echo "run-aaf-complet.sh : untar data"
rm -rf /var/tmp/aaf-complet
rm -rf /var/tmp/anon-complet
rm -rf /var/tmp/anon-complet.tgz
mkdir -p /var/tmp
cp "$VM_DIR_EOLE_CI_TEST/dataset/aaf/anon-complet.tgz" /var/tmp/anon-complet.tgz
tar xvzf /var/tmp/anon-complet.tgz −−directory /var/tmp 
rm -rf /var/tmp/anon-complet.tgz
mv /var/tmp/anon-complet /var/tmp/aaf-complet

sed -e 's/\/home\//\/var\/tmp\//' -i /etc/aaf.conf

echo "run-aaf-complet.sh : /usr/sbin/aaf-complet"
# bash car reconfigure fait un exit !
bash /usr/sbin/aaf-complet
result="$?"

echo "run-aaf-complet.sh : cat /var/log/eole/aafexceptions.log"
[ -f /var/log/eole/aafexceptions.log ] && cat /var/log/eole/aafexceptions.log

echo "result=$result"
exit $result
