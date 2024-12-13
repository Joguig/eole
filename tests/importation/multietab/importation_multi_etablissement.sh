#!/bin/bash

function doImportEtab()
{
    local NO
    local RNE
    local ETAB_PREFIX
    local start_time_etab
    
    NO="${1}"
    RNE="$(printf '%07d' "${NO}" )E"
    ETAB_PREFIX="ETB${NO}-"

    start_time_etab=$(date +%s)

    ciRunPython "$VM_DIR_EOLE_CI_TEST/tests/importation/multietab/add_etab.py" "$RNE"
    ciCheckExitCode "$?"

    if ! grep -q "$RNE" /usr/share/ead2/backend/tmp/importation/etabprefix.csv 2>/dev/null
    then
        echo "$RNE;$ETAB_PREFIX" >>/usr/share/ead2/backend/tmp/importation/etabprefix.csv
        echo "* etabprefix.csv: $RNE / $ETAB_PREFIX ajouté"
    else
        echo "* etabprefix.csv: $RNE / $ETAB_PREFIX existe, (déjà fait ?)"
    fi
    bash "$VM_DIR_EOLE_CI_TEST/tests/importation/multietab/importation_yoyo_eleves_multietab.sh"      "$NO" "annuel"
    echo "$?"
    bash "$VM_DIR_EOLE_CI_TEST/tests/importation/multietab/importation_yoyo_professeurs_multietab.sh" "$NO" "annuel"
    echo "$?"
    
    end_time_etab=$(date +%s)
    # elapsed time with second resolution
    elapsed=$(( end_time_etab - start_time_etab ))
    eval "echo Temps importation Etab : $(date -ud "@$elapsed" +'%H hr %M min %S sec')"
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

start_time_global=$(date +%s)
echo "Nb étab à importer = $NB"
for NO in $(seq 1 "$NB")
do
    echo "----------------------------------------------------------"
    echo "* $0: $NO"
    doImportEtab "$NO"
done

end_time_global=$(date +%s)
# elapsed time with second resolution
elapsed=$(( end_time_global - start_time_global ))
eval "echo Temps importation global : $(date -ud "@$elapsed" +'%H hr %M min %S sec')"


echo "* cat /usr/share/ead2/backend/tmp/importation/etabprefix.csv"
ciAfficheContenuFichier /usr/share/ead2/backend/tmp/importation/etabprefix.csv
