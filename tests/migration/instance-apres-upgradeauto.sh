#!/bin/bash

echo "************************************************************"
VM_VERSIONMAJEUR_CIBLE=$1

RESULTAT="0"

VM_VERSIONMAJEUR=$VM_VERSIONMAJEUR_CIBLE

echo "  VM_VERSIONMAJEUR apres ${VM_VERSIONMAJEUR}"
echo "  VM_MAJAUTO = $VM_MAJAUTO"

echo "******* Check Proxy ***********"
ciSetHttpProxy

echo "************************************************************"
echo "* instance"
echo "************************************************************"
ciMonitor instance
RETOUR=$?
[[ "$RETOUR" -eq 0 ]] || RESULTAT=$RETOUR

exit $RESULTAT
