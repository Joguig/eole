#!/bin/bash
 
RETOUR_TEST=0

ciPrintMsgMachine "Maj-Auto $VM_MAJAUTO"
ciMajAuto
RETOUR=$?
if [[ "$RETOUR" == "0" ]] 
then
    RETOUR_TEST=$RETOUR
fi

ciPrintMsgMachine "***********************************************************"
ciPrintMsgMachine "Test iptables, dpkg et ipset"
ciPrintMsgMachine "***********************************************************"
ciCheckInstance

ciPrintMsgMachine "***********************************************************"
ciPrintMsgMachine "PAQUETS_A_INSTALLER"
ciPrintMsgMachine "***********************************************************"
apt-eole install pyeole-tests creole-tests
ciCheckExitCode $? "install pyeole-tests creole-tests"

if [[ "$VM_MODULE" == "amon" ]] || [[ "$VM_MODULE" == "amonecole" ]] || [[ "$VM_MODULE" == "amonhorus" ]]
then   
    apt-eole install era-tests eole-amon-tests
    ciCheckExitCode $? "install era-tests eole-amon-tests"
fi

if [[ "$VM_MODULE" == "horus" ]] || [[ "$VM_MODULE" == "amonhorus" ]]
then   
    apt-eole install eole-horus-tests
    ciCheckExitCode $? "install eole-horus-tests"
fi

if [[ "$VM_MODULE" == "scribe" ]] || [[ "$VM_MODULE" == "amonecole" ]]
then   
    apt-eole install eole-scribe-tests
    ciCheckExitCode $? "install eole-scribe-tests"
fi

ciPrintMsgMachine "***********************************************************"
echo ""
echo ""
echo ""
echo ""

ciPrintMsgMachine "***********************************************************"
ciPrintMsgMachine "CreoleLint"
ciPrintMsgMachine "***********************************************************"
ciRunPython /usr/bin/CreoleLint
RETOUR=$?
if [[ "$RETOUR" == "0" ]] 
then
    echo "CreoleLint => OK"
else
    RETOUR_TEST=$RETOUR
    echo "CreoleLint => NOK ($RETOUR)"
    bash sauvegarde-fichier.sh diagnose
fi
    
ciPrintMsgMachine "***********************************************************"
ciPrintMsgMachine "pyeole-tests"
ciPrintMsgMachine "***********************************************************"
cd /usr/share/pyeole || exit 2
py.test 
RETOUR=$?
echo "pyeole-tests => $RETOUR"
[[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR 

ciPrintMsgMachine "***********************************************************"
ciPrintMsgMachine "creole-tests"
ciPrintMsgMachine "***********************************************************"
cd /usr/share/creole || exit 2
py.test
RETOUR=$?
echo "creole => $RETOUR"
[[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR 

if [[ "$VM_MODULE" == "amon" ]] || [[ "$VM_MODULE" == "amonecole" ]] || [[ "$VM_MODULE" == "amonhorus" ]]
then   
    ciPrintMsgMachine "***********************************************************"
    ciPrintMsgMachine "eole-amon-tests"
    ciPrintMsgMachine "***********************************************************"
    cd /usr/share/amon || exit 2
    py.test
    RETOUR=$?
    echo "amon => $RETOUR"
    [[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR 
fi
   
if [[ "$VM_MODULE" == "amon" ]] || [[ "$VM_MODULE" == "amonecole" ]] || [[ "$VM_MODULE" == "amonhorus" ]]
then   
    ciPrintMsgMachine "***********************************************************"
    ciPrintMsgMachine "era-tests"
    ciPrintMsgMachine "***********************************************************"
    cd /usr/share/era || exit 2
    py.test
    RETOUR=$?
    echo "era => $RETOUR"
    [[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR 
fi

if [[ "$VM_MODULE" == "horus" ]] || [[ "$VM_MODULE" == "amonhorus" ]]
then   
    ciPrintMsgMachine "***********************************************************"
    ciPrintMsgMachine "eole-horus-tests"
    ciPrintMsgMachine "***********************************************************"
    cd /usr/share/horus || exit 2
    py.test
    RETOUR=$?
    echo "horus => $RETOUR"
    [[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR 
fi

if [[ "$VM_MODULE" == "scribe" ]] || [[ "$VM_MODULE" == "amonecole" ]]
then   
    ciPrintMsgMachine "***********************************************************"
    ciPrintMsgMachine "eole-scribe-tests"
    ciPrintMsgMachine "***********************************************************"
    cd /usr/share/scribe || exit 2
    py.test
    RETOUR=$?
    echo "scribe => $RETOUR"
    [[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR 
fi

ciPrintMsgMachine "***********************************************************"
ciPrintMsgMachine "Fin run-creoletest.sh ==> $RETOUR_TEST"
ciPrintMsgMachine "***********************************************************"
exit $RETOUR_TEST 
