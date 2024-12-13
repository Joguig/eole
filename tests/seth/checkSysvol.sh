#!/bin/bash

ADMIN_PASSWORD="Eole12345!"
EXIT_ON_ERROR="${1:-no}"
WSAD="${2:-no}"
COMPARE_WITH="${3}"

if [ ! -f /etc/eole/samba4-vars.conf ]
then
    echo "Samba is disabled"
    exit 1
fi

# shellcheck disable=SC1091
. /etc/eole/samba4-vars.conf

if [ "$WSAD" == yes ]
then
    AD_ADMIN=Administrateur
    ADMIN_PASSWORD=Eole12345!
fi
if ciVersionMajeurApres "2.7.1"
then
    OPT_KERBEROS=""
else
    OPT_KERBEROS=("-k 1")
fi

function checkExitCode()
{
    local EC
    local MSG
    EC="${1}"
    MSG="${2}"
    if [[ "$EC" -eq 0 ]]
    then
        return 0
    fi
    if [ "$EXIT_ON_ERROR" != "no" ]
    then
        echo "Error: '$MSG' exit=$EC, arret demandé"
        bash sauvegarde-fichier.sh maj_auto
        ciCheckExitCode "$EC" 
    else
        echo "Warning: '$MSG' exit=$EC, mais je continue...."
    fi
}

function afficheFichier()
{
    echo "==============================================="
    echo "* Cat ${1}"
    if [ -f "${1}" ]
    then
        cat "${1}"
    else
        echo "Attention: ${1} manquant"
    fi
}

echo "==============================================="
echo "* Samba Version"
smbd -b >/tmp/build_conf
ciCheckDiffFichierReference /tmp/build_conf PATH "/mnt/eole-ci-tests/module/seth/build_conf-$VM_MACHINE-$VM_VERSIONMAJEUR" "smbd options compilation OK" "smbd options compilation différentes!" NON


if [ "$AD_SERVER_ROLE" != 'controleur de domaine' ]
then
    exit 0
fi

echo "==============================================="
echo "smbclient:"
smbclient //localhost/netlogon -U "${AD_ADMIN}" -c 'ls' < <(echo "${ADMIN_PASSWORD}")
checkExitCode "$?" "smbclient netlogon"

echo "smbclient (kerberos):"
smbclient "//${AD_HOST_NAME}/netlogon" "${OPT_KERBEROS[@]}" -c 'ls'
checkExitCode "$?" "smbclient kerberos"

echo "==============================================="
echo "Affichage Etat Replication:"
samba-tool drs showrepl
echo "Note about the Warning: No NC replicated for Connection! line: It can be safely ignored. "
echo "See FAQ: Message: Warning: No NC replicated for Connection!"

# echo "==============================================="
echo "Affichage Difference LDAP / DC référence :"
if [[ -e "${AD_DC_SYSVOL_REF}" ]]
then
    #samba-tool ldapcmp --filter=whenchanged ldap://localhost "ldap://${AD_DC_SYSVOL_REF}" domain "${OPT_KERBEROS[@]}"
    samba-tool ldapcmp ldap://localhost "ldap://${AD_DC_SYSVOL_REF}" domain "${OPT_KERBEROS[@]}"
    checkExitCode "$?" "ldapcmp"
fi
echo "==============================================="

cd /home/sysvol/ || exit 1

echo "==============================================="
ls -ld /home/sysvol/

getfacl .
if ! command -v getfattr >/dev/null 2>&1
then
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y attr
fi
if command -v getfattr >/dev/null 2>&1
then
    getfattr -n security.NTACL -d /home/sysvol/
fi

if ciVersionMajeurAvant "2.10."
then
    echo "ATTENDU SYSVOL_ACL"
    echo "O:LAG:BAD:P(A;OICI;0x001f01ff;;;BA)(A;OICI;0x001200a9;;;SO)(A;OICI;0x001f01ff;;;SY)(A;OICI;0x001200a9;;;AU)"
    samba-tool ntacl get /home/sysvol/ --as-sddl
    echo "==============================================="
    
    echo "==============================================="
    echo "POLICIES"
    ls -ld "/home/sysvol/${AD_REALM}/"
    
    echo "ATTENDU POLICIES_ACL"
    echo "O:LAG:BAD:P(A;OICI;0x001f01ff;;;BA)(A;OICI;0x001200a9;;;SO)(A;OICI;0x001f01ff;;;SY)(A;OICI;0x001200a9;;;AU)(A;OICI;0x001301bf;;;PA)"
    samba-tool ntacl get "/home/sysvol/${AD_REALM}/" --as-sddl
    echo "==============================================="
else
    echo "samba-tool ntacl get /home/sysvol/ ne fonctionne plus en 2.10"
fi

echo "Export idmap dans $VM_DIR/idmap-ldb.ldif"
ldbsearch -H /var/lib/samba/private/idmap.ldb | grep -v "# " >"$VM_DIR/idmap-ldb.ldif"

if [ -n "$COMPARE_WITH" ]
then
    if [ -f "$VM_DIR_OUTPUT/$COMPARE_WITH/idmap-ldb.ldif" ]
    then
        echo "Comparaison idmap dans $VM_DIR_OUTPUT/$COMPARE_WITH/idmap-ldb.ldif"
        diff --side-by-side "$VM_DIR_OUTPUT/${VM_MACHINE}-idmap-ldb.ldif" "$VM_DIR_OUTPUT/$COMPARE_WITH/idmap-ldb.ldif"
    fi
fi

samba-tool ntacl sysvolcheck
echo $?    
