#!/bin/bash

function waitCpuUsage()
{
    local threshold=${1:-10}
    while set -- "$(cat /proc/stat)" && [ $(( ( $2 + $4 ) * 100 / ( $2 + $4 + $5 ) )) -gt "$threshold" ] ;
    do
        echo "Wait Cpu..."
        sleep 1
    done
}

function waitMaxProcessus()
{
    local max_concurrent_tasks=20
    
    declare -a PIDS
    while true
    do
        JOBS="$(jobs -p)"
        mapfile -t PIDS < <( echo "$JOBS" )
        NBPIDS="${#PIDS[@]}"
        if [ "${NBPIDS}" -lt "$max_concurrent_tasks" ]
        then
            break
        fi
        echo "Wait..."
        sleep 1 # gnu sleep allows floating point here...
    done
}

function doCreateSiteEtablissement()
{
    site="$1"
    if ! samba-tool sites create "$site" 2>/dev/null
    then
        echo "$site existe déjà"
    else
        echo "$site crée"
    fi
}


function samba_create_home()
{
    if [ "${ACTIVER_AD_HOMES_SHARE}" == "oui" ]; then
        if [ "${AD_SERVER_ROLE}" == "controleur de domaine" ] && \
           [ "${AD_ADDITIONAL_DC=}" == "non" ]; then
            pdbedit -h "\\\\${AD_HOST_NAME}.${AD_REALM}\\$1" -D 'U:' "$1" > /dev/null
        fi
    else
        if [ "${AD_SERVER_ROLE}" == "controleur de domaine" ] && \
           [ "${AD_ADDITIONAL_DC=}" == "non" ] && \
           [ -n "${AD_HOMES_SHARE_HOST_NAME}" ]; then
            pdbedit -h "\\\\${AD_HOMES_SHARE_HOST_NAME}.${AD_REALM}\\$1" -D 'U:' "$1" > /dev/null
        fi
    fi
}

function samba_create_profile()
{
    if [ "${ACTIVER_AD_PROFILES_SHARE}" == "oui" ]; then
        if [ "${AD_SERVER_ROLE}" == "controleur de domaine" ] && \
           [ "${AD_ADDITIONAL_DC=}" == "non" ]; then
            pdbedit -p "\\\\${AD_HOST_NAME}.${AD_REALM}\\profiles\\$1" "$1" > /dev/null
        fi
    else
        if [ "${AD_SERVER_ROLE}" == "controleur de domaine" ] && \
           [ "${AD_ADDITIONAL_DC=}" == "non" ] && \
           [ -n "${AD_PROFILES_SHARE_HOST_NAME}" ]; then
            pdbedit -p "\\\\${AD_PROFILES_SHARE_HOST_NAME}.${AD_REALM}\\profiles\\$1" "$1" > /dev/null
        fi
    fi
}

function doCreateUser()
{
    local etab="$1"
    local login="$2"
    local nom="$3"
    local password="$4"
    
    CURRENT_SID=$(ldbsearch -H /var/lib/samba/private/sam.ldb "(&(objectclass=user)(name=$login))" |grep dn: | cut -d" " -f2)
    if [[ -n "$CURRENT_SID" ]]
    then
        echo "$login existe"
        return
    fi
    if [ -z "$password" ]
    then
        password="$login"
    fi
    samba-tool user create "$login" "$password" --use-username-as-cn --given-name="$nom" --userou="OU=$etab"
}

function doCreateGroup()
{
    local nomGroup="${1}"
    local etab="$2"

    CURRENT_SID=$(ldbsearch -H /var/lib/samba/private/sam.ldb "(&(objectclass=group)(CN=$nomGroup))" |grep dn: | cut -d" " -f2)
    if [[ -n "$CURRENT_SID" ]]
    then
        echo "$nomGroup existe : $CURRENT_SID"
        return
    fi
    if [ -n "$etab" ]
    then
        samba-tool group add "$nomGroup" --groupou="OU=$etab" --group-type=Security --group-scope=Global
    else
        samba-tool group add "$nomGroup" --group-type=Security --group-scope=Global
    fi
}

