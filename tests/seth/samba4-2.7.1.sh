#!/bin/bash
# -*- shell-script -*-

# shellcheck disable=SC1091
. /usr/lib/eole/ihm.sh

#
# affecte une valeur à la variable TEMP_PASSWORD
#

function getValidPassword()
{
    local prompt="${1:-Saisie du mot de passe}"
    local confirm="${2:-true}"
    local password
    local validated="False"
    local confirm_password

    while [ ${validated} != "True" ]
    do
        read -r -s -p "${prompt} : " password
        result=$(validSambaPassword "$password")
        echo

        if [ "${result}" -ne 0 ]
        then
            validated="False"
        else
            break
        fi
    done

    if [ "${confirm}" = 'false' ];then
        TEMP_PASSWORD="${password}"
        return 0
    fi

    read -r -s -p "Confirmation du mot de passe : " confirm_password
    echo

    if [ "${confirm_password}" = "${password}" ]
    then
        TEMP_PASSWORD=$password
        return 0
    else
        echo "Les mots de passe ne correspondent pas."
        echo "Veuillez recommencer"
        getValidPassword "$1"
    fi
}

#
# genere une clef SSH si elle manque
#
function check_ssh_key()
{
    [ ! -d /root/.ssh ] && mkdir -p /root/.ssh

    if [ ! -f /root/.ssh/id_rsa ]
    then
        echo "Generation de la clef SSH pour les echanges entre DC"
        ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""
    fi
}

#
# Echange la clef SSH root DC1/DC2
#
function echange_ssh_key()
{
    retval=0
    if [ -n "${AD_DC_SYSVOL_REF}" ]
    then
        if [ "${AD_DC_SYSVOL_TYPE}" = "windows" ]
        then
            echo "Le DC ${AD_DC_SYSVOL_REF} est déclaré comme 'windows', donc pas d'échange SSH !"
        else
            echo "Envoi de la clef SSH ${AD_HOST_NAME} vers le DC ${AD_DC_SYSVOL_REF}"
            ssh-copy-id -i /root/.ssh/id_rsa.pub "root@${AD_DC_SYSVOL_REF}" || retval=$?
            if [ $retval -ne 0 ]
            then
                return $retval
            fi
            scp "root@${AD_DC_SYSVOL_REF}:/root/.ssh/id_rsa.pub" /tmp/id_rsa.pub
            cat /tmp/id_rsa.pub >> /root/.ssh/authorized_keys
        fi
    fi
}

#
# Echange la clef SSH root DC1/DC2
#
function ssh_on_dc()
{
    echo "ssh_on_dc ${AD_DC_SYSVOL_REF} : $*"
    # shellcheck disable=SC2029
    ssh root@"${AD_DC_SYSVOL_REF}" "$@"
}


# Arrête tous les services liés à Samba
function stop_samba()
{
    echo "Stop Service Samba"
    smbcontrol all shutdown

    if systemctl is-active samba-ad-dc &>/dev/null
    then
        echo "- Stop samba-ad-dc"
        systemctl stop samba-ad-dc
    fi
    if systemctl is-active smbd &>/dev/null
    then
        echo "- Stop smbd"
        systemctl stop smbd
    fi
    if systemctl is-active nmbd &>/dev/null
    then
        echo "- Stop nmbd"
        systemctl stop nmbd
    fi
    if systemctl is-active winbind &>/dev/null
    then
        echo "- Stop winbind"
        systemctl stop winbind
    fi
    if pgrep ^samba$ >/dev/null
    then
        EchoRouge "- killall samba !"
        killall samba -15
    fi
    if pgrep ^smbd$ >/dev/null
    then
        EchoRouge "- killall smbd !"
        killall smbd -15
    fi
    if pgrep ^nmbd$ >/dev/null
    then
        EchoRouge "- killall nmbd !"
        killall nmbd -15
    fi
    if pgrep ^winbindd$ >/dev/null
    then
        EchoRouge "- killall winbindd !"
        killall winbindd -15
    fi
    if pgrep ^winbind$ >/dev/null
    then
        EchoRouge "- killall winbind !"
        killall winbind -15
    fi
    return 0
}

