#!/bin/bash

EXIT_ON_ERROR="${1:-no}"
if [ -f /etc/eole/samba4-vars.conf ]
then
    # shellcheck disable=SC1091
    source /etc/eole/samba4-vars.conf
else
    # Template is disabled => samba is disabled
    echo "Samba is disabled"
    exit 0
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

if [ "$AD_DNS_BACKEND" != "BIND9_DLZ" ]
then
   echo "la configuration ne demande pas l'utilisation de BIND. Stop"
   exit 0
fi

echo "==============================================="
echo "* named -v"
named -v

echo "==============================================="
echo "* check configuration 'server services'"
SERVER_SERVICES="$(testparm -s --parameter-name="server services" 2>/dev/null)"
SERVER_SERVICES_ATTENDUS="s3fs, rpc, nbt, wrepl, ldap, cldap, kdc, drepl, winbindd, ntp_signd, kcc, dnsupdate"
if [ "$SERVER_SERVICES" != "$SERVER_SERVICES_ATTENDUS" ]
then
    echo "* 'server services' incorrecte : $SERVER_SERVICES"
    echo "* 'server services' attendus   : $SERVER_SERVICES_ATTENDUS"
    exit 1    
else
    echo "* 'server services' : OK"
fi

echo "==============================================="
ls -lai /var/lib/samba/
ls -lai /var/lib/samba/private
ls -lai /etc/krb5.conf

echo "==============================================="
if [ -d /var/lib/samba/bind-dns ]
then
    ls -lai /var/lib/samba/bind-dns
    afficheFichier /etc/bind/named.conf
    afficheFichier /etc/bind/named.conf.options
    afficheFichier /etc/bind/named.conf.local
    afficheFichier /etc/bind/named.conf.default-zones
    afficheFichier /var/lib/samba/bind-dns/named.conf
    # uniquement pour SAMBA_INTERNAL, pas bind !
    afficheFichier /var/lib/samba/bind-dns/named.conf.update
    afficheFichier /var/lib/samba/bind-dns/named.txt
else
    afficheFichier /var/lib/samba/private/named.conf
    
    # uniquement pour SAMBA_INTERNAL, pas bind !
    afficheFichier /var/lib/samba/private/named.conf.update
fi

echo "==============================================="
echo  "Interrogation DNS du serveur"
dig "${AD_HOST_NAME}.${AD_REALM}"
checkExitCode "$?" "fonctionnement dig"

echo "==============================================="
echo  "Interrogation DNS forward .."
dig dev-eole.ac-dijon.fr | grep dev-eole.ac-dijon.fr 
checkExitCode "$?" "résolution forward"

echo "==============================================="
afficheFichier /var/lib/samba/private/dns_update_list
 
echo "==============================================="
echo "* klist -k /var/lib/samba/private/dns.keytab "
klist -k /var/lib/samba/private/dns.keytab 
checkExitCode "$?" "klist dns"

echo "==============================================="
COMPTE_SERVICE_DNS="dns-${AD_HOST_NAME,,}"
echo "* check compte service dns '$COMPTE_SERVICE_DNS'"
ldbsearch -H /var/lib/samba/private/sam.ldb "cn=$COMPTE_SERVICE_DNS" dn | grep "dn:"
checkExitCode "$?" "check compte service"

echo "==============================================="
echo "kinit"
kinit "dns-${AD_HOST_NAME,,}@${AD_REALM^^}" -k -t /var/lib/samba/private/dns.keytab
checkExitCode "$?" "kinit with keytab"

echo "==============================================="
echo "* samba_dnsupdate --verbose " 
samba_dnsupdate --verbose 
#--all-names
checkExitCode "$?" "samba_dnsupdate"

echo "==============================================="
echo "* samba_dnsupdate --verbose --use-samba-tool --rpc-server-ip=${AD_HOST_IP} " 
samba_dnsupdate --verbose --use-samba-tool --rpc-server-ip="${AD_HOST_IP}"

echo "==============================================="
echo "* test New DNS Entries Are Not Resolvable "
find /var/lib/samba/private/sam.ldb.d/ -name *.ldb | while read -r LDB
do
    LDB_BIND="${LDB//private/bind-dns\/dns/}"
    # shellcheck dsiable=SC2012
    INODE_SAMBA=$(ls -i "$LDB" | awk '{ print $1;}')
    # shellcheck dsiable=SC2012
    INODE_BIND=$(ls -i "$LDB_BIND" | awk '{ print $1;}')
    if [ "$INODE_SAMBA" != "$INODE_BIND" ]
    then
        echo "ATTENTION: INODE pour $LDB"
        ls -ldai "$LDB" "$LDB_BIND"
    else
        echo "INODE OK pour $LDB"
    fi
done

find /var/lib/samba/private/sam.ldb.d/ -name *.ldb | while read -r LDB
do
    LDB_BIND="${LDB//private/bind-dns\/dns/}"
    # shellcheck dsiable=SC2012
    INODE_SAMBA=$(ls -i "$LDB" | awk '{ print $1;}')
    # shellcheck dsiable=SC2012
    INODE_BIND=$(ls -i "$LDB_BIND" | awk '{ print $1;}')
    if [ "$INODE_SAMBA" != "$INODE_BIND" ]
    then
        checkExitCode "$?" "ERREUR INODE pour $LDB"
        /bin/rm "$LDB_BIND" 2>/dev/null || true
        ln --physical "$LDB" "$LDB_BIND"
        ls -lai "$LDB" "$LDB_BIND"
        chown root:bind "$LDB_BIND"
        chmod 660 "$LDB_BIND"
        ls -lai "$LDB"
        ls -lai "$LDB_BIND"
    else
        echo "INODE OK pour $LDB"
    fi
done

systemctl status --no-pager bind9.service 
systemctl status --no-pager samba-ad-dc.service 

systemctl stop samba-ad-dc.service 
systemctl stop bind9.service 

systemctl restart bind9
systemctl restart samba-ad-dc

if [ -d /var/lib/samba/bind-dns ]
then
    echo "==============================================="
    echo "* /var/lib/samba/bind-dns (chmod 770 /var/lib/samba/bind-dns; chown root:bind /var/lib/samba/bind-dns)"
    ls -ldai /var/lib/samba/bind-dns
    ls -lai /var/lib/samba/bind-dns
else
    echo "==============================================="
    echo "* /var/lib/samba/bind-dns absent"
fi

echo "==============================================="
echo "* which nsupdate"
which nsupdate
nsupdate -V

echo "==============================================="
echo "* named-checkconf"
if command -v named-checkconf >/dev/null
then
    if [ -z "$(named-checkconf)" ]
    then
        echo "named-checkconf: OK"
    else
        named-checkconf
        echo "named-checkconf: NOK"
    fi
else
    echo "* named-checkconf absent"
fi

echo "==============================================="
echo "* check named.root"
if [ -f /usr/share/dns/root.hints ]
then
    DB_ROOT=/usr/share/dns/root.hints
else
    DB_ROOT=/etc/bind/db.root
fi
wget -q -O /tmp/named.root http://www.internic.net/zones/named.root
ls -l /tmp/named.root "$DB_ROOT"
if diff --ignore-all-space /tmp/named.root "$DB_ROOT" 
then
    echo "Warning: db.root DIFFERENT"
else
    echo "db.root ok"
fi