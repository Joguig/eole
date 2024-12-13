#!/bin/bash

# Tester le retour de la commande getent pour valider l’accès aux comptes du domaine.


function test_accounts() {
    local users
    local groups
    users="$(getent passwd)"
    groups="$(getent group)"

    if [[ "${groups}" =~ ddt101 ]] && [[ "${users}" =~ ddt101 ]]
    then
        return 0
    else
        return 1
    fi
}

echo "* getent passwd"
getent passwd

echo "* getent group"
getent group

test_accounts
res=$?
echo "Le test des utilisateurs est sorti avec un code retour $res"
exit $res