# Démarre Samba Membre et attent opérationel
function start_samba()
{
    if [ "${AD_SERVER_ROLE}" == "controleur de domaine" ]
    then
        echo "Redémarrage Service Samba DC"
        service samba-ad-dc restart
    else
        echo "Redémarrage Services Samba Membre"
        service nmbd restart
        service smbd restart
        service winbind restart

        echo "Nettoyage Cache"
        net cache flush
    fi
    wait_samba_start
}

# Le démarrage de Samba peut prendre quelques instants
# attendre que le démon ait complètement démarré
function wait_samba_start()
{
    local PORT445OK
    local PORT88OK
    echo "Waiting Samba starting"
    for i in {1..600}
    do
        sleep 1
        if [ -z "$PORT445OK" ]
        then
            if tcpcheck 1 127.0.0.1:445 |grep -q alive; then
                echo "Service SMB started after $i s"
                PORT445OK=ok
            fi
        fi
        if [ "${AD_SERVER_ROLE}" == "controleur de domaine" ]
        then
            # uniquement sur DC !
            if [ -z "$PORT88OK" ]
            then
                if tcpcheck 1 127.0.0.1:88 |grep -q alive; then
                    echo "Service Kerberos started after $i s"
                    PORT88OK=ok
                fi
            fi
        else
            # implicite que un membre
            PORT88OK=ok
        fi
        if [ "$PORT445OK" == "ok" ] && [ "$PORT88OK" == "ok" ]
        then
            break
        fi
    done
    if [ "$PORT445OK" == "ok" ] && [ "$PORT88OK" == "ok" ]
    then
        echo "Samba started"
    else
        EchoRouge "Le service samba-ad-dc n'a pas démarré dans le temps imparti"
        exit 1
    fi
}

#
# Creation d'un site, subnet et site-link
#
# Voir : https://technet.microsoft.com/fr-fr/library/cc754697.aspx
#
function samba_update_site()
{
    local site
    local subnet
    local ConfigurationLdb

    site="${1}"
    subnet="${2}"

    ConfigurationLdb=$(ls /var/lib/samba/private/sam.ldb.d/CN%3DCONFIGURATION*.ldb )
    if [ ! -f  "$ConfigurationLdb" ]
    then
        echo "Erreur, le fichier $ConfigurationLdb n'existe pas"
        exit 1
    fi

    ObjectGUID_Site=$(ldbsearch -H "$ConfigurationLdb" "(&(objectclass=site)(name=$site))" | grep objectGUID: | cut -d" " -f2)
    if [ -z "$ObjectGUID_Site" ]
    then
        samba-tool sites create "$site"
        echo "* Site $site créé"
    else
        echo "* Vérification site $site : OK, existe"
    fi

    ObjectGUID_Subnet=$(ldbsearch -H "$ConfigurationLdb" "(&(objectclass=subnet)(name=$subnet))" | grep objectGUID: | cut -d" " -f2)
    if [ -z "$ObjectGUID_Subnet" ]
    then
        samba-tool sites subnet create "$subnet" "$site"
        echo "* Subnet $subnet du site $site créé"
    else
        echo "* Vérification subnet $subnet du site $site : OK, existe"
    fi


    #entree="_ldap._tcp.${site}._sites.dc._msdcs.${AD_REALM}"
    #if ! host -t SRV "$entree" >/dev/null
    #then
    #    echo "* ERREUR: l'entré DNS '$entree' n'existe pas"
    #    #DO_UPDATE_DNS=1
    #fi
    #entree="_kerberos._tcp.${site}._sites.dc._msdcs.${AD_REALM}"
    #if ! host -t SRV "$entree" >/dev/null
    #then
    #    echo "* ERREUR: l'entré DNS '$entree' n'existe pas"
    #    #DO_UPDATE_DNS=1
    #fi
}

