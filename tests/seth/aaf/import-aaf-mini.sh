#!/bin/bash

# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh

[ -f /var/lib/eole/reports/importaaf.log ] && /bin/rm -f /var/lib/eole/reports/importaaf.log

#lancement de aaf-complet
echo "* zip depuis aaf-mini/complet/*.xml"
cd "$VM_DIR_EOLE_CI_TEST"/dataset/aaf-mini/ || exit 1
rm -f /tmp/complet.zip
zip -r /tmp/complet.zip complet/
result="$?"
cd || exit 1
echo

if [ "$result" = 0 ]; then
    echo "* importation des comptes dans mongdob"
    if ciVersionMajeurAvant "2.7.1"
    then
        salt "*" ead.importaaf_processfile /tmp/complet.zip complète
    else
        salt -c /etc/ead3/salt/ "*" ead.importaaf_processfile /tmp/complet.zip complète
    fi
    result="$?"
    echo "* result importation=$result"
fi

if [ "$result" = 0 ]; then
    echo "* importation des comptes dans l'AD"
    if ciVersionMajeurAvant "2.7.1"
    then
        salt "*" ead.importad_launch
    else
        salt -c /etc/ead3/salt/ "*" ead.importad_launch
    fi
    result="$?"
    echo
fi

echo "* eole-seth-education.password"
/bin/cp -vf /etc/eole/private/eole-seth-education.password "/mnt/eole-ci-tests/output/$VM_OWNER/"

echo "* cat /etc/aaf.conf"
cat /etc/aaf.conf

echo "* cat /var/lib/eole/reports/importaaf.log"
[ -f /var/lib/eole/reports/importaaf.log ] && cat /var/lib/eole/reports/importaaf.log

echo "* result=$result"
exit $result

