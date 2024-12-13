#!/bin/bash

NAME="$1"
ID_VM=$(onevm list --csv --no-header -f NAME="$NAME" | awk -F, '{print $1;}')
echo "ID_VM=$ID_VM"

echo "* -----------------------------------------------------------"
echo "* onevm show $ID_VM $NAME"
if ! onevm show "$ID_VM" >"/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/onevm_show_${ID_VM}.log" 2>&1 
then
    echo "ERREUR: $NAME non crée"
else
    echo "OK: $NAME crée"
fi
echo "EOLE_CI_PATH onevm_show_${ID_VM}.log"

if ! virsh dumpxml "one-$ID_VM" >"/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/domain_$ID_VM.xml" 2>&1 
then
    echo "ERREUR: $NAME dump non crée"
else
    echo "OK: $NAME dump crée"
fi
echo "EOLE_CI_PATH domain_$ID_VM.xml"

if ! virsh screenshot "one-$ID_VM" "/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/screen_$ID_VM.ppm" 
then
    echo "ERREUR: $NAME screenshot non crée"
else
    echo "OK: $NAME screenshot crée"
fi
echo "EOLE_CI_PATH screen_$ID_VM.ppm"

echo "* check /var/log/hapy-deploy/$NAME.log"
if [ -f "/var/log/hapy-deploy/$NAME.log" ]
then
    cp -f "/var/log/hapy-deploy/$NAME.log" "/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/$NAME.log"
    echo "EOLE_CI_PATH $NAME.log"
else
    echo "ERREUR: /var/log/hapy-deploy/$NAME.log manque"
fi
if [ -d "/var/log/hapy-deploy/$NAME/" ]
then
    cp -rvf "/var/log/hapy-deploy/$NAME/" "/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/"
else
    echo "ERREUR: /var/log/hapy-deploy/$NAME/ manque"
fi
ciAfficheContenuFichier "/var/log/hapy-deploy/$NAME/resolv.conf"
ciAfficheContenuFichier "/var/log/hapy-deploy/$NAME/50-one-context.yaml"