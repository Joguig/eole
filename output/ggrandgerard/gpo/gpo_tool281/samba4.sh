#!/bin/bash
# -*- shell-script -*-

# shellcheck disable=SC1091
. /usr/lib/eole/ihm.sh

#
# affecte une valeur à la variable TEMP_PASSWORD
#

function areValidCredentials()
{
    # distant authenticated call to DC with submited credentials
    # net rpc info rather than net ads status because kerberos ticket not acquired yet
    local context="$1"
    local account="$2"
    local password="$3"
    local server="$4"

    for addr in $server
    do
        if net rpc info -U "${account}%${password}" -I "$addr" 2> /dev/null > /dev/null
        then
            return 0
        fi
    done
    return 1
}

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

    if systemctl is-active samba-ad-dc >/dev/null
    then
        echo "- Stop samba-ad-dc"
        systemctl stop samba-ad-dc
    fi
    if systemctl is-active smbd >/dev/null
    then
        echo "- Stop smbd"
        systemctl stop smbd
    fi
    if systemctl is-active nmbd >/dev/null
    then
        echo "- Stop nmbd"
        systemctl stop nmbd
    fi
    if systemctl is-active winbind >/dev/null
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
    # shellcheck disable=SC2153
    if [ "${AD_SERVER_ROLE}" == "controleur de domaine" ]
    then
        echo "Redémarrage Service Samba DC"
        service samba-ad-dc restart
    else
        echo "Redémarrage Services Samba Membre"
        systemctl is-active nmbd >/dev/null && service nmbd restart
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

    if [ ! -f /usr/share/eole/backend/creation-prof.py ]; then
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
    fi

    update_or_create_zones_dns

    update_or_create_dns

    create_gpo_account

    add_reference_domain

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

    if [ "${AD_DC_SYSVOL_TYPE}" = "windows" ]
    then
        echo "Le DC ${AD_DC_SYSVOL_REF} est déclaré comme 'windows' : pas d'échange de clefs."
    else
        echange_ssh_key || retval=$?
        if [ $retval -ne 0 ]
        then
            EchoRouge "Erreur lors de l'échange des clés SSH. Relancez 'instance'"
            return $retval
        fi
    fi

    echo "Jonction au domaine"
    local valid_credentials=1
    local ad_delegation_tmp="${AD_ADMIN}"
    while [ "$valid_credentials" -ne 0 ]
    do
        read -r -p "Compte pour joindre le serveur au domaine [${ad_delegation_tmp}] : " AD_DELEGATION
        echo
        if [ -z "${AD_DELEGATION}" ]
        then
            AD_DELEGATION="${ad_delegation_tmp}"
        else
            ad_delegation_tmp="$AD_DELEGATION"
        fi
        local prompt_base='Mot de passe de jonction au domaine'
        local prompt="${prompt_base:-Saisie du mot de passe}"
        read -r -s -p "${prompt} : " AD_DELEGATION_PASSWORD
        if areValidCredentials "$AD_DC_SYSVOL_TYPE" "$AD_DELEGATION" "$AD_DELEGATION_PASSWORD" "$AD_DC_SYSVOL_REF"
        then
            valid_credentials=0
            unset ad_delegation_tmp
        else
            echo
            EchoRouge "Credentials could not be checked"
        fi
	echo
    done
    stop_samba

    local ARGUMENT_BACKEND_STORE
    local ARGUMENT_PLAINTEXT_SECRETS
    local ARGUMENT_SITE
    local ARGUMENT_SERVER

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

    # TODO: c'est pas top, car le server SYSVOL pourrait être un windows alors que les DC pourraient être que des Samba/EOLE
    if [ "${AD_DC_SYSVOL_TYPE}" = "windows" ]
    then
        echo "Le DC ${AD_DC_SYSVOL_REF} est déclaré comme 'windows' : pas d'arguments server."
    else
        # Find primary DC to force join target
        AD_RID_MASTER="$(ssh_on_dc "samba-tool fsmo show" | perl -n -e '/RidAllocationMasterRole owner: CN=NTDS Settings,CN=(.+),CN=Servers/ && print $1')"
        ARGUMENT_SERVER="--server=$AD_RID_MASTER"
        echo "Attention: Join with server '${AD_RID_MASTER}'"
    fi

    # https://wiki.samba.org/index.php?title=Joining_a_Samba_DC_to_an_Existing_Active_Directory&diff=next&oldid=15757
    # Jonction to the AD
    # shellcheck disable=SC2086
    if ! samba-tool domain join "${AD_REALM}" "${AD_SERVER_MODE}DC" \
         --dns-backend="${AD_DNS_BACKEND}" \
         -U"${AD_DELEGATION}%${AD_DELEGATION_PASSWORD}" \
         --realm="${AD_REALM^^}" \
         -W "${AD_DOMAIN}" \
         ${ARGUMENT_SERVER} \
         ${ARGUMENT_BACKEND_STORE} \
         ${ARGUMENT_PLAINTEXT_SECRETS} \
         ${ARGUMENT_SITE}
    then
        echo "Impossible de joindre le DC à l'annuaire existant"
        samba_init_additional
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
        # In reality, Samba could in fact join and pretend it ran the correct functional level, but this has security consequences and is not generally considered safe.
        # The advice is to downgrade the forest (and domain) functional level on the Windows DC to 2008 R2
        # (and turn off all the associated features in 2012) before joining Samba.
        echo "Le DC ${AD_DC_SYSVOL_REF} est déclaré comme 'windows' : pas de workaround à éxecuter."
    else
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

    update_system_account "gpo-${AD_HOST_NAME}"
    # le group GpoAdmins a été crée à l'instance du 1er dc
    samba-tool group addmembers "GpoAdmins" "gpo-${AD_HOST_NAME}"

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

    local IP_SERVER
    if [[ ! -z "${FORCE_DC_IP_SERVER}" ]]; then
        IP_SERVER=${FORCE_DC_IP_SERVER}
    else
        IP_SERVER=$(host "${AD_REALM}" | cut -d" " -f4 | head -n1)
    fi

    echo "Jonction au domaine"
    local valid_credentials=1
    if [ -f /etc/eole/private/eole-seth-education.password ]; then
        AD_DELEGATION='eole-seth-education'
        AD_DELEGATION_PASSWORD=$(cat /etc/eole/private/eole-seth-education.password)
        if areValidCredentials "$AD_DC_SYSVOL_TYPE" "$AD_DELEGATION" "$AD_DELEGATION_PASSWORD" "$IP_SERVER"
        then
            valid_credentials=0
        fi
    fi
    local ad_delegation_tmp="${AD_ADMIN}"
    while [ "$valid_credentials" -ne 0 ]
    do
        read -r -p "Compte pour joindre le serveur au domaine [${ad_delegation_tmp}] : " AD_DELEGATION
        if [ -z "${AD_DELEGATION}" ]
        then
            AD_DELEGATION="${ad_delegation_tmp}"
        else
            ad_delegation_tmp="$AD_DELEGATION"
        fi
        local prompt_base='Mot de passe de jonction au domaine'
        local prompt="${prompt_base:-Saisie du mot de passe}"
        read -r -s -p "${prompt} : " AD_DELEGATION_PASSWORD
        if areValidCredentials "$AD_DC_SYSVOL_TYPE" "$AD_DELEGATION" "$AD_DELEGATION_PASSWORD" "$IP_SERVER"
        then
            valid_credentials=0
            unset ad_delegation_tmp
        else
            echo
            EchoRouge "Credentials could not be checked"
        fi
	echo
    done

    if ! net ads join -U"${AD_DELEGATION}%${AD_DELEGATION_PASSWORD}" -I "${IP_SERVER}"
    then
        EchoRouge "Impossible de joindre le domaine."
        exit 1
    fi

    local entreeDnsTrouvee=0
    local IP_DNS_LISTE
    local IP_DNS
    declare -a IP_DNS_LISTE

    if [ -n "${FORCE_IP_DNS_LISTE}" ]
    then
	IP_DNS_LISTE=("${FORCE_IP_DNS_LISTE[@]}")
    else
	# shellcheck disable=SC2207
	IP_DNS_LISTE=( $(host "${AD_REALM}" | cut -d" " -f4) )
    fi

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
                echo "Impossible d'inscrire l'entrée DNS"
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
        if [ "${AD_SERVER_ROLE}" == "controleur de domaine" ] \
               && [ "${AD_ADDITIONAL_DC=}" == "non" ]; then
            pdbedit -h "\\\\${AD_HOST_NAME}.${AD_REALM}\\admin" -D 'U:' admin > /dev/null
        fi
    else
        if [ "${AD_SERVER_ROLE}" == "controleur de domaine" ] \
               && [ "${AD_ADDITIONAL_DC=}" == "non" ] \
               && [ -n "${AD_HOMES_SHARE_HOST_NAME}" ]; then
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
            systemctl restart named
        fi
    fi
}

