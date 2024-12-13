#!/bin/sh -x

echo "Post Install Vm freebsd"
VM_ID=$1
VM_OWNER=$2
OPTIONS=$3

BASE=/mnt/eole-ci-tests

if ! command -v bash
then
    cp "$BASE/scripts/post-install/"*.txz /root
fi
find /root -name "bash*.txz" -print0 | xargs -0 pkg add

if [ ! -f /bin/bash ]
then
    ln -s /usr/local/bin/bash /bin/bash
fi
bash --version

cp "$BASE/scripts/service/mount.eole-ci-tests" /root/mount.eole-ci-tests
chmod 755 /root/mount.eole-ci-tests
chown root /root/mount.eole-ci-tests
chgrp wheel /root/mount.eole-ci-tests

cp "$BASE/scripts/getVMContext.sh" /root/getVMContext.sh
chmod 755 /root/getVMContext.sh
chown root /root/getVMContext.sh
chgrp wheel /root/getVMContext.sh

cp "$BASE/scripts/EoleCiFunctions.sh" /root/EoleCiFunctions.sh
chmod 755 /root/EoleCiFunctions.sh
chown root /root/EoleCiFunctions.sh
chgrp wheel /root/EoleCiFunctions.sh

echo "Install Services "
bash "$BASE/scripts/post-install/CheckUpdateService.sh"

echo "Démarre Services "
service EoleCiTestsDaemon start

if [ "$OPTIONS" = "RESET_PASSWORD" ]
then
    printf "eole\neole" | pw mod user root -h 0
fi

## Finish the post-install and POWEROFF the VM to save it
if [ -n "$VM_ID" ]
then
    if [ -n "$VM_OWNER" ]
    then
        [ ! -d "$BASE/output/$VM_OWNER" ] && mkdir "$BASE/output/$VM_OWNER"
        [ ! -d "$BASE/output/$VM_OWNER/$VM_ID" ] && mkdir "$BASE/output/$VM_OWNER/$VM_ID"
        echo "0" >>"$BASE/output/$VM_OWNER/$VM_ID/postinstall.exit"
        HOSTNAME="$(hostname)"
        export HOSTNAME

        if [ -f "$BASE/output/$VM_OWNER/$VM_ID/.eole-ci-tests.freshinstall" ]
        then
            cp "$BASE/output/$VM_OWNER/$VM_ID/.eole-ci-tests.freshinstall" /root/.eole-ci-tests.freshinstall
            chmod 755 /root/.eole-ci-tests.freshinstall
            chown root /root/.eole-ci-tests.freshinstall
            chgrp wheel /root/.eole-ci-tests.freshinstall
        fi
        env | sort >"$BASE/output/$VM_OWNER/$VM_ID/postinstall.env"
    fi
fi

echo "0" >"$BASE/output/$VM_OWNER/$VM_ID/vnc.exit"
echo "Post Install Vm fini"