function doCreateOUEtablissement()
{
    local etab="$1"
    local DN="OU=$etab,$BASEDN"
    if ! samba-tool ou create "$DN" 2>/dev/null
    then
        echo "OU $etab existe déjà"
    else
        echo "OU $etab crée"
    fi
    
    local DN="OU=Utilisateurs,OU=$etab,$BASEDN"
    if ! samba-tool ou create "$DN" 2>/dev/null
    then
        echo "$DN existe déjà"
    else
        echo "$DN crée"
    fi

    local DN="OU=Ordinateurs,OU=$etab,$BASEDN"
    if ! samba-tool ou create "$DN" 2>/dev/null
    then
        echo "$DN existe déjà"
    else
        echo "$DN crée"
    fi

}

function addGroupMembers()
{
    local groups="${1}"
    local member="${2}"
    
    samba-tool group addmembers "$groups" "$member" 2>/dev/null
}

function doGroupEtablissement()
{
    local etab="${1}"
    local prefix="${2}"
    local type="${3}"
    
    doCreateGroup "$prefix-$type" "$etab"
    addGroupMembers "$type" "$prefix-$type" 
}

function doGroupEleveEtablissement()
{
    local etab="${1}"
    local prefix="${2}"
    local nbMaxGroup="${3}"
    
    doGroupEtablissement "$etab" "$prefix" "eleves"
    for no in $(seq 1 "$nbMaxGroup" )
    do
        waitMaxProcessus "E${no}-$etab"
        (
        doCreateGroup "E${no}-$prefix" "$etab"
	    addGroupMembers "$prefix-eleves" "E${no}-$prefix" 
	    ) &
    done
}

function doGroupProfEtablissement()
{
    local etab="${1}"
    local prefix="${2}"
    local nbMaxGroup="${3}"

    doGroupEtablissement "$etab" "$prefix" "professeurs"
    for no in $(seq 1 "$nbMaxGroup" )
    do
        waitMaxProcessus "P${no}-$etab"
        (
        doCreateGroup "P${no}-$prefix" "$etab" 
	    addGroupMembers "$prefix-professeurs" "P${no}-$prefix"
	    ) &
    done
}

function doElevesEtablissement()
{
    local etab="${1}"
    local prefix="${2}"
    local nb_eleve="${3}"
    
    for no in $(seq 1 "$nb_eleve" )
    do
        waitMaxProcessus "${prefix}-Eleve${no}"
        (
        doCreateUser "$etab" "${prefix}-Eleve${no}" "Eleve $no" "Eleve$no"
        ) &
    done
}

function doProfsEtablissement()
{
    local etab="${1}"
    local prefix="${2}"
    local nb_prof="${3}"

    for no in $(seq 1 "$nb_prof" )
    do
        waitMaxProcessus "${prefix}-Prof${no}"
        (
        doCreateUser "$etab" "${prefix}-Prof${no}" "Prof $no" "Prof$no"
        ) &
    done
}

function doAttacheEleveGroupEtablissement()
{
    local etab="${1}"
    local prefix="${2}"
    local nbNbGroup="${3}"
    local nbEleve="${4}"

    for noGroup in $(seq 1 "$nbNbGroup" )
    do
        cat >/tmp/addGroup.ldif <<EOF
dn: cn=E${noGroup}-${prefix},OU=${etab},${BASEDN}
changetype: modify
delete: member
-
add: member
EOF
        local nbEleveToAdd=$(( ( RANDOM % "$nbEleve" )  + 1 ))
        #shellcheck disable=SC2034
        for nb in $(seq 1 "$nbEleveToAdd" )
        do
            local idx=$(( ( RANDOM % "$nbEleve" )  + 1 ))
            echo "member: CN=${prefix}-Eleve${idx},OU=${etab},${BASEDN}" >>/tmp/addGroup.ldif
        done
        echo "" >>/tmp/addGroup.ldif

        if ! ldbmodify -H /var/lib/samba/private/sam.ldb /tmp/addGroup.ldif
        then
            grep -n ":" /tmp/addGroup.ldif
            #exit 1
        fi
    done
}

