#!/bin/bash

# shellcheck disable=SC1091
. /usr/lib/eole/ihm.sh

ad_user="$(CreoleGet ad_user)"
ad_domain="$(CreoleGet ad_domain)"
ad_address="$(CreoleGet ad_address)"
ad_server_fullname="$(CreoleGet ad_server_fullname)"
ad_local="$(CreoleGet ad_local)"
ad_multietab="$(CreoleGet ead_support_multietab non)"

if [ "$(systemctl is-enabled winbind.service)" = 'masked' ];
then
    systemctl unmask winbind.service
    systemctl enable winbind.service
fi

# disable nmbd #31408
if  systemctl is-enabled nmbd.service >/dev/null ;
then
    systemctl stop nmbd.service
    systemctl disable nmbd.service
fi

PASSWORD_FILE=/root/.eolead
if [ "$ad_local" = 'oui' ];
then
    MANAGER_PASSWORD=$(cat "${PASSWORD_FILE}")
    container_path=$(CreoleGet container_path_domaine)

    if [ ! -f "$container_path/etc/eole/samba4-vars.conf" ] && [ -f /usr/lib/eole/eolead.sh ];
    then
        # on est sur un Scribe
        SSHCMD="ssh -q -o LogLevel=ERROR -o StrictHostKeyChecking=no"
        function CreoleRun () {
            $SSHCMD root@addc "$1"
        }
    fi

    user_exists() {
        local username="${1}"
        CreoleRun "samba-tool user show ${username}" domaine > /dev/null 2>&1
    }

    if [ ! -s "${PASSWORD_FILE}" ]
    then
        EchoRouge "Le fichier de mot de passe '${PASSWORD_FILE}' n’existe pas"
    else
        if ! user_exists "$ad_user"
        then
            echo "Ajout du compte '$ad_user'... "
            CreoleRun "samba-tool user create --random-password $ad_user" domaine
        fi

        echo "Mise en conformité de l’utilisateur '$ad_user'... "
        CreoleRun "samba-tool user setexpiry $ad_user --noexpiry" domaine
        CreoleRun "samba-tool user setpassword $ad_user --newpassword='${MANAGER_PASSWORD}'" domaine
        CreoleRun "samba-tool group addmembers 'Domain Admins' $ad_user" domaine >/dev/null 2>&1 || true
    fi
fi


sync=1
initkrb()
{
    DOMAIN="${ad_domain^^}"
    #export KRB5_TRACE=/dev/stderr 
    echo "$1" | kinit "$ad_user"@"$DOMAIN"  >/dev/null
    res="$?"
    if [ "$res" == "0" ]
    then
        systemctl stop winbind.service
        systemctl stop smbd.service
        rm -rf /var/lib/samba/winbindd_privileged
        net cache flush
        rm -f /var/lib/samba/winbindd*.tdb
        rm -f /var/lib/samba/group_mapping.ldb
        rm -rf /var/cache/samba/*

        net ads join -S "$ad_server_fullname" -U "$ad_user@$DOMAIN" --use-krb5-ccache=FILE:/tmp/krb5cc_0 --use-kerberos=required --name-resolve=host
        res="$?"
        if [ "$res" == "0" ]
        then
            sync=0
        else
            echo "Ticket Kerberos valide, la jonction au serveur Samba a échoué"
            return 4
        fi
        systemctl start smbd.service
        systemctl start winbind.service
    else
        echo "Mauvais mot de passe administrateur du domaine"
        return 1
    fi
}

if [ "$1" == 'instance' ];
then
    tcpcheck 3 "$ad_address:88" > /dev/null
    res="$?"
    if [ "$res" != "0" ]
    then
        echo
        EchoRouge "Impossible de joindre le serveur Kerberos"
        echo
        exit 1
    fi
    for (( i=1; i<=3 ; i++ )); do
        echo
        EchoCyan "Intégration au domaine Active Directory"
        if [ "$ad_local" = "non" ];
        then
            echo -n "Mot de passe de l'utilisateur $ad_user pour le domaine ${ad_domain^^} (attention le mot de passe est sauvegardé dans le fichier $PASSWORD_FILE) : "
            read -r -s passwd
            echo "$passwd" > "$PASSWORD_FILE"
        else
            passwd="$MANAGER_PASSWORD"
        fi
        echo
        initkrb "$passwd"
        case $? in
            0) break;;
            4) i=3;;
        esac
    done
    if [ "$i" -eq 4 ];
    then
        echo
        EchoRouge "Impossible d'effectuer l'intégration au domaine"
        echo
        exit 1
    fi
else
    tcpcheck 3 "$ad_address":88 > /dev/null
    res="$?"
    if [ "$res" != "0" ]
    then
        EchoOrange "Serveur Kerberos impossible à joindre"
    elif [ -f "$PASSWORD_FILE" ];
    then
        passwd="$(cat "$PASSWORD_FILE")"
        initkrb "$passwd"
        res="$?"
        if [ "$res" -ne "0" ]
        then
            echo
            EchoRouge "Erreur de récupération du ticket Kerberos"
            echo "Il est nécessaire de relancer la procédure d'instanciation"
            echo
            exit 1
        fi
    else
        echo
        EchoRouge "Le mot de passe Active Directory n'est pas paramétré"
        echo "Il est nécessaire de relancer la procédure d'instanciation"
        echo
        exit 1
    fi
fi

# Mise à jour du mot de passe AD dans /etc/lsc/lsc.xml et smbldap_bind.conf
echo "Mise à jour du mot de passe dans les fichiers de configuration"
systemctl stop eole-wait-addc
systemctl stop eole-lsc
passwdrecode=$(echo "$passwd" | recode ascii..html)
sed "22c\      <password>$passwdrecode</password>" </etc/eole/lsc.xml >/etc/lsc/lsc.xml
sed -i "15c\adpassword = \"$passwd\";" /etc/smbldap-tools/smbldap_bind.conf

if [ "$sync" -eq 0 ];then
    echo
    EchoCyan "Synchronisation ldap"
    lsc -f /etc/lsc -s all -t1 | grep -v "perhaps the operation would have been completed$"
    if [ "$ad_multietab" = "oui" ];
    then
        /usr/sbin/checkmultietab
    fi
    echo
fi
if [ "$ad_local" = "oui" ];
then
    systemctl enable eole-wait-addc
    systemctl start eole-wait-addc eole-lsc
else
    systemctl disable eole-wait-addc
    systemctl start eole-lsc
fi

exit 0
