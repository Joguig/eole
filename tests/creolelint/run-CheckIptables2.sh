#!/bin/bash

#########################################################################################################
#
# Check Iptables <fichierReference>
#
#########################################################################################################
function ciCheckIptables()
{
    ciPrintMsgMachine "check-iptables '$1' "

    TMPFILE=/tmp/iptables.$$
    { iptables -t filter -S; iptables -t nat -S; iptables -t mangle -S; iptables -t raw -S; } >$TMPFILE

    if command -v podman >/dev/null
    then
        # TODO ne fonctionne qu'avec un seul conteneur !
        CNI_UUID="$(podman ps --format json |jq '.[0].Id')"
        CNI_UUID="${CNI_UUID//\"/}"
        echo "CNI_UUID=$CNI_UUID"
        
        NETWORK_DN_UUID=$(grep "N CNI-DN-[0-9af]*" "$TMPFILE" | sed -e "s/-N //")
        echo "NETWORK_DN_UUID=$NETWORK_DN_UUID"
        NETWORK_SANS_DN_UUID=${NETWORK_DN_UUID:7}
        NETWORK_UUID=$(grep "N CNI-${NETWORK_SANS_DN_UUID}" "$TMPFILE" | sed -e "s/-N //")
        echo "NETWORK_UUID=$NETWORK_UUID"
        
        set -x
        sed -i "/-N $NETWORK_UUID/d" "$TMPFILE"
        sed -i "/-N $NETWORK_DN_UUID/d" "$TMPFILE"
        sed -i "/-A $NETWORK_UUID/d" "$TMPFILE"
        sed -i "/-A $NETWORK_DN_UUID/d" "$TMPFILE"
        set +x
        #sed -i "/-N $NETWORK_UUID/d" "$TMPFILE"
    fi
    
    if [ -z "$1" ]
    then
        ciCheckDiffFichierReference "$TMPFILE" CONFIGURATION "iptable"
    else
        REFERENCE_FILE="$1"
        ciCheckDiffFichierReference "$TMPFILE" PATH "$REFERENCE_FILE" "LES REGLES IPTABLES SONT CORRECTES" "LES REGLES IPTABLES SONT INCORRECTES"
    fi
}
export -f ciCheckIptables

if ! command -v jq >/dev/null
then
    apt-get install -y jq
fi
ciGetDirConfiguration
ciCheckIptables "$DIR_CONFIGURATION/iptable1"
# Attention : pas de test ici !

