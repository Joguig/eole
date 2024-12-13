#!/bin/bash

GPO_NAME="${1:-eole_script}"

if [ "$(CreoleGet eole_module)" == "scribe" ]
then
    CMD="lxc-attach -n addc -- "
else
    CMD=""
fi

GPOID=$(${CMD} ldbsearch -H /var/lib/samba/private/sam.ldb "(&(objectClass=groupPolicyContainer)(displayname=$GPO_NAME))" cn|grep ^"cn: {"|cut -d " " -f2)
${CMD} ldbsearch -H /var/lib/samba/private/sam.ldb "cn=$GPOID" | python3 "${VM_DIR_EOLE_CI_TEST}/scripts/ldbsearchUnWrap.py"
