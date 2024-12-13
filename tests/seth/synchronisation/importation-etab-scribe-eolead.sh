#!/bin/bash

function doImportEtab()
{
    local RNE
    local ETAB
    
    RNE="000000$1E"
    ETAB="ETB$1"

    ciRunPython "$VM_DIR_EOLE_CI_TEST/tests/importation/add_etab.py" "$RNE"
    ciCheckExitCode "$?"

    if ! grep -q "$RNE" /usr/share/ead2/backend/tmp/importation/etabprefix.csv
    then
        echo "$RNE;$ETAB" >>/usr/share/ead2/backend/tmp/importation/etabprefix.csv
    fi

    bash "$VM_DIR_EOLE_CI_TEST/tests/importation/importation_yoyo_eleves_multietab.sh"      "$RNE" "$ETAB"
    bash "$VM_DIR_EOLE_CI_TEST/tests/importation/importation_yoyo_professeurs_multietab.sh" "$RNE" "$ETAB"
}

function importAll()
{
    for NO in 1 2 3 4 5 6 7 8 9 A B C D E F G H 
    do
        doImportEtab "$NO"
    done

}

# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh NO_DISPLAY
if [ -z "$1" ]
then
    importAll
else
    doImportEtab "$1"
fi

echo "* cat /usr/share/ead2/backend/tmp/importation/etabprefix.csv"
ciAfficheContenuFichier /usr/share/ead2/backend/tmp/importation/etabprefix.csv
