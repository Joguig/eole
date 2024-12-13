#!/bin/bash

ciPrintMsgMachine "ciCheckInstance"

ciPrintMsgMachine "Affiche Memoire"
free -m

if command -v hwe-support-status >/dev/null 2>&1
then
    ciPrintMsgMachine "Test CVE Noyau"
    hwe-support-status
    echo "$?"
else
    ciPrintMsgMachine "Pas de Test CVE Noyau, car pas de commande 'hwe-support-status'"
fi

ciPrintMsgMachine "Affiche Uptime"
uptime

ciPrintMsgMachine "Analyse origine des paquets"
ciGetDirConfiguration
run-check-source-paquet.sh "$VM_DIR_EOLE_CI_TEST/module/$VM_MODULE/origine-$VM_VERSIONMAJEUR"
  
ciPrintConsole "ciCheckInstance: OK"