function samba_create_profiles_dir()
{
    if [ "${ACTIVER_AD_PROFILES_SHARE}" == "oui" ]; then
        mkdir -p "${AD_PROFILE_SHARE_PATH}"
        setfacl -Rbk "${AD_PROFILE_SHARE_PATH}"
        setfacl -m g:"${AD_REALM}/domain users":rwx "${AD_PROFILE_SHARE_PATH}"
        if [ "${AD_SERVER_ROLE}" == "controleur de domaine" ] \
               && [ "${AD_ADDITIONAL_DC=}" == "non" ]; then
            pdbedit -p "\\\\${AD_HOST_NAME}.${AD_REALM}\\profiles\\admin" admin > /dev/null
        fi
    else
        if [ "${AD_SERVER_ROLE}" == "controleur de domaine" ] \
               && [ "${AD_ADDITIONAL_DC=}" == "non" ] \
               && [ -n "${AD_PROFILES_SHARE_HOST_NAME}" ]; then
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
    mkdir -p /var/lib/samba/private/managed_account
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
    samba_init_pre
    case "${AD_SERVER_ROLE}" in
        "controleur de domaine")
            samba_migrate_dns
            # shellcheck disable=SC2119
            check_certificat_samba
            update_or_create_zones_dns
            update_or_create_dns
            create_gpo_account
            update_system_accounts
            add_reference_domain
            echo "* Active Directory est initialisé, reload la configuration"
            smbcontrol all reload-config
            ;;

        "membre")
            update_system_accounts
            echo "* Le membre est join, reload la configuration"
            smbcontrol all reload-config
            ;;

        *)
            EchoRouge "Server Role inconnu : '${AD_SERVER_ROLE}'"
            exit 1
            ;;
    esac

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