function doAttacheProfGroupEtablissement()
{
    local etab="${1}"
    local prefix="${2}"
    local nbNbGroup="${3}"
    local nbProf="${4}"

    for noGroup in $(seq 1 "$nbNbGroup" )
    do
        cat >/tmp/addGroup.ldif <<EOF
dn: cn=P${noGroup}-${prefix},OU=${etab},${BASEDN}
changetype: modify
delete: member
-
add: member
EOF
        local nbProfToAdd=$(( ( RANDOM % "$nbProf" )  + 1 ))
        #shellcheck disable=SC2034
        for nb in $(seq 1 "$nbProfToAdd" )
        do
	        local idx=$(( ( RANDOM % "$nbProf" )  + 1 ))
            echo "member: CN=${prefix}-Prof${idx},OU=${etab},${BASEDN}" >>/tmp/addGroup.ldif
        done
        echo "" >>/tmp/addGroup.ldif

        if ! ldbmodify -H /var/lib/samba/private/sam.ldb /tmp/addGroup.ldif
        then
            grep -n ":" /tmp/addGroup.ldif
            #exit 1
        fi
    done
}

function doEtablissement()
{
    local no="${1}"
    local nb_eleve="${2}"
    local nb_prof="${3}"
    local nb_group_eleve="${4}"
    local nb_group_prof="${5}"
    local etab
    local prefix

    etab="$(printf '%08d' "${no}" )"
    prefix="ETB${no}"
    if [ -z "$nb_eleve" ]
    then
	    nb_eleve=$(( RANDOM % 50 + 32 ))
    fi
    if [ -z "$nb_prof" ]
    then
    	nb_prof=$(( nb_eleve / 8 + 2 ))
    fi
    if [ -z "$nb_group_eleve" ]
    then
    	nb_group_eleve=$(( nb_eleve / 8 + 2 ))
    fi
    if [ -z "$nb_group_prof" ]
    then
    	nb_group_prof=$(( nb_prof / 8 + 1 ))
    fi

    echo "Etablissement $etab avec $nb_eleve Eleves et $nb_group_eleve groupes, $nb_prof Professeurs et $nb_group_prof groupes"
    doCreateOUEtablissement "$etab"
    #site="SITE${no_etab}"
    #doCreateSiteEtablissement
	doGroupEleveEtablissement "$etab" "$prefix" "$nb_group_eleve"
    doGroupProfEtablissement "$etab" "$prefix" "$nb_group_prof"
    doElevesEtablissement "$etab" "$prefix" "$nb_eleve"
    doProfsEtablissement "$etab" "$prefix" "$nb_prof"
    wait < <(jobs -p)
    doAttacheEleveGroupEtablissement "$etab" "$prefix" "$nb_group_eleve" "$nb_eleve"
    doAttacheProfGroupEtablissement "$etab" "$prefix" "$nb_group_prof" "$nb_prof"
    wait < <(jobs -p)
}

function doAcademie()
{
    local first_etab="${1}"
    local last_etab="${2}"
    local nb_eleve="${3}"
    local nb_prof="${4}"
    local nb_group_eleve="${5}"
    local nb_group_prof="${6}"
    local etab
    local no_etab
    
    doCreateGroup "professeurs"
    doCreateGroup "eleves"
    for no_etab in $(seq "$first_etab" "$last_etab" )
    do
        doEtablissement "$no_etab" "$nb_eleve" "$nb_prof" "$nb_group_eleve" "$nb_group_prof" 
    done
}


