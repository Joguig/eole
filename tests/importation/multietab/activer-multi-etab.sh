#!/bin/bash

function doCreateEtab()
{
    local NO
    local RNE
    local ETAB_PREFIX
    
    NO="${1}"
    RNE="$(printf '%07d' "${NO}" )E"
    ETAB_PREFIX="ETB${NO}-"

    if [ "$(CreoleGet ad_local)" == oui ]
    then
        ciRunPython "$VM_DIR_EOLE_CI_TEST/tests/importation/multietab/add_etab.py" "$RNE"
        ciCheckExitCode "$?"
    else
        echo "Seth distant... les etablissements ont été crée par prepare-seth1-eolead.sh"
    fi
    
    if ! grep -q "$RNE" /usr/share/ead2/backend/tmp/importation/etabprefix.csv 2>/dev/null
    then
        echo "$RNE;$ETAB_PREFIX" >>/usr/share/ead2/backend/tmp/importation/etabprefix.csv
        echo "* etabprefix.csv: $RNE / $ETAB_PREFIX ajouté"
    else
        echo "* etabprefix.csv: $RNE / $ETAB_PREFIX existe, (déjà fait ?)"
    fi
}

# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh NO_DISPLAY

if [ -z "$1" ] || [ "$1" == All ]
then
    # par défaut, 2 établisements
    NB=2
else
    NB="$1"
fi

if [ "$NB" -ge 2 ]
then
    ead_support_multietab="$(CreoleGet ead_support_multietab)"
    echo "ead_support_multietab=$ead_support_multietab"
    if [ "$ead_support_multietab" != oui ]
    then
        echo "ERREUR: mode multi établissement n'est pas actif"
        exit 1
    fi
fi

echo "Nb étab à importer = $NB"
for NO in $(seq 1 "$NB")
do
    echo "----------------------------------------------------------"
    echo "* $0: $NO"
    doCreateEtab "$NO"
done

echo "* find /home >/tmp/liste_avant.txt"
find /home >/tmp/liste_avant.txt

echo "* cat /usr/share/ead2/backend/tmp/importation/etabprefix.csv"
ciAfficheContenuFichier /usr/share/ead2/backend/tmp/importation/etabprefix.csv
