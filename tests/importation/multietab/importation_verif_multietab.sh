#!/bin/bash
USER="prenom.prof10"
ETAB_PREFIX="ETB1"
LETAB="0000001e"
Prof=$(id -Gn $USER | sed "s/ /\n/g" | sort)
echo "***************** Groupes de $USER *****************"
echo "$Prof"
echo "**********************************************************"
if ciVersionMajeurEgal "2.7.1"
then
    USERS="domain users"
else
    USERS="domain users BUILTIN\users"
fi
if ciVersionMajeurAvant "2.7.2"
then
    ProfAttendu=$(echo "${USERS} ${USER} ${LETAB} profs-${LETAB} professeurs" | sed "s/ /\n/g" | sort)
else
    ProfAttendu=$(echo "${USERS} ${USER} ${LETAB} profs-${LETAB} profs-${ETAB_PREFIX,,}c41 profs-${ETAB_PREFIX,,}opt1 profs-${ETAB_PREFIX,,}opt2 professeurs" | sed "s/ /\n/g" | sort)
fi

if [ "$Prof" != "$ProfAttendu" ]
then
    echo "Prof='$Prof' != '$ProfAttendu'"
    echo "ERREUR : l'utilisateur n'appartient pas aux bons groupes"
    exit 1
else
    echo "La liste des groupes de l'utilisateur $USER est correcte"
fi
exit 0
