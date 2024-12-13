#!/bin/bash

# shellcheck disable=SC1091,SC1090
. /root/getVMContext.sh NO_DISPLAY

ciClearJournalLogs 1>/dev/null 2>&1

ciSetHttpAndHttpsProxy
export no_proxy=salt

echo "* ping salt"
ciGetNamesInterfaces
ciPingHost salt "$VM_INTERFACE0_NAME"

echo "* getent hosts salt"
getent hosts salt

ciRenamePcLinux

lsb_release -a
DISTRIB="$(lsb_release -sc)"
echo "DISTRIB=$DISTRIB"
case "$DISTRIB" in 
    hirsute|impish|uma|una|jammy|ulyana|ulyssa|vanessa)
        #vanessa Mint 21
        #una     Mint 20.3
        # uma     Mint 20.2
        #Ulyssa  Mint 20.1
        #ulyana  Mint 20.0
        #impish  21 10
        #hirsute 21 04
        #jammy   22 04
        echo "* wget http://salt/joineole/installMinion-Alternate.sh"
        wget -O /tmp/installMinion-Alternate.sh http://salt/joineole/installMinion-Alternate.sh

        echo "* sh /tmp/installMinion-Alternate.sh"
        sh /tmp/installMinion-Alternate.sh
        ;;
    *)
        echo "* wget http://salt/joineole/installMinion.sh"
        wget -O /tmp/installMinion.sh http://salt/joineole/installMinion.sh

        echo "* sh /tmp/installMinion.sh"
        sh /tmp/installMinion.sh
esac