#
# créer ou mets à jour une Zone DNS Inverse
#
function update_or_create_zone_dns()
{
    local ZONE
    ZONE="${1}"
    if [ -z "$ZONE" ]
    then
        return 0
    fi
    if ! samba-tool dns zoneinfo "${AD_HOST_IP}" "${ZONE}.in-addr.arpa" -P 1>/dev/null 2>&1
    then
        echo "   Zone : ${ZONE}.in-addr.arpa a créer"
        samba-tool dns zonecreate "${AD_HOST_IP}" "${ZONE}.in-addr.arpa" -P
    else
        echo "   Zone : ${ZONE}.in-addr.arpa existe déjà"
    fi
}

#
# calcul la zone ou les zones d'après le IP et le MASK
#
function compute_zones()
{
    local IP
    local MASK
    IP="$1"
    MASK="$2"

    IFS=. read -r i1 i2 i3 i4 <<< "${IP}"

    #IFS=. read -r i1 i2 i3 i4 m1 m2 m3 m4 <<< "${IP}.${MASK}"
    #echo "MASK = $MASK" >&2
    #echo "network:   $((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$((i4 & m4))" >&2
    #echo "broadcast: $((i1 & m1 | 255-m1)).$((i2 & m2 | 255-m2)).$((i3 & m3 | 255-m3)).$((i4 & m4 | 255-m4))" >&2
    #echo "first IP:  $((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$(((i4 & m4)+1))" >&2
    #echo "last IP:   $((i1 & m1 | 255-m1)).$((i2 & m2 | 255-m2)).$((i3 & m3 | 255-m3)).$(((i4 & m4 | 255-m4)-1))" >&2
    cdr=$(mask2cdr "$MASK")
    cdr8=$(( cdr / 8 ))
    #echo "cdr=$cdr cdr8=$cdr8" >&2
    case $cdr8 in
        1) echo "$i1";;
        2) echo "$i2.$i1";;
        3) echo "$i3.$i2.$i1";;
        4) echo "$i4.$i3.$i2.$i1";;
        *) # dans les autres cas, pas de zone !
            echo  "";;
    esac
}

#
# update or create zones dns inversées
#
function update_or_create_zones_dns()
{
    if [ "${ACTIVER_AD_ZONES}" == "non" ];
    then
        echo "Gestion des Zones DNS Inversées désactivée."
        return 0
    fi

    echo "Gestion des Zones DNS Inversées"
    if [ "${AD_ZONES_DEFAUT}" == "oui" ];
    then
        ZONE=$(compute_zones "${AD_HOST_IP}" "${AD_HOST_NETMASK}")
        update_or_create_zone_dns "${ZONE}"

        dc4=$(cut -d. -f 4 <<<"$AD_HOST_IP" )
        if ! samba-tool dns query "${AD_HOST_IP}" "${ZONE}.in-addr.arpa" "$dc4" PTR -P 1>/dev/null 2>/dev/null
        then
            #Usage: samba-tool dns add <server> <zone> <name> <A|AAAA|PTR|CNAME|NS|MX|SRV|TXT> <data>
            if samba-tool dns add "${AD_HOST_IP}" "${ZONE}.in-addr.arpa" "$dc4" PTR "${AD_HOST_NAME}.${AD_REALM}."  -P
            then
                echo "   Création entrée PTR pour ${AD_HOST_IP} ok"
            else
                echo "   Création entrée PTR pour ${AD_HOST_IP} : erreur !"
                # c'est pas grave... au prochain reconfigure !
            fi
        else
            echo "   Entrée PTR pour ${AD_HOST_IP} existe."
        fi
    else
        echo "   Pas de gestion des zones par défaut."
    fi
    if [ -n "${AD_ZONES}" ]
    then
        #echo "Zone déclarées : ${AD_ZONES}"
        for ZONE in ${AD_ZONES}
        do
            update_or_create_zone_dns "${ZONE}"
        done
    fi
    return 0
}

