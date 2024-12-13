#!/bin/bash

# shellcheck disable=SC1091
. /root/getVMContext.sh

# shellcheck disable=SC1091
. /usr/lib/eole/ihm.sh

# shellcheck disable=SC1091
. /usr/lib/eole/samba4.sh

echo "Phase 1 : copie config eol"
CONFIGURATION=dompedago
export CONFIGURATION
ciCopieConfigEol

echo "Phase 2 : récupération et inject SID"
VM_INPUT=$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER
export VM_INPUT

# SID for domain DOMPEDAGO is: S-1-5-21-1684926602-3633166837-2462499755
SID=$(cut -d: -f2 <"$VM_INPUT/sid"| tr -d '[:space:]')
DOMAIN_SID="$(CreoleGet ad_domain_sid)"
echo "$SID $DOMAIN_SID"
if [ "$DOMAIN_SID" != "$SID" ]
then
    CreoleSet ad_domain_sid "$SID"
fi

echo "Phase 3 : instance"
if [ ! -f "/var/lib/samba/.instance_ok" ]
then
    ciInstance
fi

if [ -f "/etc/eole/samba4-vars.conf" ]
then
    #shellcheck disable=SC1091
    . "/etc/eole/samba4-vars.conf"
else
    # Template is disabled => samba is disabled
    exit 0
fi

BASEDN="DC=${AD_REALM//./,DC=}"
echo "BASEDN: $BASEDN"
while IFS=':' read -r nom_user pwd_user sid_user
do
    CURRENT_SID=$(ldbsearch -H /var/lib/samba/private/sam.ldb "(&(objectclass=user)(name=$nom_user))" |grep objectSid | cut -d" " -f2)
    if [[ -z "$CURRENT_SID" ]]
    then
        samba-tool user create "$nom_user" --random-password
        CURRENT_SID=$(ldbsearch -H /var/lib/samba/private/sam.ldb "(&(objectclass=user)(name=$nom_user))" |grep objectSid | cut -d" " -f2)
    fi
    echo "$sid_user  $CURRENT_SID  $nom_user"

    if [[ "$sid_user" != "$CURRENT_SID" ]]
	    then
	        cat >/tmp/changeSID.ldif <<EOF
dn: CN=$nom_user,CN=Users,$BASEDN
changetype: modify
replace: objectSid
objectSid: $sid_user
EOF
	        ldbmodify -v -H "/var/lib/samba/private/sam.ldb.d/${BASEDN^^}.ldb" /tmp/changeSID.ldif
        RESULT="$?"
        echo "ldbmodify = $RESULT"
        if [[ "$RESULT" -eq 0 ]]
        then
            pdbedit --set-nt-hash="$pwd_user" "$nom_user"
            echo "pdbedit = $?"
        fi
    fi
done <"$VM_INPUT/users"

cat "$VM_INPUT/machines"

CURRENT_DATETIME=$(date "+%Y%m%d%H%M%S.0Z")
while IFS=':' read -r nom_machine_avec_dollar pwd_machine sid_machine
do
	nom_machine=${nom_machine_avec_dollar:0:-1}

	# pour tester !
	#ldbdel -v -H "/var/lib/samba/private/sam.ldb.d/${BASEDN^^}.ldb" "CN=${nom_machine^^},CN=Computers,$BASEDN"
	#echo "$?"

    CURRENT_SID=$(ldbsearch -H /var/lib/samba/private/sam.ldb "(&(objectclass=computer)(name=$nom_machine^^))" |grep objectSid | cut -d" " -f2)
	echo "NOM=$nom_machine SID=$sid_machine : CURRENT_SID=$CURRENT_SID"

    if [[ "$sid_machine" != "$CURRENT_SID" ]]
    then
        cat >/tmp/changeSID.ldif <<EOF
dn: CN=${nom_machine^^},CN=Computers,$BASEDN
changetype: add
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: user
objectClass: computer
cn: ${nom_machine^^}
instanceType: 4
whenCreated: $CURRENT_DATETIME
whenChanged: $CURRENT_DATETIME
name: ${nom_machine^^}
badPwdCount: 0
codePage: 0
countryCode: 0
badPasswordTime: 0
lastLogoff: 0
lastLogon: 0
primaryGroupID: 515
logonCount: 0
sAMAccountName: ${nom_machine_avec_dollar^^}
sAMAccountType: 805306369
objectCategory: CN=Computer,CN=Schema,CN=Configuration,$BASEDN
objectSid: ${sid_machine}
isCriticalSystemObject: FALSE
userAccountControl: 4128
uSNChanged: 3788
distinguishedName: CN=${nom_machine^^},CN=Computers,$BASEDN
dNSHostName: ${nom_machine}.${AD_REALM}
servicePrincipalName: HOST/${nom_machine}.${AD_REALM}
servicePrincipalName: RestrictedKrbHost/${nom_machine}.${AD_REALM}
servicePrincipalName: HOST/${nom_machine}
servicePrincipalName: RestrictedKrbHost/${nom_machine}
msDS-SupportedEncryptionTypes: 28
EOF
        ldbmodify -v -H "/var/lib/samba/private/sam.ldb.d/${BASEDN^^}.ldb" /tmp/changeSID.ldif
        RESULT="$?"
        echo "ldbmodify = $RESULT"
        if [[ "$RESULT" -eq 0 ]]
        then
            pdbedit --set-nt-hash="$pwd_machine" "$nom_machine_avec_dollar"
            echo "pdbedit = $?"
        fi
    fi
done <"$VM_INPUT/machines"

