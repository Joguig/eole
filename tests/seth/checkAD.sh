#!/bin/bash

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

function checkTcp
{
    tcpcheck 1 "${1}" |grep -q alive
    checkExitCode "$?" "Accès Port ${1}"
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

#set -e
ADMIN_PASSWORD="Eole12345!"
EXIT_ON_ERROR="${1:-no}"
if [ "${2:-UPDATE}" == UPDATE ]
then
    UPDATE_REFERENCE_FILES=OUI
else
    UPDATE_REFERENCE_FILES=NON
fi
echo "UPDATE_REFERENCE_FILES=$UPDATE_REFERENCE_FILES"
if [ "${3}" == WSAD ]
then
    DC1_IS_WSAD=OUI
else
    DC1_IS_WSAD=NON
fi
echo "DC1_IS_WSAD=$DC1_IS_WSAD"
if ciVersionMajeurApres "2.7.1"
then
    OPT_KERBEROS=""
else
    OPT_KERBEROS=("-k 1")
fi
echo "OPT_KERBEROS=${OPT_KERBEROS[*]}"

if [ "$VM_MODULE" = scribe ]
then
    CMD=$(command -v "$0")
    #shellcheck disable=SC1091,SC1090
    . "/var/lib/lxc/addc/rootfs/etc/eole/samba4-vars.conf"
    cp -f "$CMD" /var/lib/lxc/addc/rootfs/checkAD.sh
    echo "Execute $0 dans le conteneur ADDC"
    lxc-attach -n addc -- /root/checkAD.sh "$@"
    exit 0
else
    #shellcheck disable=SC1091,SC1090
    if [ -f /etc/eole/samba4-vars.conf ]
    then
        # shellcheck disable=SC1091
        . /etc/eole/samba4-vars.conf
    else
        # Template is disabled => samba is disabled
        echo "Samba is disabled"
        exit 0
    fi
fi

if [ "$DC1_IS_WSAD" == OUI ]
then
    echo "Surcharge AD_ADMIN pour WSAD"
    AD_ADMIN=Administrateur
    ADMIN_PASSWORD=Eole12345!
fi

echo "==============================================="
echo "* Paquets Samba"
(
    dpkg -l |grep SMB/CIFS
    dpkg -l |grep -i samba
    dpkg -l |grep -i bind9 

    # shellchek: disable=SC2116
    USINGS=$(smbd -b |sed -e '/USING_SYSTEM/!d' -e 's/.*USING_SYSTEM_//')
    for USING in $USINGS
    do
       # shellcheck disable=SC2116
       USING="$(echo "$USING")"
       dpkg -l |grep -i "$USING" 
    done
) |sort |uniq

echo "==============================================="
echo "* Samba Version"
samba -V

echo "==============================================="
echo "* Check samba .so "
(TERM= ;ldd "$(command -v samba)") | sed 's/(.*)//' | sort >/tmp/samba_libs.txt 
if [ "$DC1_IS_WSAD" == NON ]
then
    # SETH -> les groupes sont en anglais !
    ciCheckDiffFichierReference /tmp/samba_libs.txt PATH "/mnt/eole-ci-tests/module/seth/samba_libs-$VM_MACHINE-$VM_VERSIONMAJEUR" "libs samba OK" "libs samba différentes!" NON "$UPDATE_REFERENCE_FILES"
else
    # WSAD les groupes sont en francais
    ciCheckDiffFichierReference /tmp/samba_libs.txt PATH "/mnt/eole-ci-tests/module/seth/samba_libs_WSAD-$VM_MACHINE-$VM_VERSIONMAJEUR" "libs samba OK" "libs samba différentes!" NON "$UPDATE_REFERENCE_FILES"
fi

afficheFichier /etc/resolv.conf
afficheFichier /etc/hosts
afficheFichier /etc/ntpd.conf
afficheFichier /etc/samba/smb.conf
afficheFichier /etc/krb5.conf
afficheFichier /var/lib/samba/private/krb5.conf
if [ "$AD_SERVER_ROLE" == 'controleur de domaine' ]
then
    if [ -d /var/lib/samba/bind-dns ]
    then
        afficheFichier /var/lib/samba/bind-dns/named.conf
        #afficheFichier /var/lib/samba/bind-dns/named.txt
    else
        afficheFichier /var/lib/samba/private/named.conf
    fi
fi

echo "==============================================="
echo "Check TCP Port Open "

checkTcp 127.0.0.1:445 
checkTcp "${AD_HOST_IP}":445 

if [ "$AD_SERVER_ROLE" == 'controleur de domaine' ]
then
    # End Point Mapper (DCE/RPC Locator Service) & Replication
    checkTcp 127.0.0.1:135 
    checkTcp "${AD_HOST_IP}":135 

    checkTcp 127.0.0.1:389
    checkTcp "${AD_HOST_IP}":389 
    
    # DNS :  User and Computer Authentication, Name Resolution, Trusts
    checkTcp 127.0.0.1:53 
    checkTcp "${AD_HOST_IP}":53 

    # kerberos :  User and Computer Authentication, Forest Level Trusts
    checkTcp 127.0.0.1:88 
    checkTcp "${AD_HOST_IP}":88
     
    # Kerberos kpasswd : Replication, User and Computer Authentication, Trusts
    checkTcp 127.0.0.1:464 
    checkTcp "${AD_HOST_IP}":464 

    # LDAPS
    checkTcp 127.0.0.1:636 
    checkTcp "${AD_HOST_IP}":636 

    # RSYNC
    #checkTcp 127.0.0.1:873 
    #checkTcp "${AD_HOST_IP}":873 

    # Global Cataloge
    checkTcp 127.0.0.1:3268 
    checkTcp "${AD_HOST_IP}":3268 

    # Global Cataloge SSL
    checkTcp 127.0.0.1:3269 
    checkTcp "${AD_HOST_IP}":3269
    
    # Multicast DNS 
    #checkTcp 127.0.0.1:5353 
    #checkTcp "${AD_HOST_IP}":5353
    
    # RPC, DFSR (SYSVOL) File Replication
    #checkTcp 127.0.0.1:5722 
    #checkTcp "${AD_HOST_IP}":5722
fi


echo "==============================================="
echo "Check DNS with AD"
# ATTENTION AU POINT EN FIN DE LIGNE !
host -t SRV "_ldap._tcp.dc._msdcs.${AD_REALM}."
checkExitCode "$?" "résolution _ldap global catalog"

host -t SRV "_ldap._tcp.${AD_REALM}."
checkExitCode "$?" "résolution _ldap realm"

host -t SRV "_kerberos._udp.${AD_REALM}."
checkExitCode "$?" "résolution _kerberos"

host -t A "${AD_HOST_NAME}.${AD_REALM}."
cdu="$?"
if [ "${AD_HOST_NAME}" == "file" ] && [ "$cdu" -ne "0" ]
then
    echo "Entrée DNS manquante...."
else
    echo "Entrée DNS présente, Ok"
fi
checkExitCode "$cdu" "résolution realm"

echo "==============================================="
echo  "Interrogation DNS du serveur (DIG)"
echo " - ${AD_HOST_NAME}.${AD_REALM}" 
dig +short "${AD_HOST_NAME}.${AD_REALM}"
checkExitCode "$?" "fonctionnement dig"

echo " - @${AD_REALM} ${AD_HOST_NAME}.${AD_REALM}" 
dig @"${AD_REALM}" +short "${AD_HOST_NAME}.${AD_REALM}"
checkExitCode "$?" "fonctionnement dig REALM"

echo  "Interrogation DNS forward .."
dig +short dev-eole.ac-dijon.fr | grep adonis.ac-dijon.fr.
checkExitCode "$?" "résolution forward"

dig @"${AD_REALM}" +short dev-eole.ac-dijon.fr | grep adonis.ac-dijon.fr.
checkExitCode "$?" "résolution forward REALM"

echo "==============================================="
echo "Check KERBEROS:"
if [ -f "${AD_ADMIN_KEYTAB_FILE}" ]
then
    echo "Kinit with keytab"
    kinit "$AD_ADMIN@${AD_REALM^^}" -k -t "${AD_ADMIN_KEYTAB_FILE}"
    checkExitCode "$?" "kinit with keytab"
else
    echo "Kinit with password"
    kinit "$AD_ADMIN@${AD_REALM^^}" < <(echo "${ADMIN_PASSWORD}")
    checkExitCode "$?" "kinit with password"
fi

echo "==============================================="
echo "klist:"
klist

echo "==============================================="
echo "Check NT authentication"
if [ -f "${AD_ADMIN_PASSWORD_FILE}" ]
then
    smbclient -L localhost -U "${AD_ADMIN}" < <(echo "${ADMIN_PASSWORD}")
    checkExitCode "$?" "smbclient localhost"
fi

if [ "$AD_SERVER_ROLE" == 'controleur de domaine' ]
then
    echo "==============================================="
    echo "smbclient: //localhost/netlogon"
    smbclient //localhost/netlogon -U "${AD_ADMIN}" -c 'ls' < <(echo "${ADMIN_PASSWORD}")
    checkExitCode "$?" "smbclient netlogon"

    echo "smbclient: //${AD_REALM}/netlogon"
    smbclient "//${AD_REALM}/netlogon" -U "${AD_ADMIN}" -c 'ls' < <(echo "${ADMIN_PASSWORD}")
    checkExitCode "$?" "smbclient netlogon realm"

    echo "smbclient: //${AD_HOST_NAME}/netlogon"
    smbclient "//${AD_HOST_NAME}/netlogon" -U "${AD_ADMIN}" -c 'ls' < <(echo "${ADMIN_PASSWORD}")
    checkExitCode "$?" "smbclient netlogon ${AD_HOST_NAME}"

    echo "smbclient: //${AD_REALM}/sysvol/"
    smbclient "//${AD_REALM}/sysvol" -U "${AD_ADMIN}" -c "ls ${AD_REALM}/\*" < <(echo "${ADMIN_PASSWORD}")
    checkExitCode "$?" "smbclient sysvol"

    echo "smbclient (kerberos): //${AD_HOST_NAME}/netlogon"
    smbclient "//${AD_HOST_NAME}/netlogon" "${OPT_KERBEROS[@]}" -c 'ls'
    checkExitCode "$?" "smbclient kerberos"

    #echo "smbclient (kerberos): //${AD_REALM}/netlogon"
    #KRB5_TRACE=/dev/stderr smbclient "//${AD_REALM}/netlogon" "${OPT_KERBEROS[@]}" -c 'ls'
    #checkExitCode "$?" "smbclient kerberos"

    echo "==============================================="
    echo "Affichage Etat Replication:"
    samba-tool drs showrepl
    echo "Note about the 'Warning: No NC replicated for Connection!' line: It can be safely ignored. "
    echo "See FAQ: Message: Warning: No NC replicated for Connection!"

    # echo "==============================================="
    echo "Affichage Difference LDAP / DC référence :"
    if [[ -e "${AD_DC_SYSVOL_REF}" ]]
    then
        samba-tool ldapcmp --filter=whenchanged ldap://localhost "ldap://${AD_DC_SYSVOL_REF}" domain "${OPT_KERBEROS[@]}"
        checkExitCode "$?" "ldapcmp"
    fi

    (
    echo "==============================================="
    echo "Affichage Drois des Comptes:"
    net rpc rights list accounts -U "${AD_ADMIN}" -I "${AD_REALM}" < <(echo "${ADMIN_PASSWORD}") | sort
    ) >/tmp/samba_users_groups.txt
    checkExitCode "$?" "Affichage Drois des Comptes"
else
    (
    echo "==============================================="
    echo "Affichage liste compte utilisateur depuis membre"
    getent passwd | sort 

    echo "==============================================="
    echo "Affichage liste des groupes depuis membre"
    getent group | sort 

    echo "==============================================="
    echo "Affichage Drois des Comptes:"
    net rpc rights list accounts -U "${AD_ADMIN}" -I "${AD_REALM}" < <(echo "${ADMIN_PASSWORD}") | sort
    ) >/tmp/samba_users_groups.txt
    checkExitCode "$?" "Affichage Drois des Comptes"
fi
if [ "$DC1_IS_WSAD" == NON ]
then
    # SETH -> les groupes sont en anglais !
    ciCheckDiffFichierReference /tmp/samba_users_groups.txt PATH "/mnt/eole-ci-tests/module/seth/samba_users_groups-$VM_MACHINE-$VM_VERSIONMAJEUR" "users/groups samba OK" "users/groups samba différentes!" NON "$UPDATE_REFERENCE_FILES"
else
    # WSAD -> les groupes sont en français !
    ciCheckDiffFichierReference /tmp/samba_users_groups.txt PATH "/mnt/eole-ci-tests/module/seth/samba_users_groups_WSAD-$VM_MACHINE-$VM_VERSIONMAJEUR" "users/groups samba OK" "users/groups samba différentes!" NON "$UPDATE_REFERENCE_FILES"
fi

echo "==============================================="
if [ "$AD_SERVER_ROLE" == 'controleur de domaine' ]
then
    echo "* journalctl samba"
    journalctl -xe -u samba --boot --no-pager
else
    echo "* journalctl smbd"
    journalctl -xe -u smbd --boot --no-pager | grep -v "Aucun fichier ou dossier de ce type"

    echo "* journalctl winbind"
    journalctl -xe -u winbind --boot --no-pager
fi
echo "==============================================="

exit 0
