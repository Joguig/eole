#!/bin/bash

# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh

echo "* eole-seth-education"
/bin/cp -vf "/mnt/eole-ci-tests/output/$VM_OWNER/eole-seth-education.password" /etc/eole/private/

echo "* /etc/synchro_aaf.conf"
cat /etc/synchro_aaf.conf
echo "* lancement de synchronize_aaf_directories"
synchronize_aaf_directories --debug
result="$?"
echo "* result=$result"
exit $result