function doImport()
{
    if [ "$numero" = "numero" ]
    then
        # entete !
        return 0 
    fi
    if [ -z "$login" ]
    then
        # ligne vide en fin de fichier ?
        return 0 
    fi
    if [ -z "$password" ]
    then
        # ligne vide en fin de fichier ?
        return 0 
    fi
    
    samba-tool user delete "$login" 2>/dev/null
    if [ -z "$prenom" ]
    then
        if [ -z "$nom" ]
        then
            echo "Import: login:$login password=$password"
            samba-tool user create "$login" "$password" --use-username-as-cn
        else
            echo "Import: login:$login nom=$nom password=$password"
            samba-tool user create "$login" "$password" --use-username-as-cn --given-name="$nom"
        fi 
    else
        echo "Import: login:$login nom=$nom prenom=$prenom password=$password"
        samba-tool user create "$login" "$password" --use-username-as-cn --surname="$prenom" --given-name="$nom"
    fi
    
    if [ -n "$classe" ]
    then
        doCreateGroup "$classe"
        addGroupMembers "$classe" "$login"
    fi
    if [ -n "$niveau" ]
    then
        doCreateGroup "$niveau"
        addGroupMembers "$niveau" "$login"
    fi
    if [ -n "$options" ]
    then
        for option in ${options//|/ }
        do
            doCreateGroup "$option"
            addGroupMembers "$option" "$login"
        done
    fi
    if [ "$TYPE" = "Prof" ]
    then
        addGroupMembers "professeurs" "$login"
    fi
    if [ "$TYPE" = "Eleve" ]
    then
        addGroupMembers "eleves" "$login"
    fi
    if [ "$TYPE" = "Administratif" ]
    then
        addGroupMembers "administratifs" "$login" 
    fi
    #addGroupMembers "Domain Users" "$nom"
    #ldbsearch -H /var/lib/samba/private/sam.ldb "(&(objectclass=user)(name=$nom))"
    samba_create_home "$login"
    samba_create_profile "$login"   
}

function doSethImportFichier()
{
    declare -a INFO_COMPTES
    FICHIER="$1"
    TYPE="$2"

    numero=""
    nom=""
    prenom=""
    #sexe=""
    #date=""
    login=""
    password=""
    #options=""
    echo "doSethImportFichier: FICHIER=$FICHIER TYPE=$TYPE"
    if [ "$TYPE" = "Prof" ]
    then
        doCreateGroup "professeurs"
    fi
    if [ "$TYPE" = "Administratif" ]
    then
        doCreateGroup "administratifs"
    fi
    if [ "$TYPE" = "Eleve" ]
    then
        doCreateGroup "eleves"
    fi
    while IFS=';' read -ra INFO_COMPTES
    do
        options=""
        classe=""
        niveau=""
        if [ "$TYPE" = "Prof" ]
        then
            #numero;nom;prenom;sexe;date;login;password;classes;options
            #1;Prof1;Prenom;M;01011950;prof1;eole;;
            numero="${INFO_COMPTES[0]}"
            nom="${INFO_COMPTES[1]}"
            prenom="${INFO_COMPTES[2]}"
            #sexe="${INFO_COMPTES[3]}"
            #date="${INFO_COMPTES[4]}"
            login="${INFO_COMPTES[5]}"
            password="${INFO_COMPTES[6]}"
            classe="${INFO_COMPTES[7]}"
            options="${INFO_COMPTES[8]}"
            doImport
        fi

        if [ "$TYPE" = "Administratif" ]
        then
            #numero;nom;prenom;sexe;date;login;password;classes;options
            #1;Prof1;Prenom;M;01011950;prof1;eole;;
            numero="${INFO_COMPTES[0]}"
            nom="${INFO_COMPTES[1]}"
            prenom="${INFO_COMPTES[2]}"
            #sexe="${INFO_COMPTES[3]}"
            #date="${INFO_COMPTES[4]}"
            login="${INFO_COMPTES[5]}"
            password="${INFO_COMPTES[6]}"
            classe="${INFO_COMPTES[7]}"
            options="${INFO_COMPTES[8]}"
            doImport
        fi

        if [ "$TYPE" = "Eleve" ]
        then
            #numero;nom;prenom;sexe;date;classe;niveau;login;password;options
            #1;Eleve1;Prenom;M;01012000;c31;3eme;c31e1;eole;
            numero="${INFO_COMPTES[0]}"
            nom="${INFO_COMPTES[1]}"
            prenom="${INFO_COMPTES[2]}"
            #sexe="${INFO_COMPTES[3]}"
            #date="${INFO_COMPTES[4]}"
            classe="${INFO_COMPTES[5]}"
            niveau="${INFO_COMPTES[6]}"
            login="${INFO_COMPTES[7]}"
            password="${INFO_COMPTES[8]}"
            options="${INFO_COMPTES[9]}"
            doImport
        fi

        if [ "$TYPE" = "EcoMachine" ]
        then
            login="${INFO_COMPTES[0]}"
            nom="${INFO_COMPTES[0]}"
            prenom="$nom"
            password="${INFO_COMPTES[1]}"
            #sid="${INFO_COMPTES[2]}"
            doImport
        fi
                   
        if [ "$TYPE" = "EcoUser" ]
        then
            login="${INFO_COMPTES[0]}"
            nom="${INFO_COMPTES[0]}"
            prenom="$nom"
            password="${INFO_COMPTES[1]}"
            #sid="${INFO_COMPTES[2]}"
            #division="${INFO_COMPTES[3]}"
            #mail="${INFO_COMPTES[4]}"
            doImport
        fi
                   
    done <"$FICHIER"
}

function doSethImport()
{
    if [ -f "/etc/eole/samba4-vars.conf" ]
    then
        #shellcheck disable=SC1091
        . "/etc/eole/samba4-vars.conf"
    else
        # Template is disabled => samba is disabled
        exit 0
    fi

    # shellcheck disable=SC1091
    . /usr/lib/eole/ihm.sh

    # shellcheck disable=SC1091
    . /usr/lib/eole/samba4.sh

    BASEDN="DC=${AD_REALM//./,DC=}"
    echo "BASEDN: $BASEDN"
    echo "CONFIGURATION: $1"

    samba-tool domain passwordsettings set --complexity=off
    samba-tool domain passwordsettings set --min-pwd-length=4
    case "$1" in
        +10k)
            FIRST=$(samba-tool group listmembers professeurs |grep -c "^ETB" )
            FIRST=$(( FIRST + 1 ))
            LAST=$(( FIRST + 10 ))
            echo $FIRST "-" $LAST
            doAcademie $FIRST $LAST 200
            ;;

        50k)
            doAcademie 1 100 200
            ;;

        2k)
            doAcademie 1 2
            ;;

        3k)
            doCreateGroup "professeurs"
            doCreateGroup "eleves"
            doEtablissement 2
            ;;

        ecologie)
            doSethImportFichier "$VM_DIR_EOLE_CI_TEST/dataset/ecologie/sid_fixe/domaine_utilisateurs.txt" "EcoUser"
            doSethImportFichier "$VM_DIR_EOLE_CI_TEST/dataset/ecologie/sid_fixe/domaine_machines.txt" "EcoMachine"
            ;;

        setheducation|default)
            if command -v samba_update_site >/dev/null 2>&1; then
                echo "* Create or Update Sites List (Seth >= 2.6.2)"
                AD_HOST_IP_NETMASK="$(CreoleGet adresse_netmask_eth0)"
                AD_HOST_IP_NETWORK="$(CreoleGet adresse_network_eth0)"
                echo "*AD_HOST_IP_NETMASK=$AD_HOST_IP_NETMASK"
                cdr=$(mask2cdr "${AD_HOST_IP_NETMASK}" )
                echo "* cdr=$cdr"
                cidr="${AD_HOST_IP_NETWORK}/${cdr}"
                echo "* cidr=$cidr"
                samba_update_site "Default-First-Site-Name" "$cidr"
                samba_update_site "00000001" "10.1.0.0/16"
                samba_update_site "00000002" "10.2.0.0/16"

                echo "* Update DNS"
                samba_dnsupdate --verbose --all-names
            fi
    
            echo "* Import Eleve et Profs basique"
            doSethImportFichier "$VM_DIR_EOLE_CI_TEST/dataset/scribe/csv/Test Eleve.csv" "Eleve"
            doSethImportFichier "$VM_DIR_EOLE_CI_TEST/dataset/scribe/csv/Test Prof.csv" "Prof"
            doSethImportFichier "$VM_DIR_EOLE_CI_TEST/dataset/scribe/csv/Test Administratif.csv" "Administratif"
            ;;
            
         *)
            echo "* cas no géré $1"
            ;;
    esac
}

time doSethImport "$@"