#
# update or create zones dns inversées
#
function update_or_create_dns()
{
    echo "Gestion des DNS"
    for dns in isatap wpad
    do
        if ! samba-tool dns query "${AD_HOST_IP}" "${AD_REALM}" "${dns}" A -P 1>/dev/null 2>/dev/null
        then
            #Usage: samba-tool dns add <server> <zone> <name> <A|AAAA|PTR|CNAME|NS|MX|SRV|TXT> <data>
            if samba-tool dns add "${AD_HOST_IP}" "${AD_REALM}" "${dns}" A "127.0.0.1"  -P
            then
                echo "   Création entrée A pour ${dns} ok"
            else
                echo "   Création entrée A pour ${dns} : erreur !"
                # c'est pas grave... au prochain reconfigure !
            fi
        else
            echo "   Entrée A pour ${dns} existe."
        fi
    done
    return 0
}

#
# get the password file for service account
#
function get_passwordfile_for_account()
{
    local account
    account="${1}"
    echo "/var/lib/samba/private/managed_account/${account}.pwd"
}

#
# get the keytab file for service account
#
function get_keytabfile_for_account()
{
    local account
    account="${1}"
    echo "/var/lib/samba/private/managed_account/${account}.keytab"
}

#
# update local system account
#
# Attention: ce code peut être appelé depuis instance ou reconfigure !
#
function update_system_account()
{
    local sevenDaysBefore
    local file_time
    local account
    local NEWPASSWORD

    account="${1}"
    if [ -z "${account}" ]
    then
        return
    fi
    passwordFile=$(get_passwordfile_for_account "${account}")
    keytabFile=$(get_keytabfile_for_account "${account}")

    [ -d /var/lib/samba/private/managed_account ] || mkdir -p /var/lib/samba/private/managed_account

    if samba-tool user show "${account}" >/dev/null 2>&1
    then
        # les mots de passe sont mis à jour si plus de 7 jours
        # rappel: la régle par default est de 42 jours.
        current_time=$( date +%s )
        sevenDaysBefore=$(( current_time - ( 60 * 60 * 24 * 7 ) ))
        if [ -f "$passwordFile" ]
        then
            file_time=$(stat --format='%Y' "$passwordFile")
        else
            # hum... le fichier n'existe plus ! je force la recréation
            file_time=0
        fi
        if (( file_time < sevenDaysBefore ))
        then
            # j'utilise la fonction pwgen S=--secure N=--numerals C=--capitalize 1=one line, 42=42 chars
            NEWPASSWORD="$(pwgen -scn1 42)"

            # update
            samba-tool user setpassword "${account}" --newpassword="${NEWPASSWORD}"
            printf "%s" "${NEWPASSWORD}" >"${passwordFile}"
            samba-tool domain exportkeytab "${keytabFile}" --principal="${account}@${AD_REALM^^}" -P
        fi
    else
        # j'utilise la fonction pwgen S=--secure N=--numerals C=--capitalize 1=one line, 42=42 chars
        NEWPASSWORD="$(pwgen -scn1 42)"
        
        #create 
        if samba-tool user create "${account}" "${NEWPASSWORD}"
        then
            touch "${passwordFile}"
            chmod 600 "${passwordFile}"         
            printf "%s" "${NEWPASSWORD}" >"${passwordFile}"
            samba-tool domain exportkeytab "${keytabFile}" --principal="${account}@${AD_REALM^^}" -P
        fi
    fi
}   


#
# open a kerberos session for an account
#
function kinit_for_account()
{
    local account
    account="${1}"
    if [ -z "${account}" ]
    then
        # bizarre, je renvoi rien !
        return
    fi
    keytabFile=$(get_keytabfile_for_account "${account}")
    kinit "${account}@${AD_REALM^^}" -k -t "${keytabFile}"
}

# update all system accounts
#
function update_system_accounts()
{
    local account
    
    [ -d /var/lib/samba/private/managed_account ] || mkdir -p /var/lib/samba/private/managed_account    
    find /var/lib/samba/private/managed_account -name '*.pwd' | while read -r  pwdFile
    do
        account=$(basename "$pwdFile" .pwd)
        update_system_account "${account}"
    done
}


