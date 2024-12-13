#!/bin/bash

# shellcheck disable=SC1091,SC1090
. /root/getVMContext.sh NO_DISPLAY


if [ "$VM_MACHINE" == "etb3.amonecole" ]
then
   CMD="lxc-attach -n addc -- "
   
   echo "Inject Salt Debug Addc"
   CreoleRun 'mkdir /usr/share/eole/saltstack/salt/eole-workstation/parameters/os/' addc
   CreoleRun '/bin/echo -e "values:\n  salt:\n    minion:\n      log_level: debug" > /usr/share/eole/saltstack/salt/eole-workstation/parameters/os/Windows.yaml' addc
else
   # sur Seth, ScribeAd salt n'est pas dans le conteneur !
   CMD=""
   
   echo "Inject Salt Debug Seth"
   mkdir -p /usr/share/eole/saltstack/salt/eole-workstation/parameters/os/
   /bin/echo -e "values:\n  salt:\n    minion:\n      log_level: debug" > /usr/share/eole/saltstack/salt/eole-workstation/parameters/os/Windows.yaml
fi
${CMD} salt-key

if [ -z "$1" ]
then
    echo "* Recherche MinionID = dernier unaccepted"
    MINION_ID=$(${CMD} salt-key -l unaccepted -q | grep -v "Unaccepted" | tail -n 1)
else
    echo "* Recherche MinionID pour id=$1"
    MINION_ID=$(${CMD} salt-key -l unaccepted -q | grep -v "Unaccepted" | grep "$1" | tail -n 1)
fi

if [ -z "$MINION_ID" ]
then
    echo "Erreur: pas de clef minion unaccepted !"
    exit 1
else
    echo "minionid=$MINION_ID"
    

    echo "* salt-key -a $MINION_ID "
    ${CMD} salt-key -a "$MINION_ID" < <(echo "Y")
    
    echo "* salt-run state.event pretty=True "
    echo "* ======================================================================================"
    # shellcheck disable=SC2086
    ciMonitor ${CMD} salt-run state.event pretty=True &
    
    sleep 5
    
    PID1="$(pgrep -f salt-run)"
    echo "PID1=$PID1"
    
    # l'application de la recette va rebooter la machine. il faut laisser du temps
    sleep 700
    pkill -ABRT salt-run
    
    echo "* ======================================================================================"
    echo "* salt $MINION_ID state.highstate apply (2nd appel tant que https://github.com/saltstack/salt/issues/66592 open"
    if ${CMD} salt -l debug "$MINION_ID" state.highstate apply 2&>1
    then
        echo "* state.highstate apply exit ok"
    else
        echo "* state.highstate apply exit nok, réessai"
        sleep 10
        if ${CMD} salt -l debug "$MINION_ID" state.highstate apply 2&>1
        then
            echo "* state.highstate apply 2 exit ok"
        else
            echo "* test.ping exit nok"
        fi
    fi
    
    echo "* ======================================================================================"
    echo "* salt $MINION_ID test.ping"
    if ${CMD} salt -l debug "$MINION_ID" test.ping >/tmp/testping.out 2>/tmp/testping.err
    then
        echo "* test.ping exit ok"
        cat /tmp/testping.out
    else
        echo "* test.ping exit nok, réessai"
        sleep 10
        if ${CMD} salt -l debug "$MINION_ID" test.ping >/tmp/testping.out 2>/tmp/testping.err
        then
            echo "* test.ping 2 exit ok"
            cat /tmp/testping.out
        else
            echo "* test.ping exit nok"
            cat /tmp/testping.out
            cat /tmp/testping.err
        fi
    fi
    
    echo "* ======================================================================================"
    echo "* salt --out=txt '$MINION_ID' grains.get os"
    MINION_OS=$(${CMD} salt --out=txt "$MINION_ID" grains.get os)
    echo "$MINION_OS"
    
    if [[ "$MINION_OS" == *Windows ]]
    then
        echo "* ======================================================================================"
        echo "* salt '$MINION_ID' cmd.run 'wmic ComputerSystem get PartOfDomain'"
        ${CMD} salt "$MINION_ID" cmd.run 'wmic ComputerSystem get PartOfDomain'
    else
        echo "* pas windows !"
    fi

    echo "* salt-call --local --versions-report"
    ${CMD} salt-call --local --versions-report
fi
