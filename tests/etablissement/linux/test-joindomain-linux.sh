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
    ciSignalAlerte "'$MSG' exit=$EC"
    if [ "$EXIT_ON_ERROR" != "no" ]
    then
        bash sauvegarde-fichier.sh maj_auto
        ciCheckExitCode "$EC" 
    fi
}

# shellcheck disable=SC1091,SC1090
. /root/getVMContext.sh NO_DISPLAY

EXIT_ON_ERROR=no
ciClearJournalLogs 1>/dev/null 2>&1

ciSetHttpAndHttpsProxy
export no_proxy=salt

if [ "$VM_ETABLISSEMENT" == etb3 ]
then
	AD_REALM="etb3.lan"
else
	if [ "$VM_ETABLISSEMENT" == etb1 ]
	then
		AD_REALM="dompedago.etb1.lan"
	else
		echo "$0: cas non géré"
		exit 0
	fi
fi

ciRenamePcLinux

echo "==============================================="
echo "* Install sssd et cie..."
if ! command -v realm
then
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y sssd-ad sssd-tools realmd adcli 
fi

echo "* pré init krb5..."
if [ ! -f /etc/krb5.conf ]
then
    cat > /etc/krb5.conf <<EOF
[libdefaults]
    default_realm = ${AD_REALM^^}
    dns_lookup_realm = false
    dns_lookup_kdc = true
    # disable Reverse Dns resolution
    rdns = false
EOF
fi
ciAfficheContenuFichier /etc/krb5.conf

echo "* Install krb5-user sssd-krb5..."
if ! command -v ktutil 2>/dev/null
then 
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y krb5-user sssd-krb5 >/dev/null
fi

echo "* Install 'net' command..."
if ! command -v net 2>/dev/null
then 
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y samba-common-bin >/dev/null
fi

echo "* Install 'msktutil' command..."
if ! command -v msktutil 2>/dev/null
then
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y msktutil >/dev/null
fi
echo "* Install 'ldbsearch' command..."
if ! command -v ldbsearch 2>/dev/null
then
    export DEBIAN_FRONTEND=noninteractive
    apt install ldb-tools >/dev/null
fi
echo "* remove nscd..."
# déconseillé avec SSSD !
apt-get remove nscd -y  >/dev/null

echo "==============================================="
echo "==============================================="
PC_NAME="pc-$VM_ID"
echo "PC_NAME=$PC_NAME"

PC_NAME_DOMAIN=$(hostname -f)
echo "PC_NAME_DOMAIN=$PC_NAME_DOMAIN"
if [ "$PC_NAME_DOMAIN" != "${PC_NAME}.${AD_REALM}" ]
then
    PC_NAME_DOMAIN="${PC_NAME}.${AD_REALM}"
    echo "ATTENTION: le nom complet venant du DHCP n'est pas le bon, remplacé par '$PC_NAME_DOMAIN'"
    sed -i "s/$PC_NAME/$PC_NAME_DOMAIN $PC_NAME/" /etc/hosts
fi
hostnamectl
ciAfficheContenuFichier /etc/hosts

echo "* resolvectl query $PC_NAME_DOMAIN"
resolvectl query "$PC_NAME_DOMAIN"

echo "* ping salt"
ciGetNamesInterfaces
ciPingHost salt "$VM_INTERFACE0_NAME"

echo "* getent hosts salt"
getent hosts salt

echo "* resolvectl status"
ciAfficheContenuFichier /etc/resolv.conf
resolvectl status

echo "* timedatectl status"
if grep -q "#NTP=" /etc/systemd/timesyncd.conf
then
    echo "ATTENTION: le NTP venant du DHCP n'est pas le bon"
    echo "NTP=10.1.3.11" >>/etc/systemd/timesyncd.conf
    systemctl status systemd-timedated.service
    systemctl status systemd-timesyncd.service
fi
ciAfficheContenuFichier /etc/systemd/timesyncd.conf 
timedatectl

echo "==============================================="
echo  "Interrogation DNS du serveur depuis le client"
echo "==============================================="
host -t SRV "_ldap._tcp.dc._msdcs.${AD_REALM}."
checkExitCode "$?" "résolution _ldap global catalog"

host -t SRV "_ldap._tcp.${AD_REALM}."
checkExitCode "$?" "résolution _ldap realm"

host -t SRV "_kerberos._udp.${AD_REALM}."
checkExitCode "$?" "résolution _kerberos"

echo  "* Interrogation DC du serveur"
dig "${AD_REALM}" | grep -v ";;" 
checkExitCode "$?" "fonctionnement dig"

echo  "* Interrogation dev-eole.ac-dijon.fr (valide DNS forward)"
dig dev-eole.ac-dijon.fr | grep -v ";;" 
checkExitCode "$?" "résolution forward"

ciAfficheContenuFichier /etc/realmd.conf
cat >/etc/realmd.conf <<EOF
[users]
default-home = /home/%u@%d
default-shell = /bin/bash
EOF

if /bin/false
then
    host -t A "${PC_NAME_DOMAIN}."
    cdu="$?"
    if [ "$cdu" -ne "0" ]
    then
        # il faut la crée !
        echo "Entrée DNS manquante...."
    else
        msktutil delete \
          --computer-name "${PC_NAME^^}"
        
        realm leave
    fi
fi

if realm list | grep -q 'configured: kerberos-member'
then
    echo "PC joint au domaine : OK"
    #exit 0
