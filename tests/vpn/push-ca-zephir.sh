#!/bin/bash 

echo "push ca zephir"

cp -vf "$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER/zephir_ca_local.crt" /usr/share/ca-certificates/menesr/zephir_ca_local.crt

