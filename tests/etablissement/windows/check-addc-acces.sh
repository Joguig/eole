#!/bin/bash

# shellcheck disable=SC1091,SC1090
. /root/getVMContext.sh NO_DISPLAY
if [ "$VM_ETABLISSEMENT" == etb3 ]
then
    AD_REALM="etb3.lan"
    IP_DC="10.3.2.5"
else
    if [ "$VM_ETABLISSEMENT" == etb1 ]
    then
        AD_REALM="dompedago.etb1.lan"
        IP_DC="10.1.3.11"
    else
        echo "$0: cas non géré"
        exit 0
    fi
fi

ciGetNamesInterfaces

ciWaitTcpPort "${IP_DC}" 445 10

ciPingHost "${IP_DC}" "$VM_INTERFACE0_NAME"

dig @"${IP_DC}" +short -t SRV "_ldap._tcp.dc.$AD_REALM"
CDU="$?"
if [ "$CDU" -ne 0 ]
then
    ciSignalAlerte "Résolution _ldap._tcp.$AD_REALM ... NOK"
else
    echo "* résolution _ldap._tcp.$AD_REALM ... OK"
fi

dig @"${IP_DC}" +short -t SRV "_ldap._tcp.dc._msdcs.$AD_REALM"
CDU="$?"
if [ "$CDU" -ne 0 ]
then
    ciSignalAlerte "Résolution _ldap._tcp.dc._msdcs.$AD_REALM NOK"
else
    echo "* résolution _ldap._tcp.dc._msdcs.$AD_REALM OK"
fi