function create_gpo_account()
{
    if ! samba-tool group show GpoAdmins >/dev/null 2>&1   
    then
        samba-tool group add GpoAdmins
        # TODO : à améliorer !
        samba-tool group addmembers "Domain Admins" GpoAdmins   
    fi

    update_system_account "gpo-${AD_HOST_NAME}"

    if ! samba-tool group listmembers GpoAdmins | grep -q "gpo-${AD_HOST_NAME}"
    then
        samba-tool group addmembers GpoAdmins "gpo-${AD_HOST_NAME}"
    fi
}

function add_reference_domain()
{
    local ConfigurationLdb
    ConfigurationLdb='/var/lib/samba/private/sam.ldb'
    for obj in DomainDnsZones ForestDnsZones; do
        dn=$(ldbsearch -H "$ConfigurationLdb" --cross-ncs "(dnsroot=${obj}.${AD_REALM})" dn|grep "^dn: " | cut -d" " -f2)
        # shellcheck disable=SC2091
        if ! $(ldbsearch -H "$ConfigurationLdb" -b "$dn" msDS-SDReferenceDomain|grep -q "^msDS-SDReferenceDomain: "); then
            cat >/tmp/referencedomain.ldif <<EOF
dn: $dn
changetype: modify
add: msDS-SDReferenceDomain
msDS-SDReferenceDomain: CN=Configuration,${BASEDN}
EOF
            ldbmodify -v -H "$ConfigurationLdb" /tmp/referencedomain.ldif
            rm -f /tmp/referencedomain.ldif
        fi
    done
}

# shellcheck disable=SC2120
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

function workaround_policies()
{
    # nettoyage Policy non détruites
    cd "/home/sysvol/${AD_REALM}/Policies" || return 11
    for ID in "{"*
    do
        if [ "$ID" == "{6AC1786C-016F-11D2-945F-00C04FB984F9}" ] || [ "$ID" == "{31B2F340-016D-11D2-945F-00C04FB984F9}" ]
        then
            # protection
            continue
        fi
        if ! samba-tool gpo show  "$ID" -k 1 -U"${CREDENTIAL}" -H "ldap://${AD_HOST_NAME}.${AD_REALM}" 1>/dev/null 2>&1
        then
            if [ -n "$ID" ] # protection avant rm !
            then
                echo "* Suppression GPO '$ID' inconnu"
                rm -rf "/home/sysvol/${AD_REALM}/Policies/$ID/"
            fi
        fi
    done 
}

function workaround_sysvol()
{
    ## si le SYSVOL est présent ==> check + reset si besoin
    SYSVOL_PATH=$(samba-tool testparm --suppress-prompt --section-name sysvol --parameter-name='path' 2>/dev/null)
    if [ -n "$SYSVOL_PATH" ]
    then
        if [ -d "$SYSVOL_PATH" ]
        then
            if samba-tool ntacl sysvolcheck 2>/dev/null
            then
                echo "Check sysvol ACL : Ok"
            else
                echo "Check sysvol ACL NOK, do sysvolreset, please wait ..."
                if samba-tool ntacl sysvolreset 2>/dev/null
                then
                    echo "Reset sysvol ACL OK"
            else
                    echo "Reset sysvol ACL NOK"
                fi
            fi
        fi
    fi
    
}

function samba_delete_gpo()
{
    local GPONAME="$1"
    
    echo "* Supprime GPO $GPONAME"
    if [ -z "$GPONAME" ]
    then
        echo "Usage: samba_delete_gpo <gpo_name>"
        return 1
    fi
    
    if [ "${AD_SERVER_ROLE}" != "controleur de domaine" ]
    then
        echo "Cette commande ne doit pas être éxecutée sur les serveurs membres."
        return 1
    fi
    
    if [ "${AD_ADDITIONAL_DC}" != "non" ]
    then
        echo "Cette commande ne doit pas être éxecutée sur les Dc Secondaires."
        return 2
    fi
    
    GPO_ADMIN="gpo-${AD_HOST_NAME}"
    GPO_ADMIN_DN="${GPO_ADMIN}@${AD_REALM^^}"
    GPO_ADMIN_PWD_FILE=$(get_passwordfile_for_account "${GPO_ADMIN}")
    ADMIN_PWD="$(cat "${GPO_ADMIN_PWD_FILE}")"
    CREDENTIAL="${GPO_ADMIN_DN}%${ADMIN_PWD}"
    GPO_ADMIN_KEYTAB_FILE=$(get_keytabfile_for_account "${GPO_ADMIN}")
    if [ ! -f "${GPO_ADMIN_PWD_FILE}" ]
    then
        echo "Warning:Le fichier ${GPO_ADMIN_PWD_FILE} est manquant"
        return 3
    fi
    if [ ! -f "${GPO_ADMIN_KEYTAB_FILE}" ]
    then
        echo "Warning:Le fichier ${GPO_ADMIN_KEYTAB_FILE} est manquant"
        return 4
    fi
    
    if ! kinit "${GPO_ADMIN_DN}" -k -t "${GPO_ADMIN_KEYTAB_FILE}"
    then
        echo "Impossible de créer une session kerberos."
        return 5
    fi
    
    if gpo-tool helper show_by_name "$GPONAME" --attribut name -k 1 -H "ldap://${AD_HOST_NAME}.${AD_REALM}" -U"$CREDENTIAL" 2>/dev/null 
    then
        gpo-tool helper delete_by_name "$GPONAME" -k 1 -H "ldap://${AD_HOST_NAME}.${AD_REALM}" -U"$CREDENTIAL" 1>/dev/null
        CDU="$?"
    else
        CDU="0"
    fi
    workaround_policies
    
    kdestroy || /bin/true
    return "$CDU" 
}

