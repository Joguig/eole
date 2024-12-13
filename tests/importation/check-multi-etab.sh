#!/bin/bash

ead_support_multietab="$(CreoleGet ead_support_multietab)"
echo "ead_support_multietab=$ead_support_multietab"
if [ "$ead_support_multietab" != oui ]
then
    echo "Le mode multi établissement n'est pas actif avec cette image !"
    exit 1
fi

ciAfficheContenuFichier /usr/share/ead2/backend/tmp/importation/etabprefix.csv

