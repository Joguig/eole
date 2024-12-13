#!/bin/bash

ip route >/tmp/iproute.txt
ciAfficheContenuFichier /tmp/iproute.txt

ciPrintMsgMachine "***********************************************************"
ciMonitor reconfigure
ciCheckExitCode $? "reconfigure"

ciPrintMsgMachine "***********************************************************"
ciGetDirConfiguration
ciCheckDiffFichierReference /tmp/iproute.txt PATH "$DIR_CONFIGURATION/iproute" "ip route OK" "ip route différentes!" OUI

ciPrintMsgMachine "***********************************************************"
ciMonitor diagnose
ciCheckExitCode $? "diagnose"

ciPrintMsgMachine "***********************************************************"
echo "Espace occupé par les systèmes de fichiers"
df -h
