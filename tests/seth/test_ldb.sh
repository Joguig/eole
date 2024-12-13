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

    if [ "$1" == wsad ]
    then
        AD_ADMIN=Administrateur
        ADMIN_PASSWORD=Eole12345!
    fi

    kinit "$AD_ADMIN@${AD_REALM^^}" < <(echo "${ADMIN_PASSWORD}") 1>/dev/null
    RESULTAT="$?"
    if [ "$RESULTAT" -ne 0 ]
    then
        echo "RESULTAT=$RESULTAT"
        exit "$RESULTAT"
    fi
fi

if ciVersionMajeurApres "2.7.1"
then
    OPT_KERBEROS=""
    UTILISE_OPTION_KERBEROSE=non
else
    OPT_KERBEROS=("-k 1")
    UTILISE_OPTION_KERBEROSE=oui
fi


function doLdbsearchNoMessage()
{
    echo "-----"
    if [ "$MODE" = "LOCAL" ]
    then
        CMD="ldbsearch -H /var/lib/samba/private/sam.ldb $*"
        #echo "$CMD"
        ldbsearch -H /var/lib/samba/private/sam.ldb "$@" >/tmp/ldbsearch
        CDU="$?"
    else
        CMD="ldbsearch -H 'ldap://$SAMLDB' ${OPT_KERBEROS[*]} -U$AD_ADMIN@${AD_REALM^^}%${ADMIN_PASSWORD} $*"
        #echo "$CMD"
        
        if [ "${UTILISE_OPTION_KERBEROSE}" == non ]
        then
            ldbsearch -H "ldap://$SAMLDB" -U"$AD_ADMIN@${AD_REALM^^}%${ADMIN_PASSWORD}" "$@" >/tmp/ldbsearch 2>/dev/null
            CDU="$?"
        else
            ldbsearch -H "ldap://$SAMLDB" "${OPT_KERBEROS[@]}" -U"$AD_ADMIN@${AD_REALM^^}%${ADMIN_PASSWORD}" "$@" >/tmp/ldbsearch
            CDU="$?"
        fi
        CDU="$?"
    fi
    if [ "$CDU" -ne 0 ] 
    then
        echo "TEST: $TEST : ERREUR"
        echo "Commande: $CMD"
        cat /tmp/ldbsearch
        RESULTAT="1"
    fi
    return $?
}

function doLdbsearch()
{
    doLdbsearchNoMessage "$@"
    CDU="$?"
    if [ "$CDU" -eq 0 ] 
    then
        echo "TEST: $TEST : OK"
    fi
    return "$CDU"
}

function doLdbsearchWithFiltre()
{
    PATTERN=$1
    shift

    doLdbsearchNoMessage "$@"
    if grep "$PATTERN" /tmp/ldbsearch 
    then
        echo "TEST: $TEST : OK"
    else
        echo "TEST: $TEST : ERREUR"
    fi
}

function doLdbsearchWithCount()
{
    COUNT_MINIMUM=$1
    PATTERN=$2
    shift
    shift

    doLdbsearchNoMessage "$@"
    nentries=$(grep -c "$PATTERN" </tmp/ldbsearch)
    if [ "$nentries" -lt "$COUNT_MINIMUM" ]; then
        echo "TEST: $TEST : ERREUR  (nb obtenu=$nentries, minimum=$COUNT_MINIMUM)"
        RESULTAT="1"
    else
        echo "TEST: $TEST : OK (nb obtenu=$nentries, minimum=$COUNT_MINIMUM)"
    fi
}

TEST="RootDSE"
doLdbsearch --basedn '' -s base
cat /tmp/ldbsearch

TEST="RootDSE"
doLdbsearch --basedn '' -s base DUMMY=x dnsHostName highestCommittedUSN 

TEST="Check rootDSE for Controls"
doLdbsearchWithCount 20 supportedControl -s base -b '' '(objectclass=*)' supportedControl

TEST="Getting defaultNamingContext"
doLdbsearchWithCount 1 defaultNamingContext --basedn='' -s base DUMMY=x defaultNamingContext

BASEDN=$(grep defaultNamingContext /tmp/ldbsearch | awk '{print $2}' )
echo "TEST: Getting defaultNamingContext is : $BASEDN"

TEST="Listing Users"
doLdbsearchWithCount 1 sAMAccountName '(objectclass=user)' sAMAccountName

TEST="Listing Users Sorted"
doLdbsearchWithFiltre sAMAccountName -S '(objectclass=user)' sAMAccountName

TEST="Listing Groups"
doLdbsearchWithCount 1 sAMAccountName '(objectclass=group)' sAMAccountName

TEST="sAMAccountName"
doLdbsearchWithCount 10 sAMAccountName '(|(|(&(!(groupType:1.2.840.113556.1.4.803:=1))(groupType:1.2.840.113556.1.4.803:=2147483648)(groupType:1.2.840.113556.1.4.804:=10))(samAccountType=805306368))(samAccountType=805306369))' sAMAccountName

TEST="Paged Results Control"
doLdbsearchWithCount 1 sAMAccountName  --controls=paged_results:1:5 '(objectclass=user)' sAMAccountName

TEST="Server Sort Control"
doLdbsearchWithCount 1 sAMAccountName --controls=server_sort:1:0:sAMAccountName '(objectclass=user)' sAMAccountName

TEST="Extended DN Control"
doLdbsearchWithCount 1 sAMAccountName --controls=extended_dn:1:0 '(objectclass=user)' sAMAccountName

TEST="Extended Domain scope Control"
doLdbsearchWithCount 1 sAMAccountName --controls=domain_scope:1 '(objectclass=user)' sAMAccountName

TEST="Attribute Scope Query Control"
if [ "$1" == wsad ]
then
    doLdbsearchWithCount 1 sAMAccountName --controls=asq:1:member -s base -b "CN=Administrateurs,CN=Builtin,$BASEDN" sAMAccountName
else
    doLdbsearchWithCount 1 sAMAccountName --controls=asq:1:member -s base -b "CN=Administrators,CN=Builtin,$BASEDN" sAMAccountName
fi 

TEST="Search Options Control"
doLdbsearchWithCount 5 dn --controls=search_options:1:2 '(objectclass=crossRef)' dn

echo "* ls -l /var/lib/samba/private"
ls -l /var/lib/samba/private

if [ -d /var/lib/samba/private/sam.ldb.d/ ]
then
    echo "ls -l /var/lib/samba/private/sam.ldb.d/"
    ls -l /var/lib/samba/private/sam.ldb.d/
fi

if [ "$AD_SERVER_ROLE" == 'controleur de domaine' ]
then
    echo "Liste des utilisateurs"
    samba-tool user list
    
    echo "Liste des groupes"
    samba-tool group list
fi

echo "RESULTAT=$RESULTAT"
exit "$RESULTAT"