else
    # cf.: https://lists.samba.org/archive/cifs-protocol/2015-March/002691.html
    
    echo "* Kinit with password"
    kinit "Administrator@${AD_REALM^^}" < <(echo "Eole12345!")
    checkExitCode "$?" "kinit with password"
    
    echo "* klist:"
    klist

    echo "* host pc"
    host -t A "${PC_NAME_DOMAIN}."
    cdu="$?"
    if [ "$cdu" -ne "0" ]
    then
        # il faut la crée !
        echo "Entrée DNS manquante...."


        echo "msktutil create"
        msktutil create \
          --computer-name "${PC_NAME^^}" \
          --hostname "${PC_NAME_DOMAIN}" \
          --upn "host/${PC_NAME_DOMAIN}" \
          --enctypes 0x18 \
          --verbose
        # --base OU=Linux,OU=Servers \
    else
        echo "Entrée DNS présente, Ok"
    fi

    echo "* Vérification msDS-SupportedEncryptionTypes"
    ldbsearch -H "ldap://${AD_REALM}" -k yes '(objectclass=computer)' msDS-SupportedEncryptionTypes |grep -v 'ref:' |grep -v '^# ' |grep -v '^$'

    echo "* realm join"
    echo "Eole12345!" |realm join -v "${AD_REALM^^}" \
                                  --user="Administrator@${AD_REALM^^}" \
                                  --os-name="$(lsb_release -sd)" \
                                  --os-version="$(lsb_release -sr)" \
                                  --user-principal="host/${PC_NAME}@${AD_REALM^^}"
    
    # Unspecified GSS failure on my rhel8 machine it was due to DNS not being configured on my Domain Controller. 
    # I had to create the A Record and reverse zone. I also forgot to specify the FQDN on the AD_Server field inside of /etc/sssd/sssd.conf
    sleep 10
    host -t A "${PC_NAME_DOMAIN}."
    cdu="$?"
    if [ "$cdu" -ne "0" ]
    then
        # il faut la crée !
        echo "Entrée DNS manquante...."
    else
        echo "Entrée DNS présente, Ok"
    fi
    
    echo "* samba-tool computer show" 
    # cf.: https://lists.samba.org/archive/cifs-protocol/2015-March/002691.html
    samba-tool computer show "${PC_NAME}" -H "ldap://${AD_REALM}" -UAdministrator%Eole12345! 
    
    echo "* net ads enctypes" 
    net ads enctypes list "${PC_NAME}" 

    echo "* realm permit Domain Users" 
    realm permit "Domain Users@${AD_REALM}"
    
    echo "* realm permit all"
    realm permit --all
fi


echo "* pam-auth-update --enable mkhomedir"
pam-auth-update --enable mkhomedir

ciAfficheContenuFichier /etc/krb5.conf

ciAfficheContenuFichier /etc/sssd/sssd.conf

#cat /etc/sssd/sssd.conf
#cat >/etc/sssd/sssd.conf <<EOF
#[sssd]
#domains = etb3.lan
#config_file_version = 2
#
#[domain/etb3.lan]
#ad_gpo_ignore_unreadable = True
#ad_gpo_access_control = permissive
#default_shell = /bin/bash
#krb5_store_password_if_offline = True
#cache_credentials = True
#krb5_realm = ETB3.LAN
#realmd_tags = manages-system joined-with-adcli 
#id_provider = ad
#fallback_homedir = /home/%u@%d
#override_homedir = /home/%u@%d
#ad_domain = etb3.lan
#use_fully_qualified_names = True
#ldap_id_mapping = True
#access_provider = ad
#
#EOF

sssctl config-check

systemctl restart sssd
echo $?
sleep 4

#authconfig --update --enablesssd --enablesssdauth --enablemkhomedir

ciAfficheContenuFichier /usr/share/pam-configs/mkhomedir
bash -c "cat >/usr/share/pam-configs/mkhomedir" <<EOF
Name: activate mkhomedir
Default: yes
Priority: 900
Session-Type: Additional
Session:
        required                        pam_mkhomedir.so umask=0022 skel=/etc/skel
EOF

RESULTAT="0"
id "admin@${AD_REALM}"
CDU="$?"
if [ "$CDU" -ne 0 ]
then
    echo "* erreur test 'id admin' : $CDU"
    RESULTAT="1"
fi

id "prof1@${AD_REALM}"
CDU="$?"
if [ "$CDU" -ne 0 ]
then
    echo "* erreur test 'id prof1' : $CDU"
    RESULTAT="1"
fi

id "c31e1@${AD_REALM}"
CDU="$?"
if [ "$CDU" -ne 0 ]
then
    echo "* erreur test 'id c31e1' : $CDU"
    RESULTAT="1"
fi

if [ "$RESULTAT" == "1" ]
then
    ciAfficheContenuFichier /etc/nsswitch.conf
    ciAfficheContenuFichier /etc/realmd.conf
    ciAfficheContenuFichier /etc/sssd/sssd.conf
    ciAfficheContenuFichier /etc/security/pam_mount.conf.xml
    rgrep sss /etc/pam.d/ 

#    if command -v lightdm 1>/dev/null 2>&1
#    then
#        echo "* lightdm --show-config"
#        lightdm --show-config
#
#        echo "* lightdm --test-mode --debug"
#        lightdm --test-mode --debug
#    fi
#
#    if command -v NetworkManager 1>/dev/null 2>&1
#    then
#        echo "* NetworkManager --print-config"
#        NetworkManager --print-config
#    fi

fi

echo "RESULTAT=$RESULTAT"
exit "$RESULTAT"
	
