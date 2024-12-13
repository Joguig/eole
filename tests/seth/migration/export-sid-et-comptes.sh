#!/bin/bash

# shellcheck disable=SC1091
. /root/getVMContext.sh

ciAccountProfile prof.6a prof.6a 

echo "HACK: systemctl start winbind !!"
systemctl start winbind

VM_OUTPUT=$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER
export VM_OUTPUT

rm -f "$VM_OUTPUT/sid" "$VM_OUTPUT/users" "$VM_OUTPUT/machines"

net getdomainsid >"$VM_OUTPUT/sid"

declare -a SID_ET_NAME
pdbedit -L --smbpasswd-style | while IFS=':' read -ra ACCOUNT_INFOS
do
    # 0=name : 1=uid : 2=lamman-password-hash : 3=nt-password-hash : 4=Account-Flags : 5=Last-Change-Time
    nom="${ACCOUNT_INFOS[0]}"
    pwd="${ACCOUNT_INFOS[3]}"
    SID_ET_NAME=($(wbinfo --name-to-sid "$1"))
    sid="${SID_ET_NAME[0]}"

    if [[ "${ACCOUNT_INFOS[4]}" = "[U"* ]] 
    then
        echo "$nom:$pwd:$sid:" >>"$VM_OUTPUT/users"
    fi
        
    if [[ "${ACCOUNT_INFOS[4]}" = "[W"* ]] 
    then
        echo "$nom:$pwd:$sid:" >>"$VM_OUTPUT/machines"
    fi
    
done 

wc -l "$VM_OUTPUT/sid" "$VM_OUTPUT/users" "$VM_OUTPUT/machines"
