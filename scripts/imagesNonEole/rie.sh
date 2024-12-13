#!/bin/bash
# shellcheck disable=SC2034,SC2148,SC2009

function doRie()
{
    export DEBIAN_FRONTEND=noninteractive
    export APT_OPTS=""
    doUpgrade
    removeServicesGenant
    apt-get install "$APT_OPTS" -y vim
    ciCheckExitCode "$?"
    apt-get install "$APT_OPTS" -y openssh-server
    ciCheckExitCode "$?"
    apt-get install "$APT_OPTS" -y tshark
    ciCheckExitCode "$?"
    
    sshAccesRoot
    forceModule9P
}

function doRieDnsBanshee()
{
    ciPrintMsgMachine "* rie-dns-banshee"
    if [ ! -f "/etc/debian_version" ]
    then
        ciPrintMsg "rie-dns-banshee doit etre debian "
        exit 1
    fi

    export DEBIAN_FRONTEND=noninteractive
    export APT_OPTS="-y"
    
    echo "* lsb_release -s -c"
    lsb_release -s -c
    
    echo "* cat /etc/apt/sources.list"
    cat /etc/apt/sources.list
    
#    echo "* ecrase /etc/apt/sources.list"
    #deb http://ftp.fr.debian.org/debian/ $(lsb_release -s -c) main
    #deb http://security.debian.org/debian-security/ $(lsb_release -s -c)/updates main
    
#    cat >/etc/apt/sources.list <<EOF
#deb http://ftp.fr.debian.org/debian/ $(lsb_release -s -c)-updates main
#EOF
#   ciCheckExitCode "$?"
    
    echo "* cat /etc/apt/sources.list"
    cat /etc/apt/sources.list
    
    doAptGetWithRetry update
    
    #ciWaitTestHttp "http://ftp.fr.debian.org/debian/"
    #ciCheckExitCode "$?" "test debian"
    
    doRie
    apt-get install "$APT_OPTS" -y apache2
    ciCheckExitCode "$?"
    apt-get install "$APT_OPTS" -y libapache2-mod-php
    ciCheckExitCode "$?"
    apt-get install "$APT_OPTS" -y bind9
    ciCheckExitCode "$?"

    #Traitement des données Bind
    cp /mnt/eole-ci-tests/dataset/ecologie/dns-banshee/bind/*.* /etc/bind
    chown  root:bind /etc/bind/e2.rie.gouv.fr.lan
    chown  root:bind /etc/bind/named.conf.local
    chown  root:bind /etc/bind/named.conf.options

    systemctl restart bind9.service

    #Traitement des données Banshee
    cat >/var/www/html/test_wget.txt<<EOF
OK
EOF

    cp -R /mnt/eole-ci-tests/dataset/ecologie/dns-banshee/mdp /home/
    chown -R root:www-data /home/mdp
    cat >/etc/apache2/sites-available/diff_cle.conf<<EOF
Alias /diff_cle/ /home/mdp/diff/
<Directory /home/mdp/diff/>
Require all granted
</Directory>
EOF

    cat >/etc/apache2/sites-available/ldif.conf<<EOF
Alias /ldif/ /home/mdp/ldif/
<Directory /home/mdp/ldif/>
Require all granted
</Directory>
EOF

    a2ensite diff_cle
    a2ensite ldif
    systemctl reload apache2.service
    tagImage
}

function doRieLDAPMA()
{
    ciPrintMsgMachine "* rie-ldapma"
    if [ ! -f "/etc/debian_version" ]
    then
        ciPrintMsg "rie-ldapma doit etre debian "
        exit 1
    fi

    export DEBIAN_FRONTEND=noninteractive
    export APT_OPTS="-y"
    doRie
    apt-get install "$APT_OPTS" -y slapd
    ciCheckExitCode "$?"
    
    if [ ! -d /var/lib/ldap/equipement ]
    then
        systemctl stop slapd
        echo "Intégration de la configuration"
        rm -rf /etc/ldap/slapd.d/
        mkdir -p /var/lib/ldap/equipement
        chown openldap:openldap /var/lib/ldap/equipement/
        cp -R "${VM_DIR_EOLE_CI_TEST}/dataset/ecologie/rie.ldapma/etc" /
        cp -R "${VM_DIR_EOLE_CI_TEST}/dataset/ecologie/rie.ldapma/usr" /
        echo "Initialisation de la base LDAP"
        slapadd -v < "$VM_DIR_EOLE_CI_TEST/dataset/ecologie/ldapma/export-ddt-101.ldif" 
        ciCheckExitCode "$?"
        
        chown -R openldap:openldap /var/lib/ldap/equipement/
        systemctl start slapd
        sleep 10
        journalctl --no-pager -u slapd.service
    fi
    tagImage
}

# shellcheck disable=SC1091
source /dev/stdin </mnt/eole-ci-tests/scripts/imagesNonEole/functions.sh
    
echo "FRESHINSTALL_IMAGE=$FRESHINSTALL_IMAGE"
echo "DAILY_IMAGE=$DAILY_IMAGE"
IMAGE_FINALE=${1:-$DAILY_IMAGE}
IMAGE_SOURCE=${2:-$FRESHINSTALL_IMAGE}
echo "IMAGE_SOURCE=$IMAGE_SOURCE"
echo "IMAGE_FINALE=$IMAGE_FINALE"
export DEBIAN_FRONTEND=noninteractive
    
case "$IMAGE_FINALE" in
    rie-ldap*)
        doRieLDAPMA
        ;;

    rie-dns-banshee*)
        doRieDnsBanshee
        ;;

    *)
        echo "IMAGE_FINALE = $IMAGE_FINALE : inconnu, doUpgrade"
        exit 1
        ;;
esac
exit $?