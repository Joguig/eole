#!/bin/bash

# shellcheck disable=SC1091,SC1090
. /root/getVMContext.sh NO_DISPLAY

if [ "$VM_MACHINE" == "etb3.amonecole" ]
then
   CMD="lxc-attach -n addc -- "
else
   # sur Seth, ScribeAd salt n'est pas dans le conteneur !
   CMD=""
fi
${CMD} salt-key

MINION_ID_DENIED=$(${CMD} salt-key -l denied -q | grep -v "Denied" | tail -n 1)
if [ -n "$MINION_ID_DENIED" ]
then
    echo "minion_id_denied=$MINION_ID_DENIED"
    echo "ERREUR: clef minion Denied !"
    exit 1
fi

echo "* Recherche MinionID pour id=$1"
MINION_ID=$(${CMD} salt-key -q | grep "$1" | tail -n 1)

if [ -z "$MINION_ID" ]
then
    echo "Erreur: pas de clef minion unaccepted !"
    exit 1
else
    echo "minionid=$MINION_ID"
fi
