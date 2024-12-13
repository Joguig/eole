#!/bin/bash -x

# shellcheck disable=SC1091
source ./context.sh

if [ ! -d "/tmp/hapy-deploy/${VM_NAME}" ]
then
    mkdir "/tmp/hapy-deploy/${VM_NAME}"
fi
journalctl --no-pager -u one-context-local.service >"/tmp/hapy-deploy/${VM_NAME}/one-context-local.log" 2>&1
journalctl --no-pager -u one-context-online.service >"/tmp/hapy-deploy/${VM_NAME}/one-context-online.log" 2>&1
journalctl --no-pager -u one-context-reconfigure-delayed.service >"/tmp/hapy-deploy/${VM_NAME}/context-reconfigure-delayed.log" 2>&1
ip addr >"/tmp/hapy-deploy/${VM_NAME}/ip-addr.avant.log" 2>&1
cat /etc/resolv.conf >"/tmp/hapy-deploy/${VM_NAME}/resolv.avant.conf" 2>&1
cp /etc/netplan/* "/tmp/hapy-deploy/${VM_NAME}/"
exit 0