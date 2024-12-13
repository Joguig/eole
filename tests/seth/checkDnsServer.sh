#!/bin/bash

#set -e
ADMIN_PASSWORD="Eole12345!"
SAMBA4_VARS=/etc/eole/samba4-vars.conf
EXIT_ON_ERROR="${1:-no}"

if [ -f "${SAMBA4_VARS}" ]
then
    . "${SAMBA4_VARS}"
else
    # Template is disabled => samba is disabled
    echo "Samba is disabled"
    exit 0
fi


function checkExitCode()
{
    local EC
    local MSG
    EC="${1}"
    MSG="${2}"
    if [[ "$EC" -eq 0 ]]
    then
        return 0
    fi
    if [ "$EXIT_ON_ERROR" != "no" ]
    then
        echo "Error: '$MSG' exit=$EC, arret demandé"
        bash sauvegarde-fichier.sh maj_auto
        ciCheckExitCode "$EC"
    else
        echo "Warning: '$MSG' exit=$EC, mais je continue...."
    fi
}

function checkTcp
{
    tcpcheck 1 "${1}" |grep -q alive
    checkExitCode "$?" "Accès Port ${1}"
}

function afficheFichier()
{
    echo "==============================================="
    echo "* Cat ${1}"
    if [ -f "${1}" ]
    then
        cat "${1}"
    else
        echo "Attention: ${1} manquant"
    fi
}

if [ "$AD_DNS_BACKEND" != "BIND9_DLZ" ]
then
   echo "la configuration ne demande pas l'utilisation de BIND. Stop"
   exit 0
fi

echo "==============================================="
echo " HOST_IP "
samba-tool dns serverinfo "${AD_HOST_IP}" -P

echo " HOST_IP "
samba-tool dns serverinfo "${AD_ADDITIONAL_IP}" -P
