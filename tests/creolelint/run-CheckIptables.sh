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
        
        # NETWORK_UUID est plus 'long' que NETWORK_DN_UUID !, donc en premier 
        if [ -n "$NETWORK_UUID" ]
        then
            sed -i "/-N $NETWORK_UUID/d" "$TMPFILE"
            sed -i "/-A $NETWORK_UUID/d" "$TMPFILE"
            sed -i "s/$NETWORK_UUID/network_uuid/" "$TMPFILE"
        fi
        if [ -n "$NETWORK_DN_UUID" ]
        then
            sed -i "/-N $NETWORK_DN_UUID/d" "$TMPFILE"
            sed -i "/-A $NETWORK_DN_UUID/d" "$TMPFILE"
            sed -i "s/$NETWORK_DN_UUID/network_dn_uuid/" "$TMPFILE"
        fi
        if [ -n "$CNI_UUID" ]
        then
            sed -i "s/$CNI_UUID/cni_uuid/" "$TMPFILE"
        fi
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
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y jq
fi
ciGetDirConfiguration
ciCheckIptables "$DIR_CONFIGURATION/iptable"
# Attention : pas de test ici !

