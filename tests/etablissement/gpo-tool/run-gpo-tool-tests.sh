#!/bin/bash

RETOUR_TEST=0

ciPrintMsgMachine "***********************************************************"
ciPrintMsgMachine "MAJ AUTO FORCE"
ciPrintMsgMachine "***********************************************************"
ciMajAutoEtReconfigure
ciCheckExitCode $? "ciMajAutoEtReconfigure"

#if ! command -v gpo-tool
#then
#	ciAptEole eole-gpo-script
#fi

if ciVersionMajeurAvant "2.7.2"
then
    ciPrintMsgMachine "***********************************************************"
    ciPrintMsgMachine "gpo-tool-test.sh all-no-help with_kerberos"
	ciPrintMsgMachine "***********************************************************"
    bash gpo-tool-test.sh --version "$VM_VERSIONMAJEUR"  EXIT_ON_ERROR all-no-help with_kerberos
else
    # a partir de samba 4.11, la connection au partage sysvol/Policies ne fonctionne plus en Kerberos !
    ciPrintMsgMachine "***********************************************************"
    ciPrintMsgMachine "gpo-tool-test.sh all-no-help with_credential"
    ciPrintMsgMachine "***********************************************************"
    bash gpo-tool-test.sh --version "$VM_VERSIONMAJEUR" EXIT_ON_ERROR all-no-help with_credential
fi
RETOUR=$?
echo "gpo-tool-test => $RETOUR"
[[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR

ciPrintMsgMachine "***********************************************************"
ciPrintMsgMachine "Fin run-gpo-too-test.sh ==> $RETOUR_TEST"
ciPrintMsgMachine "***********************************************************"
exit $RETOUR_TEST
