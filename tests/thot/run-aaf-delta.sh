#!/bin/bash

if [ -z "$2" ]
then
   NOM_A_TESTER=DUPONT
else
   NOM_A_TESTER=$2
fi

if [ -z "$3" ]
then
   PRESENT=OUI
else
   PRESENT=$3
fi

cd /home/aaf-delta || exit 1
rm -rf /home/aaf-delta/*
cp -vf "$VM_DIR_EOLE_CI_TEST/dataset/$1"/*.xml .

# bash car reconfigure fait un exit !
bash /usr/sbin/aaf-delta

echo "run-aaf-complet.sh : cat /var/log/eole/aafexceptions.log"
[ -f /var/log/eole/aafexceptions.log ] && cat /var/log/eole/aafexceptions.log

result=$(ldapsearch -x | grep "$NOM_A_TESTER")
echo "RESULTAT LDAP : $result"

if [ "$PRESENT" == OUI ]
then
    if [ -z "$result" ]
    then
        echo "Pas trouve, mais presence attendue"
        echo "TEST EN ERREUR"
        exit 1
    else
        echo "Trouve et presence attendue"
        echo "OK"
        exit 0
    fi
else
    if [ -z "$result" ]
    then
        echo "Pas trouve, et absence attendue"
        echo "OK"
        exit 0
    else
        echo "Trouve, mais absence attendue"
        echo "TEST EN ERREUR"
        exit 1
    fi
fi 
