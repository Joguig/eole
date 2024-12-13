#!/bin/bash

ciSetHttpProxy

if ciVersionMajeurAPartirDe "2.8."
then
    ciPrintMsgMachine "* Tests exécutés par défaut en Python 3"
    PYTEST="py.test-3 -v"
else
    ciPrintMsgMachine "* Tests exécutés par défaut en Python 2"
    PYTEST="py.test -v"
fi

ciPrintMsgMachine "***********************************************************"
ciPrintMsgMachine "eole-sympa-tests"
ciPrintMsgMachine "***********************************************************"
apt-eole install eole-sympa-tests
ciCheckExitCode $? "install eole-sympa-tests"

cd /usr/share/eole-sympa || exit 1
$PYTEST
RETOUR=$?
echo "eole-sympa => $RETOUR"
[[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR

ciPrintMsgMachine "***********************************************************"
ciPrintMsgMachine "Fin $0 ==> $RETOUR_TEST"
ciPrintMsgMachine "***********************************************************"
exit $RETOUR_TEST
