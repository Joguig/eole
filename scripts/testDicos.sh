#!/bin/bash 
ZEPHIR=$1
MACHINE=$3
ID=$2
[ -d /tmp/testDicos ] && rm -rf /tmp/testDicos
mkdir /tmp/testDicos
mkdir /tmp/testDicos/zephir
mkdir /tmp/testDicos/machine
ssh-copy-id "root@$MACHINE"
ssh-copy-id "root@$ZEPHIR"
ssh "root@$MACHINE" "cd /mnt/eole-ci-tests/scripts; . getVMContext.sh; ciMonitor maj_auto_rc"
ssh "root@$ZEPHIR" "cd /mnt/eole-ci-tests/scripts; . getVMContext.sh; ciMonitor maj_auto_rc"
scp "root@$ZEPHIR:/var/lib/zephir/modules/$ID/dicos/*.xml" /tmp/testDicos/zephir >/dev/null
scp "root@$MACHINE:/usr/share/eole/creole/dicos/*.xml" /tmp/testDicos/machine >/dev/null

IGNORE=$(grep -c "<variable " /tmp/testDicos/machine/*.xml | grep :0 | cut -d":" -f1)
echo "Dicos sans variables : "
echo "$IGNORE"
rm "$IGNORE"
echo "Dicos différents : "
diff -q /tmp/testDicos/machine /tmp/testDicos/zephir 
