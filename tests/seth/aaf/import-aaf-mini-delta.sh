#!/bin/bash

# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh

ZIP_FILE="/tmp/delta.zip"

#lancement de aaf-delta
echo "* zip depuis aaf-mini/delta/*.xml"
# shellcheck disable=SC2164 
cd "$VM_DIR_EOLE_CI_TEST"/dataset/aaf-mini-delta/
rm -f "$ZIP_FILE"
zip -r "$ZIP_FILE" delta/
result="$?"
# shellcheck disable=SC2103,SC2164
cd -
echo

if [ "$result" = 0 ]; then
    echo "* importation des comptes dans mongdob -- delta"
    salt -c /etc/ead3/salt/ "*" ead.importaaf_processfile "$ZIP_FILE" delta
    result="$?"
    echo
fi

#if [ "$result" = 0 ]; then
#    echo "* importation des comptes dans l'AD"
#    salt -c /etc/ead3/salt/ "*" ead.importad_launch
#    result="$?"
#    echo
#fi

echo "* cat /etc/aaf.conf"
cat /etc/aaf.conf

echo "* cat /var/lib/eole/reports/importaaf.log"
[ -f /var/lib/eole/reports/importaaf.log ] && cat /var/lib/eole/reports/importaaf.log

echo "* result=$result"
exit $result

