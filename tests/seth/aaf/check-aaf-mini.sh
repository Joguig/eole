#!/bin/bash

RESULTAT="0"
ADMIN_PASSWORD="Eole12345!"

# shellcheck disable=SC1091
source /etc/eole/samba4-vars.conf

if [ -z "$1" ]
then
    MODE=LOCAL
else
    SAMLDB="$1.${AD_REALM}"
    MODE=DISTANT

    kinit "$AD_ADMIN@${AD_REALM^^}" < <(echo "${ADMIN_PASSWORD}")
    RESULTAT="$?"
    if [ "$RESULTAT" -ne 0 ]
    then
        echo "RESULTAT=$RESULTAT"
        exit "$RESULTAT"
    fi
fi

function doLdbsearch()
{
    local REQUETE="$1"
    /bin/rm -f /tmp/ldbsearch
    if [ "$MODE" = "LOCAL" ]
    then
        CMD="ldbsearch -H /var/lib/samba/private/sam.ldb $REQUETE --controls=search_options:0:1 sAMAccountName"
        ldbsearch -H /var/lib/samba/private/sam.ldb "$REQUETE" --controls=search_options:0:1 sAMAccountName >/tmp/ldbsearch
        result="$?"
    else
        CMD="ldbsearch -H "ldap://$SAMLDB" -k yes $REQUETE --controls=search_options:0:1 sAMAccountName"
        ldbsearch -H "ldap://$SAMLDB" -k yes "$REQUETE" --controls=search_options:0:1 sAMAccountName >/tmp/ldbsearch
        result="$?"
    fi
    if [ "$result" -ne 0 ]
    then
        echo "TEST: $TEST : Commande ERREUR"
        echo "Commande: $CMD"
        cat /tmp/ldbsearch
        RESULTAT="1"
    else
        echo "TEST: $TEST : Commande OK"
    fi
    return $?
}

function doLdbsearchWithCount()
{
    local NB="$1"
    local REQUETE="$2"
    doLdbsearch "$REQUETE"
    nentries=$(grep -c sAMAccountName </tmp/ldbsearch)
    if [ "$nentries" != "$NB" ]; then
        echo "TEST: $TEST : Comptage ERREUR  (nb obtenu=$nentries, attendu=$NB)"
        RESULTAT="1"
    else
        echo "TEST: $TEST : Comptage OK (nb obtenu=$nentries, attendu=$NB)"
    fi
}
function doGetEnt()
{
    if [ "$MODE" = "DISTANT" ]; then
        local TYPE="$1"
        local NAME="$2"
        echo "getent $TYPE $NAME"
        getent "$TYPE" "$NAME"
        result="$?"
        if [ "$result" != "0" ]; then
            echo "$TYPE $NAME non présent localement"
            RESULTAT="1"
        fi
	    echo
    fi
}

echo "=========================================="
echo "* testparm"
testparm -sv | grep winbind

echo "=========================================="
echo "* user list AD "
if [ "$MODE" = "DISTANT" ]
then
    samba-tool user list -H ldap://dc1
else
    samba-tool user list
fi

echo "=========================================="
echo "* group list AD "
if [ "$MODE" = "DISTANT" ]
then
    samba-tool group list -H ldap://dc1
else
    samba-tool group list
fi

USER="ghislaine.delmare"
echo "=========================================="
echo "* utilisateur $USER"
REQUETE="(&(objectclass=user)(cn=$USER))"
if [ "$MODE" = "LOCAL" ]
then
    ldbsearch -H /var/lib/samba/private/sam.ldb $REQUETE --controls=search_options:0:1
else
    ldbsearch -H "ldap://$SAMLDB" -k yes $REQUETE --controls=search_options:0:1
fi

# sans compte de machine qui sont des utilisateurs
# sans compte de service DNS
TEST="User (real accounts)"
doLdbsearchWithCount 15 '(&(objectclass=user)(!(CN=dns-*))(!(CN=gpo-*))(!(objectClass=computer)))'

USER="albertine.delacourt02"
TEST="User $USER"
doLdbsearchWithCount 1 "(&(objectclass=user)(cn=$USER))"
doGetEnt passwd "$USER"

USER="albertine.delacourt03"
TEST="User $USER"
doLdbsearchWithCount 1 "(&(objectclass=user)(cn=$USER))"
doGetEnt passwd "$USER"

GRP="professeurs"
TEST="Groups $GRP"
doLdbsearchWithCount 1 "(&(objectclass=group)(cn=$GRP))"
doGetEnt group "$GRP"

GRP="administratifs"
TEST="Groups $GRP"
doLdbsearchWithCount 1 "(&(objectclass=group)(cn=$GRP))"
doGetEnt group "$GRP"

GRP="eleves"
TEST="Groups $GRP"
doLdbsearchWithCount 1 "(&(objectclass=group)(cn=$GRP))"
doGetEnt group "$GRP"

GRP="etb1_professeurs"
TEST="Groups $GRP"
doLdbsearchWithCount 1 "(&(objectclass=group)(cn=$GRP))"
doGetEnt group "$GRP"

GRP="etb1_administratifs"
TEST="Groups $GRP"
doLdbsearchWithCount 1 "(&(objectclass=group)(cn=$GRP))"
doGetEnt group "$GRP"

GRP="etb1_eleves"
TEST="Groups $GRP"
doLdbsearchWithCount 1 "(&(objectclass=group)(cn=$GRP))"
doGetEnt group "$GRP"

GRP="etb1_t_stl"
TEST="Groups '$GRP'"
doLdbsearchWithCount 1 "(&(objectclass=group)(cn=$GRP))"
doGetEnt group "$GRP"

GRP="etb1"
TEST="Groups '$GRP'"
doLdbsearchWithCount 1 "(&(objectclass=group)(cn=$GRP))"
doGetEnt group "$GRP"

#TEST="Groups *"
#doLdbsearchWithCount 41 '(&(objectclass=group)(cn=*))'

echo "RESULTAT=$RESULTAT"
exit "$RESULTAT"