function samba_import_gpo_clean_after()
{
    if [ -d "/var/tmp/$GPONAME" ]
    then
        # sécurité, vide ne devrait jamais arrivé
        if [ -n "$GPONAME" ]
        then
            /bin/rm -rf "/var/tmp/$GPONAME"
        fi 
    fi
    kdestroy || /bin/true
}

function samba_import_gpo()
{
    local GPONAME="$1"
    local SOURCE="$2"
    local DN_TO_LINK="$3"
    local SOURCE_TMP=""
    
    echo "* Import GPO $GPONAME from export $SOURCE"
    if [ -z "$GPONAME" ]
    then
        echo "Usage: samba_import_gpo <gpo_name> <export_gpos.tar.gz|folder> [<dn_to_link>]]"
        return 1
    fi

    if [ "${AD_SERVER_ROLE}" != "controleur de domaine" ]
    then
        echo "Cette commande ne doit pas être éxecutée sur les serveurs membres."
        return 1
    fi
    
    if [ "${AD_ADDITIONAL_DC}" != "non" ]
    then
        echo "Cette commande ne doit pas être éxecutée sur les Dc Secondaires."
        return 2
    fi
    
    GPO_ADMIN="gpo-${AD_HOST_NAME}"
    GPO_ADMIN_DN="${GPO_ADMIN}@${AD_REALM^^}"
    GPO_ADMIN_PWD_FILE=$(get_passwordfile_for_account "${GPO_ADMIN}")
    ADMIN_PWD="$(cat "${GPO_ADMIN_PWD_FILE}")"
    CREDENTIAL="${GPO_ADMIN_DN}%${ADMIN_PWD}"
    GPO_ADMIN_KEYTAB_FILE=$(get_keytabfile_for_account "${GPO_ADMIN}")
    if [ ! -f "${GPO_ADMIN_PWD_FILE}" ]
    then
        echo "Warning:Le fichier ${GPO_ADMIN_PWD_FILE} est manquant"
        return 3
    fi
    if [ ! -f "${GPO_ADMIN_KEYTAB_FILE}" ]
    then
        echo "Warning:Le fichier ${GPO_ADMIN_KEYTAB_FILE} est manquant"
        return 4
    fi
    if ! kinit "${GPO_ADMIN_DN}" -k -t "${GPO_ADMIN_KEYTAB_FILE}"
    then
        echo "Impossible de créer une session kerberos."
        return 5
    fi
    
    if [ ! -f "$SOURCE" ]
    then
        if [ ! -d "$SOURCE" ]
        then
            # ce n'est pas un fichier, ni un dossier
            echo "Usage: samba_import_gpo <gpo_name> <export_gpos.tar.gz|folder> [<dn_to_link>]"
            samba_import_gpo_clean_after
            return 1
        fi
        # SOURCE est un dossier
    else
        # SOURCE est un fichier
        SOURCE_TMP="/var/tmp/$GPONAME"
        if [ ! -d "$SOURCE_TMP" ]
        then
            mkdir "$SOURCE_TMP"
        fi
        if ! pushd "$SOURCE_TMP" >/dev/null 
        then
            echo "Impossible de changer de répertoire $SOURCE_TMP"
            samba_import_gpo_clean_after
            return 6
        fi
        if ! tar xf "$SOURCE"
        then
            echo "Impossible d'extraire le fichier '$SOURCE', est-ce un tar.gz ?"
            samba_import_gpo_clean_after
            return 6
        fi
        if ! popd >/dev/null
        then
            echo "Impossible de restaurer le répertoire initial"
            samba_import_gpo_clean_after
            return 6
        fi
        # ok, change SOURCE vers le dossier tmp
        SOURCE="$SOURCE_TMP"
    fi

    if [ ! -d "$SOURCE/policy" ]
    then
        echo "Le format de l'archive de la GPO n'est pas correcte. il manque le répertoire 'policy'."
        samba_import_gpo_clean_after
        return 7
    fi
    
    echo "* Fix netlogon"
    gpo-tool helper fix_netlogon_scripts_acl -k 1  -H "ldap://${AD_HOST_NAME}.${AD_REALM}" -U"$CREDENTIAL" 
    
    if GPOID=$(gpo-tool helper show_by_name "$GPONAME" --attribut name -k 1 -H "ldap://${AD_HOST_NAME}.${AD_REALM}" -U"$CREDENTIAL" 2>/dev/null)
    then
        if [ ! -f "/var/tmp/gpo-script/update_$GPONAME" ]
        then
            echo "* $GPONAME $GPOID existe, stop."
            samba_import_gpo_clean_after
            return 0
        fi
        echo "* $GPONAME $GPOID existe, rebuild demandé"
        /bin/rm "/var/tmp/gpo-script/update_$GPONAME"
         
        if ! gpo-tool helper delete_by_name "$GPONAME" -k 1 -H "ldap://${AD_HOST_NAME}.${AD_REALM}" -U"$CREDENTIAL"
        then
            echo "* Delete '$GPONAME' Erreur"
            # j'ignore si elle a déjà été supprimée !
        else
            echo "* Delete '$GPONAME' OK"
        fi
    fi
    
    echo "* Import GPO"
    if ! samba-tool gpo restore -k 1 -H "ldap://${AD_HOST_NAME}.${AD_REALM}" -U"${CREDENTIAL}" "$GPONAME" "$SOURCE/policy" --restore-metadata
    then
        echo "* $GPONAME : restauration impossible !"
        samba_import_gpo_clean_after
        return 8
    fi
    # check
    if ! GPOID=$(gpo-tool helper show_by_name "$GPONAME" --attribut name -k 1 -H "ldap://${AD_HOST_NAME}.${AD_REALM}" -U"$CREDENTIAL" )
    then
        echo "* $GPONAME impossible de créer la GPO !"
        samba_import_gpo_clean_after
        return 9 
    fi
    
    if [ -f "$SOURCE/ldif" ]
    then
        VERSION_AD=$(gpo-tool helper show_by_name "$GPONAME" --attribut versionNumber -k 1 -H "ldap://${AD_HOST_NAME}.${AD_REALM}" -U"$CREDENTIAL" )
        VERSION_EXPORT=$(awk -F": " '/versionNumber/ {print $2;}' <"$SOURCE/ldif")
        if [ "$VERSION_AD" == "$VERSION_EXPORT" ]
        then
            echo "* Version ok"
        else
            echo "* Version différente, positionne à ${VERSION_EXPORT}"
            cat >/tmp/gpoUpdate.ldif <<EOF
dn: CN=$GPOID,CN=Policies,CN=System,$BASEDN
changetype: modify
replace: versionNumber
versionNumber: ${VERSION_EXPORT}
EOF
    
            ldbmodify -v -H "/var/lib/samba/private/sam.ldb" -U"${CREDENTIAL}" /tmp/gpoUpdate.ldif
        fi 
    fi
    
    if [ -f "$SOURCE/attr" ]
    then
        echo "* Restauration xattr"
        cd "/home/sysvol/${AD_REALM}/Policies/$GPOID" || return 1
        setfattr --restore "$SOURCE/attr" . 
    fi
    
    echo "* Fix GPO"
    gpo-tool helper fix_gpo_acl "$GPONAME" -k 1 -H "ldap://${AD_HOST_NAME}.${AD_REALM}" -U"$CREDENTIAL" 
    
    # link ?
    if [ -n "$DN_TO_LINK" ]
    then
        if ! samba-tool gpo setlink "$DN_TO_LINK" "$GPOID" -k 1 -H "ldap://${AD_HOST_NAME}.${AD_REALM}" -U"${CREDENTIAL}" >/dev/null
        then
            echo "* $GPONAME impossible de lier la GPO à $DN_TO_LINK !"
            samba_import_gpo_clean_after
            return 10 
        fi
    fi
    
    workaround_policies
    workaround_sysvol
    
    samba_import_gpo_clean_after
    return 0
}

