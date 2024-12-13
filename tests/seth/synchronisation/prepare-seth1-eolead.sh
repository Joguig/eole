#!/bin/bash

MODE="$1"

function doCreateOUEtablissement()
{
    local etab="$1"
    RESULT=$(ldbsearch -H /var/lib/samba/private/sam.ldb "(&(objectclass=organizationalunit)(name=$etab))" | grep dn:)
    if [ -n "$RESULT" ]
    then
        echo "OU $etab existe déjà"
        return
    fi

    cat >/tmp/creatOU.ldif <<EOF
dn: OU=$etab,$BASEDN
changetype: add
objectClass: top
objectClass: organizationalunit

dn: OU=Utilisateurs,OU=$etab,$BASEDN
changetype: add
objectClass: top
objectClass: organizationalunit

dn: OU=Ordinateurs,OU=$etab,$BASEDN
changetype: add
objectClass: top
objectClass: organizationalunit
EOF

    cat /tmp/creatOU.ldif
    ldbmodify -v -H "/var/lib/samba/private/sam.ldb" /tmp/creatOU.ldif
    echo $?
    echo "OU $etab crée"
}


# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh NO_DISPLAY

if [ -f "/etc/eole/samba4-vars.conf" ]
then
    #shellcheck disable=SC1091
    . "/etc/eole/samba4-vars.conf"
else
    # Template is disabled => samba is disabled
    exit 0
fi

BASEDN="DC=${AD_REALM//./,DC=}"
BASEDN3D="DC=${AD_REALM//./,DC%3D}"
echo "BASEDN: $BASEDN"
echo "BASEDN3D: $BASEDN3D"

VM_OUTPUT="$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER"
export VM_OUTPUT

if ciVersionMajeurAPartirDe "2.8."
then
    /bin/cp -f /etc/ssl/certs/ca.crt "$VM_OUTPUT/seth1_ca.pem"
else
    /bin/cp -f /var/lib/samba/private/tls/ca.pem "$VM_OUTPUT/seth1_ca.pem"
fi

for NO in 1 2 3 4 5 6 7 8 9 A B C D E F G H
do
    doCreateOUEtablissement "000000${NO}E"
done

if [ "$MODE" = "restaurationSh" ];then
    ciSignalHack "Test Eole-AD : pré-création du compte 3a.01 pour son mot de passe"
    samba-tool user create "3a.01" "Eole54321!"
fi
