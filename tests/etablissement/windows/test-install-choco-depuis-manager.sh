#!/bin/bash

MINION_ID=$(salt-key --include-accepted -l acc -q | tail -n 1)
if [ -z "$MINION_ID" ]
then
    echo "Erreur: minionid inconnu !"
    exit 1
fi

echo "minionid=$MINION_ID"

echo "* ================ Choco ======================"
echo "* Extraction Choco list avec Salt depuis le serveur"
salt -t 10 --state-verbose=true "$MINION_ID" cmd.powershell 'choco list' |sort >>"/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/choco.list"
echo "$?"
echo "EOLE_CI_PATH choco.list"

echo "* Test install 'Keypass' avec Salt depuis le serveur"
salt -t 10 --state-verbose=true "$MINION_ID" cmd.powershell 'choco install keepass-classic -y --acceptlicense --no-progress'
echo "$?"

echo "* ================ Winget ======================"
echo "* Winget reset"
salt -t 10 --state-verbose=true "$MINION_ID" cmd.powershell 'winget reset'
echo "$?"

echo "* Winget list"
salt -t 10 --state-verbose=true "$MINION_ID" cmd.powershell 'winget list' |sort >>"/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/winget-list.txt"
echo "$?"
echo "EOLE_CI_PATH winget-list.txt"

echo "* winget install TheDocumentFoundation.LibreOffice"
salt -t 10 --state-verbose=true "$MINION_ID" cmd.powershell 'winget install TheDocumentFoundation.LibreOffice '
echo "$?"
echo "EOLE_CI_PATH choco.list"
