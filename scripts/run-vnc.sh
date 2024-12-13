#!/bin/bash
#########################################
# arg 1 = commande
# arg 2 = step number dans repertoire DONE
#########################################

#########################################
# attention : lancé de puis /root !
cd /mnt/eole-ci-tests/scripts || exit 1
#########################################

[[ /mnt/eole-ci-tests/scripts/EoleCiFunctions.sh -nt /root/EoleCiFunctions.sh ]] && /bin/cp /mnt/eole-ci-tests/scripts/EoleCiFunctions.sh /root/EoleCiFunctions.sh
# shellcheck disable=SC1091,SC1090
. /root/EoleCiFunctions.sh
ciGetContext

[ ! -d "/mnt/eole-ci-tests/output/$VM_ID"      ] && mkdir "/mnt/eole-ci-tests/output/$VM_ID/"
[ ! -d "/mnt/eole-ci-tests/output/$VM_ID/DONE" ] && mkdir "/mnt/eole-ci-tests/output/$VM_ID/DONE"

VNC_LOG="/mnt/eole-ci-tests/output/$VM_ID/DONE/$2.log"
VNC_EXIT="/mnt/eole-ci-tests/output/$VM_ID/DONE/$2.exit"
RETVAL="-1"
case $1 in
    update-daily)
        ./update-daily.sh >"$VNC_LOG" 2>&1
        RETVAL="$?"
        ;;
    *)
        RETVAL="1"
        ;;
esac
echo "$RETVAL" >"$VNC_EXIT"