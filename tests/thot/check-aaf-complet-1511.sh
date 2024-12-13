#!/bin/bash

function search()
{
    echo "$2" | grep "$1"
    if [ $? -ne 0 ]
    then
        echo "Erreur: chaîne \"$1\" non trouvée"
        RES=1
    fi
}

# Vérification des établissements de rattachement (#29088)

PROF=$(ldapsearch -x ENTPersonJointure=AC-DIJON\$3228611)

echo "* Vérification attribut ENTPersonFonctions"
search 'ENTPersonFonctions: 2573\$' "$PROF"
search 'ENTPersonFonctions: 2566\$' "$PROF"
echo

echo "* Vérification attribut ENTAuxEnsClasses"
search 'ENTAuxEnsClasses: cn=s2573,' "$PROF"
search 'ENTAuxEnsClasses: cn=s2566,' "$PROF"
echo

echo "* Vérification attribut ENTAuxEnsMatiereEnseignEtab"
search 'ENTAuxEnsMatiereEnseignEtab: cn=s2566,' "$PROF"
search 'ENTAuxEnsMatiereEnseignEtab: cn=s2566,' "$PROF"
echo

exit $RES
