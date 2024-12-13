#!/bin/bash

cd /var/www/html/outils/ecoStations/ || exit 1

echo " ls -l copieFicMachinesDB.pl"
ls -l copieFicMachinesDB.pl

echo " php copieMachinesdb()"
php -r 'include("incAppli/f_ecoStations.inc.php");copieMachinesdb();'

echo " ls config/copie_machines.db"
ls -l config/copie_machines.db

echo " cat config/copie_machines.db"
RESULTAT="0"
while IFS=';' read -r MINIONID IP MAC 
do
    echo "MINIONID=$MINIONID IP=$IP MAC=$MAC"
    if [ "$IP" == "127.0.0.1" ]
    then
        echo "ERREUR : fichier copie_machines.db incorrect (IP)"
        RESULTAT=1
    fi
    if [ "$MAC" == ":::::" ]
    then
        echo "ERREUR : fichier copie_machines.db incorrect (MAC vide)"
        RESULTAT=1
    fi
done <"config/copie_machines.db"
exit "$RESULTAT"