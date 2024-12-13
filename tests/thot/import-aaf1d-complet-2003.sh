#!/bin/bash

# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh

tmpaafdir="/var/tmp/aaf-complet"

SET="AAF1D-BESANCON"
echo "$0 : copie depuis $SET/*.xml (sauf fichiers PersRelEleve)"
rm -rf "$tmpaafdir"
mkdir -p "$tmpaafdir"
for TYPE in "_EtabEducNat_" "_PersEducNat_" "_Eleve_"
do
    cp -v "$VM_DIR_EOLE_CI_TEST/dataset/$SET"/*"$TYPE"*.xml "$tmpaafdir"
done
sed -e 's/\/home\//\/var\/tmp\//' -i /etc/aaf.conf

echo "$0 : /usr/sbin/aaf-complet"
# bash car reconfigure fait un exit !
bash /usr/sbin/aaf-complet
result="$?"
echo "aaf-complet = $result"
ciCheckExitCode "$result"

echo "$0 : cat /var/log/eole/aafexceptions.log"
[ -f /var/log/eole/aafexceptions.log ] && cat /var/log/eole/aafexceptions.log

exit $result
