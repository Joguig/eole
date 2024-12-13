#!/bin/bash

ID="$1"
if [ -z "$ID" ]
then
    echo "* ID manquant"
    exit 1
fi

# shellcheck disable=SC1091,SC1090
. /root/getVMContext.sh NO_DISPLAY

echo "* Test connexion SSH vers $ID"

REPERTOIRE_MACHINE="$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER/$ID"
if [ ! -d "$REPERTOIRE_MACHINE" ]
then
    echo "ERREUR: Repertoire $REPERTOIRE_MACHINE manquant, le pc ne l'a pas générer. stop !"
    # si on vient ici, c'est que le service executeur EoleCiTestService est en erreur sur le pc.... et qu'il n'a pas crée ce dossier !
    # il est fort probable que le fichier 'ip' n'est pas disponible nom plus.
    # donc on s'arrete !
    exit 1
fi 
IP_PC=$(tr -d '\r\n' <"$REPERTOIRE_MACHINE/ip" )
if [ -z "$IP_PC" ]
then
    echo "ERREUR: fichier $REPERTOIRE_MACHINE/ip ne contient pas l'IP de la machine windows !"
    exit 1
fi
echo "* IP = $IP_PC"

if ! command -v sshpass >/dev/null
then
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y install sshpass 
fi
if ! command -v timeout >/dev/null
then
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y install timeout 
fi

RESULTAT="0"
echo "* test Root"
timeout 60 sshpass -p 'eole' ssh "root@$IP_PC" 'pwd; ls -l'
CDU="$?"
if [ "$CDU" -ne 0 ]
then
    echo "* erreur test connexion SSH Root : $CDU"
    RESULTAT="1"
fi

echo "* test Admin"
timeout 60 sshpass -p 'Eole12345!' ssh "admin@$IP_PC" 'pwd; ls -l'
CDU="$?"
if [ "$CDU" -ne 0 ]
then
    echo "* erreur test connexion SSH admin : $CDU"
    RESULTAT="1"
fi

echo "* test Prof1"
timeout 60 sshpass -p 'Eole12345!' ssh "prof1@$IP_PC" 'pwd; ls -l'
CDU="$?"
if [ "$CDU" -ne 0 ]
then
    echo "* erreur test connexion SSH prof1 : $CDU"
    RESULTAT="1"
fi

echo "* test c31e1"
timeout 60 sshpass -p 'Eole12345!' ssh "c31e1@$IP_PC" 'pwd; ls -l'
CDU="$?"
if [ "$CDU" -ne 0 ]
then
    echo "* erreur test connexion SSH c31e1 : $CDU"
    RESULTAT="1"
fi

echo "RESULTAT=$RESULTAT"
exit "$RESULTAT"
