#!/bin/bash -x

GPONAME="eole_script"
ldbsearch -H /var/lib/samba/private/sam.ldb "(&(objectClass=groupPolicyContainer)(displayname=$GPONAME))" >/tmp/gpo.ldif 
cat /tmp/gpo.ldif

GPO=$(grep ^"cn: {" </tmp/gpo.ldif |cut -d " " -f2)
echo "GPO=$GPO"

DN=$(grep ^"dn: " </tmp/gpo.ldif |cut -d " " -f2)
echo "DN=$DN"

versionNumber=$(grep ^"versionNumber: " </tmp/gpo.ldif |cut -d " " -f2)
echo "versionNumber = $versionNumber "

versionNumber=$(( versionNumber + 1 ))
echo "versionNumber = $versionNumber "


ldbmodify -H /var/lib/samba/private/sam.ldb -i <<EOF
dn: $DN
changetype: modify
replace: versionNumber
versionNumber: $versionNumber
EOF

ldbsearch -H /var/lib/samba/private/sam.ldb "(&(objectClass=groupPolicyContainer)(displayname=$GPONAME))" >/tmp/gpo.ldif 
cat /tmp/gpo.ldif