function samba_export_gpo()
{
    local GPO_NAME="$1"
    local EXPORT_TAR_GZ="$2"
    
    if [ -z "$GPO_NAME" ]
    then
        echo "Usage: samba_export_gpo <gpo_name> [<export_gpos.tar.gz>]"
        return 1
    fi
    if [ -z "$EXPORT_TAR_GZ" ]
    then
        EXPORT_TAR_GZ="/usr/share/eole/gpo/${GPO_NAME}.tar.gz"
    fi    
    if [ -f "$EXPORT_TAR_GZ" ]
    then
        echo "Usage: samba_export_gpo <gpo_name> [<export_gpos.tar.gz>]"
        echo "$EXPORT_TAR_GZ existe."
        return 1
    fi
    echo "* Export GPO $GPO_NAME to $EXPORT_TAR_GZ"
    
    if [ "${AD_SERVER_ROLE}" != "controleur de domaine" ]
    then
        echo "Cette command ne doit pas être éxecutée sur les serveurs membres"
        return 0
    fi
    
    if [ "${AD_ADDITIONAL_DC}" != "non" ]
    then
        echo "Cette commande ne doit pas être éxecutée sur les Dc Secondaires."
        return 0
    fi
    
    GPO_ADMIN="gpo-${AD_HOST_NAME}"
    GPO_ADMIN_DN="${GPO_ADMIN}@${AD_REALM^^}"
    GPO_ADMIN_PWD_FILE=$(get_passwordfile_for_account "${GPO_ADMIN}")
    if [ ! -f "${GPO_ADMIN_PWD_FILE}" ]
    then
        echo "Warning:Le fichier ${GPO_ADMIN_PWD_FILE} est manquant"
        return 1
    fi
    ADMIN_PWD="$(cat "${GPO_ADMIN_PWD_FILE}")"
    CREDENTIAL="${GPO_ADMIN_DN}%${ADMIN_PWD}"
    
    GPO_ID=$(gpo-tool helper show_by_name "$GPO_NAME" --attribut name -H "ldap://${AD_HOST_NAME}.${AD_REALM}" -U"${CREDENTIAL}" )
    if [ -z "$GPO_ID" ]
    then
        echo "La GPO $GPO_NAME n'existe pas!"
        return 1
    fi
    
    rm -rf "/var/tmp/$GPO_NAME"
    mkdir -p "/var/tmp/$GPO_NAME"
    samba-tool gpo backup "$GPO_ID" --tmpdir="/var/tmp/$GPO_NAME" -d 0
    cd "/var/tmp/$GPO_NAME/policy/" || return 1
    mv "$GPO_ID/"* .
    rm -rf "/var/tmp/$GPO_NAME/policy/$GPO_ID"
    ldbsearch -H /var/lib/samba/private/sam.ldb -U"${CREDENTIAL}" CN="$GPO_ID" >"/var/tmp/$GPO_NAME/ldif"
    cd "/home/sysvol/${AD_REALM}/Policies/$GPO_ID" || return 1
    getfattr -Rd . >"/var/tmp/$GPO_NAME/attrs"
    getfacl -R . >"/var/tmp/$GPO_NAME/acls"
    find . |while read -r F ; do file "$F"; done >"/var/tmp/$GPO_NAME/encodings"
    find . |while read -r F ; do SDDL=$(samba-tool ntacl get  "$F" --as-sddl); echo "$SDDL $F"; done >"/var/tmp/$GPO_NAME/sddl"
    
    echo "${AD_DOMAIN}" >"/var/tmp/$GPO_NAME/domain"
    gpo-tool helper show_by_name "$GPO_NAME" --attribut name -H "ldap://${AD_HOST_NAME}.${AD_REALM}" -U"${CREDENTIAL}" >"/var/tmp/$GPO_NAME/version"
    samba-tool ntacl get "/home/sysvol/${AD_REALM}/Policies/$GPO_ID/" --as-sddl >"/var/tmp/$GPO_NAME/sddl.FS_GPO"
    samba-tool dsacl get --objectdn="CN=$GPO_ID,CN=Policies,CN=System,${BASEDN}"  -U"${CREDENTIAL}" | tail -1 >"/var/tmp/$GPO_NAME/sddl.DS_GPO"
    samba-tool ntacl get "/home/sysvol/${AD_REALM}/Policies/$GPO_ID/User" --as-sddl >"/var/tmp/$GPO_NAME/sddl.FS_GPO_User"
    samba-tool dsacl get --objectdn="CN=USer,CN=$GPO_ID,CN=Policies,CN=System,${BASEDN}"  -U"${CREDENTIAL}" | tail -1 >"/var/tmp/$GPO_NAME/sddl.FS_GPO_User"
    samba-tool ntacl get "/home/sysvol/${AD_REALM}/Policies/$GPO_ID/Machine" --as-sddl >"/var/tmp/$GPO_NAME/sddl.FS_GPO_Machine"
    samba-tool dsacl get --objectdn="CN=Machine,CN=$GPO_ID,CN=Policies,CN=System,${BASEDN}" -U"${CREDENTIAL}" | tail -1 >"/var/tmp/$GPO_NAME/sddl.DS_GPO_Machine"
    
    cd "/var/tmp/$GPO_NAME/" || return 1
    tar --xattrs --acls -cvf "$EXPORT_TAR_GZ" .
    ls -l "$EXPORT_TAR_GZ"
    
    echo "* Export GPO $GPO_NAME from export $EXPORT_TAR_GZ"
    return 0
}
    