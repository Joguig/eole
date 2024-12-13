#!/bin/bash

RETOUR_TEST=0

ciPrintMsgMachine "***********************************************************"
ciPrintMsgMachine "MAJ AUTO FORCE"
ciPrintMsgMachine "***********************************************************"
ciMajAutoSansTest
ciCheckExitCode $? "maj auto"

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

if [[ "$VM_MODULE" == "seth" ]] && ciVersionMajeurApres "2.6.1"
then
    if dpkg -l eole-seth-aaf
    then
        apt-eole install eole-sethaaf-tests
        ciCheckExitCode $? "install eole-sethaaf-tests"
    else
        ciPrintMsgMachine "Le paquet eole-seth-aaf n'est pas installé"
    fi
fi

ciMajAutoEtReconfigure

if ciVersionMajeurAPartirDe "2.8."
then
    ciPrintMsgMachine "* Tests exécutés par défaut en Python 3"
    PYTEST="py.test-3 -v"
else
    ciPrintMsgMachine "* Tests exécutés par défaut en Python 2"
    PYTEST="py.test -v"
fi

ciPrintMsgMachine "***********************************************************"
ciPrintMsgMachine "pyeole-tests"
ciPrintMsgMachine "***********************************************************"
cd /usr/share/pyeole || exit 2
$PYTEST
RETOUR=$?
echo "pyeole-tests => $RETOUR"
[[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR

ciPrintMsgMachine "***********************************************************"
ciPrintMsgMachine "creole-tests"
ciPrintMsgMachine "***********************************************************"
cd /usr/share/creole/tests || exit 2
$PYTEST
RETOUR=$?
echo "creole => $RETOUR"
[[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR

if [[ "$VM_MODULE" == "amon" ]] || [[ "$VM_MODULE" == "amonecole" ]] || [[ "$VM_MODULE" == "amonhorus" ]]
then
    ciPrintMsgMachine "***********************************************************"
    ciPrintMsgMachine "eole-amon-tests"
    ciPrintMsgMachine "***********************************************************"
    cd /usr/share/amon || exit 2
    $PYTEST
    RETOUR=$?
    echo "amon => $RETOUR"
    [[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR
fi

if [[ "$VM_MODULE" == "amon" ]] || [[ "$VM_MODULE" == "amonecole" ]] || [[ "$VM_MODULE" == "amonhorus" ]]
then
    if ciVersionMajeurAPartirDe "2.8." && ciVersionMajeurAvant "2.9.0"
    then
        ciPrintMsgMachine "***********************************************************"
        ciPrintMsgMachine "era-tests (python2)"
        ciPrintMsgMachine "***********************************************************"
        cd /usr/share/era/tests || exit 2
        py.test -v
        RETOUR=$?
        echo "era (python2) => $RETOUR"
        [[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR
    fi
    ciPrintMsgMachine "***********************************************************"
    ciPrintMsgMachine "era-tests"
    ciPrintMsgMachine "***********************************************************"
    cd /usr/share/era/tests || exit 2
    $PYTEST
    RETOUR=$?
    echo "era => $RETOUR"
    [[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR
fi

if [[ "$VM_MODULE" == "horus" ]] || [[ "$VM_MODULE" == "amonhorus" ]]
then
    ciPrintMsgMachine "***********************************************************"
    ciPrintMsgMachine "eole-horus-tests"
    ciPrintMsgMachine "***********************************************************"
    if ciVersionMajeurApres "2.7.0"
    then
        ciSignalHack "Pause de 30 secondes dans ad_password de backend.py"
        cp /usr/lib/python2.7/dist-packages/horus/backend.py /tmp/backend.py
        sed -i -e 's/sleep(2)/sleep(30)/' /usr/lib/python2.7/dist-packages/horus/backend.py
        diff /usr/lib/python2.7/dist-packages/horus/backend.py /tmp/backend.py

        # debug
        cp -u /mnt/eole-ci-tests/tests/creolelint/logback.xml /etc/lsc

#        echo "stop eole-lsc.service"
#        systemctl stop eole-lsc.service
#
#        echo "start eole-lsc.service"
#        systemctl start eole-lsc.service
#
        echo "status eole-lsc.service"
        systemctl status  eole-lsc.service --no-pager

        if [[ "$VM_DEBUG" -ge "1" ]]
        then
            journalctl -f --no-pager &
            tail -f /var/log/lsc/lsc.ldif &
            tail -f /var/log/lsc/lsc.log &
        fi
    fi
    cd /usr/share/horus || exit 2
    py.test -v
    RETOUR=$?
    echo "horus => $RETOUR"
    [[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR

    if ciVersionMajeurApres "2.7.0"
    then
        pkill -9 journalctl >/dev/null 2>&1
        pkill -9 tail >/dev/null 2>&1
    fi
fi

if [[ "$VM_MODULE" == "scribe" ]] || [[ "$VM_MODULE" == "amonecole" ]]
then
    if ciVersionMajeurApres "2.7.1"
    then
        ciPrintMsgMachine "***********************************************************"
        ciPrintMsgMachine "* Test du script /usr/share/eole/backend/droits_user.py"
        ciPrintMsgMachine "***********************************************************"
        cd "$(dirname "$0")" || exit 2
        ./run-Checkdroits_user.sh
    fi
    ciPrintMsgMachine "***********************************************************"
    ciPrintMsgMachine "eole-scribe-tests"
    ciPrintMsgMachine "***********************************************************"
    if ciVersionMajeurApres "2.7.0"
    then
        if ciVersionMajeurAPartirDe "2.8."
        then
            PYVERS="3"
        else
            PYVERS="2.7"
        fi
        ciSignalHack "Pause de 30 secondes dans ad_password de eoleuser.py"
        cp "/usr/lib/python${PYVERS}/dist-packages/scribe/eoleuser.py" /tmp/eoleuser.py
        sed -i -e 's/sleep(2)/sleep(30)/' "/usr/lib/python${PYVERS}/dist-packages/scribe/eoleuser.py"
        diff "/usr/lib/python${PYVERS}/dist-packages/scribe/eoleuser.py" /tmp/eoleuser.py
        ciSignalHack "Pause de 30 secondes dans eoleshare.py"
        cp "/usr/lib/python${PYVERS}/dist-packages/scribe/eoleshare.py" /tmp/eoleshare.py
        sed -i -e 's/sleep(2)/sleep(30)/' "/usr/lib/python${PYVERS}/dist-packages/scribe/eoleshare.py"
        diff "/usr/lib/python${PYVERS}/dist-packages/scribe/eoleshare.py" /tmp/eoleshare.py

        # debug
        cp -u /mnt/eole-ci-tests/tests/creolelint/logback.xml /etc/lsc

#        echo "stop eole-lsc.service"
#        systemctl stop eole-lsc.service
#
#        echo "start eole-lsc.service"
#        systemctl start eole-lsc.service
#
        echo "status eole-lsc.service"
        systemctl status  eole-lsc.service --no-pager

        if [[ "$VM_DEBUG" -ge "1" ]]
        then
            journalctl -f  --no-pager &
            tail -f /var/log/lsc/lsc.ldif &
            tail -f /var/log/lsc/lsc.log &
        fi
    fi
    cd /usr/share/scribe || exit 2
    $PYTEST
    RETOUR=$?
    echo "scribe => $RETOUR"
    [[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR

    if ciVersionMajeurApres "2.7.0"
    then
        pkill -9 journalctl >/dev/null 2>&1
        pkill -9 tail >/dev/null 2>&1
    fi

fi

if [[ "$VM_MODULE" == "seth" ]] && ciVersionMajeurApres "2.6.1"
then
    if dpkg -l eole-sethaaf-tests
    then
        if ciVersionMajeurApres "2.7.1"
        then
            SETHPYTEST="py.test-3 -v"
        else
            SETHPYTEST="py.test -v"
        fi
        ciPrintMsgMachine "***********************************************************"
        ciPrintMsgMachine "eole-sethaaf-tests"
        ciPrintMsgMachine "***********************************************************"
        cd /usr/share/sethaaf || exit 2
        $SETHPYTEST
        RETOUR=$?
        echo "sethaaf => $RETOUR"
        [[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR
    else
        ciPrintMsgMachine "Le paquet eole-seth-aaf n'est pas installé"
    fi
fi

if [[ "$VM_MODULE" == "hapy" ]] && ciVersionMajeurApres "2.7.1"
then
    ciPrintMsgMachine "***********************************************************"
    ciPrintMsgMachine "accès à l'API OneFlow"
    ciPrintMsgMachine "***********************************************************"
    CreoleGet --list | grep oneflow
    curl -s -u eoleone:eole https://hapy.ac-test.fr/oneflow/service_template | grep -C3 "DOCUMENT_POOL"
    RETOUR=$?
    echo "OneFlow => $RETOUR"
    [[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR
fi

ciPrintMsgMachine "***********************************************************"
ciPrintMsgMachine "Fin run-module-test.sh ==> $RETOUR_TEST"
ciPrintMsgMachine "***********************************************************"
exit $RETOUR_TEST
