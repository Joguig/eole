#!/bin/bash

RETOUR_TEST=0
ciPrintMsgMachine "ciCheckLogs: Analyse des fichiers de log"

if ciVersionMajeurEgal "2.8.0" && [[ "$VM_MODULE" == "sphynx" ]]
then
    ciSignalWarning "Pas de test des agents Zéphir sur Sphynx 2.8.0"
    exit 0
fi

echo "* agents Zéphir"
agentslog="/var/log/rsyslog/local/zephiragents/zephiragents.info.log"
#sur Zéphir c'est le service "backend" qui gère les agents
[ -f "$agentslog" ] || agentslog="/var/log/rsyslog/local/zephir_backend/zephir_backend.info.log"
if grep -E "(exception during measure|Traceback|RRDtool warning: opening)" "$agentslog"
then
    /bin/cp "$agentslog" "$VM_DIR/agents.log"
    ciSignalAlerte "Exception détectée dans les logs des agents ==> $VM_DIR/agents.log"
    RETOUR_TEST=1
else
    echo "$agentslog : OK"
fi

if [ $RETOUR_TEST -eq 0 ]
then
    ciPrintMsgMachine "ciCheckLogs: OK"
else
    ciPrintMsgMachine "ciCheckLogs: ERREUR"
fi

exit $RETOUR_TEST