#
# calcul mask réseau => nb bit
# ex: 255.255.252.0 => 9
#
function mask2cdr()
{
   # Assumes there's no "255." after a non-255 byte in the mask
   local x=${1##*255.}
   set -- 0^^^128^192^224^240^248^252^254^ $(( (${#1} - ${#x})*2 )) "${x%%.*}"
   x=${1%%$3*}
   echo $(( $2 + (${#x}/4) ))
}


#
# calcul nb bit => mask réseau
# ex: 9 ==> 255.255.252.0
#
function cdr2mask()
{
   # Number of args to shift, 255..255, first non-255 byte, zeroes
   set -- $(( 5 - ($1 / 8) )) 255 255 255 255 $(( (255 << (8 - ($1 % 8))) & 255 )) 0 0 0
   if [ "$1" -gt 1 ] ;
   then
       shift "$1"
   else
       shift
   fi
   echo "${1-0}.${2-0}.${3-0}.${4-0}"
}

#
# AIM: Initialise the AD databases
#
function samba_init_ad()
{
    echo "Initialisation DC"

    check_ssh_key

    TEMP_PASSWORD=''
    if getValidPassword 'Création du mot de passe "Administrator" Active Directory'
    then
        AD_ADMIN_PASSWORD="${TEMP_PASSWORD}"
    else
        EchoRouge "Impossible d’initialiser le DC."
        exit 1
    fi

    # Updating hostname
    hostnamectl set-hostname "$(cat /etc/hostname)"

    kdestroy

    # Initialisation of the AD
    stop_samba

    # --use-rfc2307 : this argument adds POSIX attributes (UID/GID) to
    #                 the AD Schema. This will be necessary if you
    #                 intend to authenticate Linux, BSD, or OS X
    #                 clients (including the local machine) in
    #                 addition to Microsoft Windows.
    #

    mkdir -p "/var/lib/samba/private/tls"
    local ARGUMENT_DOMAIN_SID
    local ARGUMENT_BACKEND_STORE
    local ARGUMENT_PLAINTEXT_SECRETS
    if [ -n "$AD_DOMAIN_SID" ]
    then
        ARGUMENT_DOMAIN_SID="--domain-sid=${AD_DOMAIN_SID}"
        echo "Attention: positionnement du SID à l'initialisation avec ${AD_DOMAIN_SID}"
    fi

    if [ "$AD_BACKEND_STORE" != "tdb" ]
    then
        ARGUMENT_BACKEND_STORE="--backend-store=${AD_BACKEND_STORE}"
        echo "Attention: Activation backend Store avec ${AD_BACKEND_STORE}"
    fi

    if [ "$AD_PLAINTEXT_SECRETS" == "oui" ]
    then
        ARGUMENT_PLAINTEXT_SECRETS="--plaintext-secrets"
        echo "Attention: Activation Plaintext Secrets"
    fi

    mkdir -p "/var/lib/samba/private/tls"
    # shellcheck disable=SC2086
    if ! samba-tool domain provision --use-rfc2307 \
           ${ARGUMENT_DOMAIN_SID} \
           ${ARGUMENT_BACKEND_STORE} \
           ${ARGUMENT_PLAINTEXT_SECRETS} \
           --realm="${AD_REALM^^}" \
           --domain="${AD_DOMAIN^^}" \
           --adminpass="${AD_ADMIN_PASSWORD}" \
           --server-role=dc \
           --host-ip="${AD_HOST_IP}" \
           --option="bind interfaces only=yes" \
           --option="interfaces=lo ${NOM_CARTE_NIC1}"
    then
        echo "Impossible de initialiser l'annuaire Active Directory"
        exit 1
    fi

    samba_migrate_dns

    # export keytab Administrator
    [[ -f "${AD_HOST_KEYTAB_FILE}" ]] && rm "${AD_HOST_KEYTAB_FILE}"
    if ! samba-tool domain exportkeytab "${AD_HOST_KEYTAB_FILE}" --principal="${AD_HOST_NAME^^}@${AD_REALM^^}"
    then
        echo "Impossible de générer le keytab ${AD_HOST_NAME}"
        exit 1
    fi

    start_samba

    echo "Test connection kerberos/AD"
    sleep 5
    if ! kinit "${AD_HOST_NAME^^}@${AD_REALM^^}" -k -t "${AD_HOST_KEYTAB_FILE}"
    then
        echo "Connection kerberos/AD impossible"
        exit 1
    fi

    echo "Set Administrator password never expire"
    if ! samba-tool user setexpiry "${AD_ADMIN}" --noexpiry
    then
        echo "Impossible de déactiver l'expiration de mot de passe de l'Administrator"
        exit 1
    fi

    echo "Ajout SeDiskOperatorPrivilege au groupe 'Domain Admins'"
    if ! net rpc rights grant "${AD_DOMAIN^^}\Domain Admins" SeDiskOperatorPrivilege -U"${AD_ADMIN}%${AD_ADMIN_PASSWORD}"
    then
        echo "Impossible d'attribuer le privilège SeDiskOperatorPrivilege au groupe Domain Admins"
        exit 1
    fi

    #TODO : create reverse zone pour PEDAGO, ADMIN,DMZ !
    #samba-tool dns zonecreate pedago.eole.lan 2.1.10.in-addr.arpa --username=${AD_ADMIN}
    #samba-tool dns zonecreate admin.eole.lan 1.1.10.in-addr.arpa --username=${AD_ADMIN}
    #samba-tool dns zonecreate dmz.eole.lan 3.1.10.in-addr.arpa --username=${AD_ADMIN}

    #samba-tool dns zonecreate dc1.eole.lan 0.168.192.in-addr.arpa --username=${AD_ADMIN}
    #samba-tool dns add dc1.eole.lan.tld 0.168.192.in-addr.arpa 17 PTR  dc1.eole.lan.tld --username=${AD_ADMIN}

    echo "Creation utilisateur 'admin'"
    TEMP_PASSWORD=''
    if getValidPassword 'Création du mot de passe "admin" Active Directory'
    then
        ADMIN_PASSWORD="${TEMP_PASSWORD}"
        unset TEMP_PASSWORD
    else
        EchoRouge "Impossible de créer l'utilisateur \"admin\"."
        exit 1
    fi

    if ! samba-tool user create admin "$ADMIN_PASSWORD"
    then
        echo "Impossible de créer l'utilisateur admin"
        exit 1
    fi
    samba_create_homes_dir
    samba_create_profiles_dir

    if ! samba-tool group addmembers "Domain Admins" admin
    then
        echo "Impossible d'inscire admin dans le groupe Domain Admins"
        exit 1
    fi

    touch "${AD_INSTANCE_LOCK_FILE}"
}

#
# AIM: Initialise the Additional DC
#
function samba_init_additional()
{
    echo "Initialisation DC Secondaire"

    check_ssh_key

    if [ -n "${AD_DC_SYSVOL_REF}" ]
    then
        if ! grep -q "${AD_DC_SYSVOL_REF}" /etc/resolv.conf
        then
            echo "nameserver ${AD_DC_SYSVOL_REF}" >>/etc/resolv.conf
        else
            sed -i "/nameserver\s\+${AD_DC_SYSVOL_REF}/b; /nameserver\s\+/d" /etc/resolv.conf
        fi
    fi

    # Updating hostname
    hostnamectl set-hostname "$(cat /etc/hostname)"

    echange_ssh_key || retval=$?
    if [ $retval -ne 0 ]
    then
        EchoRouge "Erreur lors de l'échange des clés SSH. Relancez 'instance'"
        return $retval
    fi

    echo "Jonction au domaine"
    read -r -p "Compte pour joindre le serveur au domaine [${AD_ADMIN}] : " AD_DELEGATION
    echo
    if [ -z "${AD_DELEGATION}" ]
    then
        AD_DELEGATION="${AD_ADMIN}"
    fi

    TEMP_PASSWORD=''
    if getValidPassword 'Mot de passe de jonction au domaine' false
    then
        AD_DELEGATION_PASSWORD="${TEMP_PASSWORD}"
        unset TEMP_PASSWORD
    else
        EchoRouge "Impossible de joindre le domaine."
        exit 1
    fi

    stop_samba

    local ARGUMENT_BACKEND_STORE
    local ARGUMENT_PLAINTEXT_SECRETS
    local ARGUMENT_SITE

    if [ "$AD_BACKEND_STORE" != "tdb" ]
    then
        ARGUMENT_BACKEND_STORE="--backend-store=${AD_BACKEND_STORE}"
        echo "Attention: Activation backend Store avec ${AD_BACKEND_STORE}"
    fi

    if [ "$AD_PLAINTEXT_SECRETS" == "oui" ]
    then
        ARGUMENT_PLAINTEXT_SECRETS="--plaintext-secrets"
        echo "Attention: Activation Plaintext Secrets"
    fi

    if [ "$AD_ADDITIONAL_DC_FORCE_SITE" == "oui" ]
    then
        ARGUMENT_SITE="--site=${DC_SITE}"
        echo "Attention: Join to site '${DC_SITE}'"
    fi

    # Find primary DC to force join target
    AD_RID_MASTER="$(ssh_on_dc "samba-tool fsmo show" | perl -n -e '/RidAllocationMasterRole owner: CN=NTDS Settings,CN=(.+),CN=Servers/ && print $1')"
    echo "Use Rid Master : $AD_RID_MASTER"

    # Jonction to the AD
    # shellcheck disable=SC2086
    if ! samba-tool domain join "${AD_REALM}" "${AD_SERVER_MODE}DC" \
           --dns-backend="${AD_DNS_BACKEND}" \
           -U"${AD_DELEGATION}%${AD_DELEGATION_PASSWORD}" \
           --realm="${AD_REALM^^}" \
           --server="$AD_RID_MASTER" \
           -W "${AD_DOMAIN}" \
           ${ARGUMENT_BACKEND_STORE} \
           ${ARGUMENT_PLAINTEXT_SECRETS} \
           ${ARGUMENT_SITE}
    then
        echo "Impossible de joindre le DC à l'annuaire existant"
        exit 1
    fi

    samba_migrate_dns

    # export keytab ${AD_HOST_NAME}
    [[ -f "${AD_HOST_KEYTAB_FILE}" ]] && rm "${AD_HOST_KEYTAB_FILE}"
    if ! samba-tool domain exportkeytab "${AD_HOST_KEYTAB_FILE}" --principal="${AD_HOST_NAME^^}@${AD_REALM^^}"
    then
        echo "Impossible de générer le keytab ${AD_HOST_NAME^^}"
        exit 1
    fi

    mkdir -p /var/lib/samba/private
    if [ "${AD_DC_SYSVOL_TYPE}" = "windows" ]
    then
        echo "Le DC ${AD_DC_SYSVOL_REF} est déclaré comme 'windows' : pas de workaround à éxecuter."
    else
        # si version 4.7 : cela doit être corrigé !!! A suivre
        # https://wiki.samba.org/index.php/Verifying_and_Creating_a_DC_DNS_Record
        if [ "${AD_DC_SYSVOL_TYPE}" = "samba" ]
        then
            if [ -z "${AD_DC_SYSVOL_POST_JOIN_CMD}" ]
            then
                echo "Le DC ${AD_DC_SYSVOL_REF} est déclaré comme 'samba'. "
                echo "Il faut vérifier les entrées DNS suivant 'https://wiki.samba.org/index.php/Verifying_and_Creating_a_DC_DNS_Record' "
                echo "Executer sur le DC distant : "
                echo "   samba-tool dns add \$(hostname) ${AD_REALM} ${AD_HOST_NAME} ${AD_HOST_NAME}.${AD_REALM} A ${AD_HOST_IP} "
                echo "   ldbsearch -H /usr/local/samba/private/sam.ldb '(invocationId=*)' --cross-ncs objectguid"
                echo "Identifier le 'objectGuid' à utiliser"
                echo "   samba-tool dns add \$(hostname) _msdcs.${AD_REALM} <objectGuid> CNAME ${AD_HOST_NAME}.${AD_REALM} "
                echo "   tdbbackup -s .bak /var/lib/samba/private/idmap.ldb"
                echo "Copier /var/lib/samba/private/idmap.ldb.bak sur le serveur additionel dans /var/lib/samba/private/idmap.ldb"
                read -r -p "Taper 'entrée' une fois que les commandes ont été executées sur le DC de référence: "
            else
                ssh_on_dc "${AD_DC_SYSVOL_POST_JOIN_CMD}" "${AD_HOST_NAME}" "${AD_HOST_IP}"
                ssh_on_dc tdbbackup -s .bak /var/lib/samba/private/idmap.ldb
                scp "root@${AD_DC_SYSVOL_REF}:/var/lib/samba/private/idmap.ldb.bak" /var/lib/samba/private/idmap.ldb
            fi
        else
            # comportement par défault ==> c'est un Seth !
            # workaround samba < 4.2.0 pour https://bugzilla.samba.org/show_bug.cgi?id=10928
            ssh_on_dc /usr/share/eole/sbin/createDnsRecord "${AD_HOST_NAME}" "${AD_HOST_IP}" "${DC_SITE}" "${AD_SERVER_MODE}DC"
            # Apparemment, toujours nécessaire en 4.3
            # https://wiki.samba.org/index.php/Join_an_additional_Samba_DC_to_an_existing_Active_Directory#GID_mappings_of_built-in_groups
            ssh_on_dc tdbbackup -s .bak /var/lib/samba/private/idmap.ldb
            scp "root@${AD_DC_SYSVOL_REF}:/var/lib/samba/private/idmap.ldb.bak" /var/lib/samba/private/idmap.ldb
        fi
    fi
    [ -f /var/lib/samba/private/idmap.ldb ] && chmod 600 /var/lib/samba/private/idmap.ldb

    start_samba

    echo "Execute Synchro Sysvol"
    JobSynchroSysvol

    # Samba 4.1 : replication of the SysVol share isn't implemented. If you make any changes on that share,
    # you have to keep them in sync on all your Domain Controllers. An example, how to achieve
    # this automatically, is provided in the SysVol Replication documentation.
    # https://wiki.samba.org/index.php/Rsync_based_SysVol_replication_workaround
    ## we need rsync to create the directory structure with extended attributes
    echo "Install SysVol Replication Workaround "
    if [ ! -f /etc/cron.d/sysvol-sync ]
    then
        cat >/etc/cron.d/sysvol-sync <<EOF
*/5 * * * * root  /usr/share/eole/sbin/JobSynchroSysvol >>/var/log/samba/JobSynchroSysvol.log
EOF
    fi

    samba_create_homes_dir
    samba_create_profiles_dir
    CreoleCat -t resolv.conf
    touch "${AD_INSTANCE_LOCK_FILE}"
}

#
# AIM: Initialise a Member Server
#
function samba_init_member()
{
    echo "Initialisation Server Membre"
    stop_samba
    # Attention : https://wiki.samba.org/index.php/Setup_a_Samba_AD_Member_Server

    echo "Jonction au domaine"
    read -r -p "Compte pour joindre le serveur au domaine [${AD_ADMIN}] : " AD_DELEGATION
    echo
    if [ -z "${AD_DELEGATION}" ]
    then
        AD_DELEGATION="${AD_ADMIN}"
    fi

    TEMP_PASSWORD=''
    if getValidPassword 'Mot de passe de jonction au domaine' false
    then
        AD_DELEGATION_PASSWORD="${TEMP_PASSWORD}"
        unset TEMP_PASSWORD
    else
        EchoRouge "Sans mot de passe, impossible de joindre le domaine."
        exit 1
    fi

    local IP_SERVER
    IP_SERVER=$(host "${AD_REALM}" | cut -d" " -f4 |head ) 
    if ! net ads join -U"${AD_DELEGATION}%${AD_DELEGATION_PASSWORD}" -I "${IP_SERVER}" 
    then
        EchoRouge "Impossible de joindre le domaine."
        exit 1
    fi

    local entreeDnsTrouvee=0
    local IP_DNS_LISTE
    local IP_DNS
    declare -a IP_DNS_LISTE
    # shellcheck disable=SC2207
    IP_DNS_LISTE=( $(host "${AD_REALM}" | cut -d" " -f4) )
    for i in {1..20}
    do
        # shellcheck disable=SC2128
        for IP_DNS in ${IP_DNS_LISTE}
        do
            if dig "@${IP_DNS}" "${AD_HOST_NAME}.${AD_REALM}" | grep "${AD_HOST_IP}"
            then
                echo "Entrée DNS présente sur ${IP_DNS}, Ok"
                entreeDnsTrouvee=1
                break
            fi
        done
        if [ "$entreeDnsTrouvee" -eq 1 ]
        then
            break
        fi
        
        echo "Entrée DNS manquante, ré-essai ${i} ..."
        if ! net ads dns register "${AD_HOST_NAME}.${AD_REALM}" -U"${AD_DELEGATION}%${AD_DELEGATION_PASSWORD}"
        then
            if ! samba-tool dns add "${IP_SERVER}" "${AD_REALM}" "${AD_HOST_NAME}" A "${AD_HOST_IP}" -U"${AD_DELEGATION}%${AD_DELEGATION_PASSWORD}"
            then
                echo "Impossible d'inscrire l'entrée DNS (samba4-2.7.1.sh!)"
            fi
        fi
        echo "Pause ${i} ..."
        sleep 30
    done
    if [ $entreeDnsTrouvee -eq 0 ]
    then
        EchoRouge "L'entrée DNS de la machine n'est pas inscrite."
        exit 1
    else
        echo "Entrée DNS présente, Ok"
    fi

    start_samba

    samba_create_homes_dir
    samba_create_profiles_dir
    touch "${AD_INSTANCE_LOCK_FILE}"
}

function samba_create_homes_dir()
{
    if [ "${ACTIVER_AD_HOMES_SHARE}" == "oui" ]; then
        mkdir -p "${AD_HOME_SHARE_PATH}"
        if [ "${AD_SERVER_ROLE}" == "controleur de domaine" ] && \
           [ "${AD_ADDITIONAL_DC=}" == "non" ]; then
            pdbedit -h "\\\\${AD_HOST_NAME}.${AD_REALM}\\admin" -D 'U:' admin > /dev/null
        fi
    else
        if [ "${AD_SERVER_ROLE}" == "controleur de domaine" ] && \
           [ "${AD_ADDITIONAL_DC=}" == "non" ] && \
           [ -n "${AD_HOMES_SHARE_HOST_NAME}" ]; then
            pdbedit -h "\\\\${AD_HOMES_SHARE_HOST_NAME}.${AD_REALM}\\admin" -D 'U:' admin > /dev/null
        fi
    fi
}

function samba_migrate_dns()
{
    # switch dns backend and restart bind if interaction with Samba is needed
    if [[ "${AD_SERVER_ROLE}" = "controleur de domaine" ]]; then
        if [[ -z "${AD_SERVER_MODE}" ]]; then
            echo "* Mise à jour du backend DNS"
            if [[ "${AD_DNS_BACKEND}" = "BIND9_DLZ" ]]; then
                mkdir -p "/var/lib/samba/bind-dns"
            fi
            samba_upgradedns --dns-backend="${AD_DNS_BACKEND}"
        else
            echo "No DNS dynamic update on RODC"
        fi
        if [[ "${AD_DNS_BACKEND}" = "BIND9_DLZ" ]]; then
            systemctl restart bind9
        fi
    fi
}

function samba_create_profiles_dir()
{
    if [ "${ACTIVER_AD_PROFILES_SHARE}" == "oui" ]; then
        mkdir -p "${AD_PROFILE_SHARE_PATH}"
        setfacl -Rbk "${AD_PROFILE_SHARE_PATH}"
        setfacl -m g:"${AD_REALM}/domain users":rwx "${AD_PROFILE_SHARE_PATH}"
        if [ "${AD_SERVER_ROLE}" == "controleur de domaine" ] && \
           [ "${AD_ADDITIONAL_DC=}" == "non" ]; then
            pdbedit -p "\\\\${AD_HOST_NAME}.${AD_REALM}\\profiles\\admin" admin > /dev/null
        fi
    else
        if [ "${AD_SERVER_ROLE}" == "controleur de domaine" ] && \
           [ "${AD_ADDITIONAL_DC=}" == "non" ] && \
           [ -n "${AD_PROFILES_SHARE_HOST_NAME}" ]; then
            pdbedit -p "\\\\${AD_PROFILES_SHARE_HOST_NAME}.${AD_REALM}\\profiles\\admin" admin > /dev/null
        fi
    fi
}

#
# AIM: Initialise a standalone host
#
function samba_init_standalone()
{
    echo "Initialisation Standalone Server"

    #TODO

    touch "${AD_INSTANCE_LOCK_FILE}"
}

function samba_init_pre()
{
    mkdir -p /etc/samba/conf.d/
}

#
# AIM: Initialise AD
#
function samba_instance()
{
    if [ -e "${AD_INSTANCE_LOCK_FILE}" ]
    then
        EchoOrange "L’Active Directory est déjà initialisé, exécute reconfigure"
        samba_reconfigure
        exit 0
    fi

    samba_init_pre
    case "${AD_SERVER_ROLE}" in
        "controleur de domaine")
            if [ "${AD_ADDITIONAL_DC}" == 'non' ]
            then
                samba_init_ad
            else
                samba_init_additional
            fi
            ;;

        "membre")
            samba_init_member
            ;;

        *)
            EchoRouge "Server Role inconnu : '${AD_SERVER_ROLE}'"
            exit 1
            ;;
    esac
#    samba_init_post
}


#
# AIM: Initialise the AD databases
#
function samba_reconfigure()
{
    if [ ! -e "${AD_INSTANCE_LOCK_FILE}" ]
    then
        EchoRouge "Vous devez exécuter instance pour peupler l’Active Directory"
        exit 1
    fi

    echo "Samba/Seth reconfigure"
    echo "* Active Directory est initialisé, reload la configuration"
    smbcontrol all reload-config
    samba_migrate_dns
    check_certificat_samba 604800
    echo "Samba/Seth reconfigure end"
}

#
# clean winbind cache
#
function clean_samba_cache()
{
    stop_samba
    rm /var/cache/nscd/*
    rm /var/cache/samba/*tdb*
    start_samba
}

function check_certificat_samba()
{
    local TLS_ENABLED
    local TLS_CERTFILE
    local TLS_CAFILE
    local DO_RENEW
    local END_IN_7_DAYS

    # 7*86400 = 604800s
    # le parametre $1 permet de tester la procédure !
    END_IN_7_DAYS="${1:-604800}"
    DO_RENEW=no
    TLS_ENABLED=$(testparm -s --parameter-name='tls enabled' 2>/dev/null)
    if [ "${TLS_ENABLED^^}" = YES ]
    then
        TLS_CERTFILE=$(testparm -s --parameter-name='tls certfile' 2>/dev/null)
        if [ -f "${TLS_CERTFILE}" ]
        then
            if ! openssl x509 -enddate -noout -in "${TLS_CERTFILE}" -checkend "${END_IN_7_DAYS}" >/tmp/samba_cert.txt
            then
                DO_RENEW=yes
            fi
        fi
        TLS_CAFILE=$(testparm -s --parameter-name='tls cafile' 2>/dev/null)
        if [ -f "${TLS_CAFILE}" ]
        then
            if ! openssl x509 -enddate -noout -in "${TLS_CAFILE}" -checkend "${END_IN_7_DAYS}" >/tmp/samba_ca.txt
            then
                DO_RENEW=yes
            fi
        fi
        if [ "${DO_RENEW}" = yes ]
        then
            # je ne prends en compte que le cas "par défaut" (auto signé samba)
            if [ "${TLS_CAFILE}" = /var/lib/samba/private/tls/ca.pem ] && [ "${TLS_CERTFILE}" = /var/lib/samba/private/tls/cert.pem ]
            then
                echo "Renouvellement des certificats Samba"
                stop_samba
                if [ -f "${TLS_CAFILE}" ]
                then
                    rm -f "${TLS_CAFILE}"
                fi
                if [ -f "${TLS_CERTFILE}" ]
                then
                    rm -f "${TLS_CERTFILE}"
                fi
                TLS_KEYFILE=$(testparm -s --parameter-name='tls keyfile' 2>/dev/null)
                if [ -f "${TLS_KEYFILE}" ]
                then
                    rm -f "${TLS_KEYFILE}"
                fi
                start_samba
                # attente re génération des certificats
 			    sleep 5
            else
                echo "Attention: les certificats Samba vont expirer !"
            fi
        fi
    fi
}
