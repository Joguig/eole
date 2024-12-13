#!/bin/bash

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
    CURRENT_SID=$(ldbsearch -H /var/lib/samba/private/sam.ldb "(&(objectclass=user)(name=$login))" |grep dn: | cut -d" " -f2)
    if [[ -n "$CURRENT_SID" ]]
    then
        echo "$login existe"
        return
    fi
    #samba-tool user delete "$login" 2>/dev/null
    password="$login"
    samba-tool user create "$login" "$password" --use-username-as-cn --given-name="$nom" --userou="OU=$etab"
}

function doCreateGroup()
{
    local nomGroup="${1}"
    CURRENT_SID=$(ldbsearch -H /var/lib/samba/private/sam.ldb "(&(objectclass=group)(CN=$nomGroup))" |grep dn: | cut -d" " -f2)
    if [[ -n "$CURRENT_SID" ]]
    then
        echo "$nomGroup existe : $CURRENT_SID"
        return
    fi
    samba-tool group add "$nomGroup" --groupou="OU=$etab" --group-type=Security --group-scope=Global
    #ldbsearch -H /var/lib/samba/private/sam.ldb "(&(objectclass=group)(name=$nomGroup))"
}

function doCreateOUEtablissement()
{
    RESULT=$(ldbsearch -H /var/lib/samba/private/sam.ldb "(&(objectclass=organizationalunit)(name=$etab))" | grep dn:)
    if [ -n "$RESULT" ] 
    then
        echo "OU $etab existe déjà"
        return
    fi
     
    cat >/tmp/creatOU.ldif <<EOF
dn: OU=$etab,$BASEDN
changetype: add
objectClass: top
objectClass: organizationalunit
EOF

    ldbmodify -v -H "/var/lib/samba/private/sam.ldb" /tmp/creatOU.ldif
    echo "OU $etab crée"
}


function doGroupEtablissement()
{
    local nbMaxGroup="${1}"
    for no in $(seq 1 "$nbMaxGroup" )
    do
        doCreateGroup "G${no}-$etab"
    done
}

function doUserEtablissement()
{
    local nb_eleve="${1}"
    for no in $(seq 1 "$nb_eleve" )
    do
        login="${etab}-Eleve${no}"
        nom="Eleve $no"
        password="Eleve$no"
        doCreateUser
    done
}

function doLinkGroupMembersEtablissement()
{
    local nbMaxGroup="${1}"
    local nbEleve="${2}"
    
    for noGroup in $(seq 1 "$nbMaxGroup" )
    do
        local nbEleveToAdd=$(( ( RANDOM % nbEleve )  + 1 ))
        #shellcheck disable=SC2034
        for nb in $(seq 1 "$nbEleveToAdd" )
        do
            local noEleve=$(( ( RANDOM % nbEleve )  + 1 ))
            samba-tool group addmembers "G${noGroup}-$etab" "${etab}-Eleve${noEleve}"
        done
    done
}

function doAcademie()
{
    local nb_etab="${1}"
    local nb_eleve="${2}"
    local nb_group="5"
    local etab
    local no_etab
    for no_etab in $(seq 1 "$nb_etab" )
    do
        etab="$(printf '%08d' "${no_etab}" )"
        echo "Etablissement $etab "
        doCreateOUEtablissement
        doGroupEtablissement "$nb_group"
        doUserEtablissement "$nb_eleve"
        doLinkGroupMembersEtablissement "$nb_group" "$nb_eleve" 
    done
}

function doImport()
{
    if [ "$numero" = "numero" ]
    then
        # entete !
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
    login=""
    password=""
    echo "doSethImportFichier: FICHIER=$FICHIER TYPE=$TYPE"
    while IFS=';' read -ra INFO_COMPTES
    do
        if [ "$TYPE" = "EcoMachine" ]
        then
            login="${INFO_COMPTES[0]}"
            nom="${INFO_COMPTES[0]}"
            prenom="$nom"
            password="${INFO_COMPTES[1]}"
            doImport
        fi
                   
        if [ "$TYPE" = "EcoUser" ]
        then
            login="${INFO_COMPTES[0]}"
            nom="${INFO_COMPTES[0]}"
            prenom="$nom"
            password="${INFO_COMPTES[1]}"
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
    BASEDN3D="DC=${AD_REALM//./,DC%3D}"
    echo "BASEDN: $BASEDN"
    echo "BASEDN3D: $BASEDN3D"
    echo "ARGUMENT: $1"
    echo "INSTANCE_CONFIGURATION: $INSTANCE_CONFIGURATION"
    
    samba-tool domain passwordsettings set --complexity=off
    samba-tool domain passwordsettings set --min-pwd-length=4
    if [ "$1" = "50k" ]
    then
        doAcademie 100 200
        return
    fi
    if [ "$1" = "2" ]
    then
        doAcademie 2 20
        return
    fi
    doSethImportFichier "$VM_DIR_EOLE_CI_TEST/dataset/ecologie/sid_fixe/domaine_utilisateurs.txt" "EcoUser"
    doSethImportFichier "$VM_DIR_EOLE_CI_TEST/dataset/ecologie/sid_fixe/domaine_machines.txt" "EcoMachine"
}

doSethImport "$@"
