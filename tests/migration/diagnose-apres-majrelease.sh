#!/bin/bash

RESULTAT="0"

echo "************************************************************"
echo "Inject eolerc"
echo "************************************************************"
if [[ -f /etc/profile.d/eolerc.sh ]]
then
    # shellcheck disable=SC1091,SC1090
    . /etc/profile.d/eolerc.sh  >/dev/null
    RETOUR=$?
    echo "eolerc.sh => $RETOUR"
else
    echo "PAS DE FICHIER eolerc.sh !!!!"
fi

echo "************************************************************"
echo "Machine $VM_MACHINE : Diagnose"
echo "************************************************************"
ciDiagnose
RETOUR=$?
[[ "$RETOUR" -eq 0 ]] || RESULTAT=$RETOUR

exit $RESULTAT
