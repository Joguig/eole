#!/bin/bash

function doCreateSiteEtablissement()
{
    site="$1"
    ConfigurationLdb=$(ls /var/lib/samba/private/sam.ldb.d/CN%3DCONFIGURATION*.ldb)
    if [ ! -f  "$ConfigurationLdb" ]
    then
        echo "Erreur, le fichier $ConfigurationLdb n'existe pas"
        exit 1
    fi
    
    ObjectGUID_Site=$(ldbsearch -H "$ConfigurationLdb" "(&(objectclass=site)(name=$site))" | grep objectGUID: | cut -d" " -f2)
    echo "$ObjectGUID_Site"
    if [ -n "$ObjectGUID_Site" ] 
    then
        echo "$site existe déjà (ObjectSid=$ObjectGUID_Site)"
        #return
    else
        samba-tool sites create "$site"
        echo "$site crée"
        
        ObjectGUID_Site=$(ldbsearch -H "$ConfigurationLdb" "(&(objectclass=site)(name=$site))" | grep objectGUID: | cut -d" " -f2)
        echo "ObjectGUID=$ObjectGUID_Site"
        if [ -z "$ObjectGUID_Site" ] 
        then
            echo "ERREUR impossible de trouver ObjectGUID du $site"
            exit 1
        fi
    fi

#    echo "recherche sitelink $ObjectGUID_Site dans DEFAULTIPSITELINK"
#    if ldbsearch -H "$ConfigurationLdb" "(&(objectclass=siteLink)(CN=DEFAULTIPSITELINK))" ;
#    then
#        echo "ERREUR impossible de trouver DEFAULTIPSITELINK"
#        exit 1
#    fi               
#    ldbmodify -v -H $ConfigurationLdb -i <<EOF
#dn: CN=DEFAULTIPSITELINK,CN=IP,CN=Inter-Site Transports,CN=Sites,CN=Configuration,$BASEDN
#changetype: modify
#add: siteList
#siteList: <GUID=$ObjectGUID_Site>;<RMD_FLAGS=0>;<RMD_VERSION=0>;CN=Site-$etab,CN=Sites,CN=Configuration,$BASEDN
#EOF
#    ObjectGUID_Sitelink=$(ldbsearch -H "$ConfigurationLdb" "(&(objectclass=sitelink)(name=$sitelink))" | grep objectGUID: | cut -d" " -f2)
#    if [ -z "$ObjectGUID_Sitelink" ]
#    then
#        # récupération ObjectGUID DEFAULTIPSITELINK 
#        ObjectGUID_DEFAULTIPSITELINK=$(ldbsearch -H "$ConfigurationLdb" "(&(objectclass=sitelink)(name=DEFAULTIPSITELINK))" | grep objectGUID: | cut -d" " -f2)
#        if [ -z "$ObjectGUID_DEFAULTIPSITELINK" ]
#        then
#            echo "* Sitelink DEFAULTIPSITELINK non trouvé, erreur grave !"
#            exit 1
#        fi
#
#        BASEDN="DC=${AD_REALM//./,DC=}"
#        cat >/tmp/createSiteLink.ldif <<EOF
#dn: CN=${sitelink},CN=IP,CN=Inter-Site Transports,CN=Sites,CN=Configuration,${BASEDN}
#changetype: add
#objectClass: top
#objectClass: siteLink
#cn: ${sitelink}
#name: ${sitelink}
#distinguishedName: CN=${sitelink},CN=IP,CN=Inter-Site Transports,CN=Sites,CN=Configuration,${BASEDN}        
#instanceType: 4
#cost: 100
#replInterval: 180
#siteList: <GUID=${ObjectGUID_DEFAULTIPSITELINK}>;<RMD_ADDTIME=0>;<RMD_CHANGETIME=0>;<RMD_FLAGS=0>;<RMD_VERSION=0>;CN=Default-First-Site-Name,CN=Sites,CN=Configuration,$BASEDN
#siteList: <GUID=${ObjectGUID_Site}>;<RMD_ADDTIME=0>;<RMD_CHANGETIME=0>;<RMD_FLAGS=0>;<RMD_VERSION=0>;CN=${Site},CN=Sites,CN=Configuration,$BASEDN
#EOF
#        cat /tmp/createSiteLink.ldif
#        ldbmodify -v -H "$ConfigurationLdb" /tmp/createSiteLink.ldif
#
#        ldbsearch -H "$ConfigurationLdb" "(&(objectclass=sitelink)(name=$sitelink))"
#                
##        cat >/tmp/createSiteLinkList.ldif <<EOF
##changetype: modify
##add: siteList
##siteList: <GUID=${ObjectGUID_DEFAULTIPSITELINK}>;<RMD_ADDTIME=131480617530000000>;<RMD_CHANGETIME=131480617530000000>;<RMD_FLAGS=0>;<RMD_INVOCID=43162d8f-1a5b-4243-a3fa-bf1d8ae65be4>;<RMD_LOCAL_USN=3840>;<RMD_ORIGINATING_USN=3840>;<RMD_VERSION=0>;CN=Default-First-Site-Name,CN=Sites,CN=Configuration,$BASEDN
##siteList: <GUID=${ObjectGUID_Site}>;<RMD_ADDTIME=131480617530000000>;<RMD_CHANGETIME=131480617530000000>;<RMD_FLAGS=0>;<RMD_INVOCID=43162d8f-1a5b-4243-a3fa-bf1d8ae65be4>;<RMD_LOCAL_USN=3840>;<RMD_ORIGINATING_USN=3840>;<RMD_VERSION=0>;CN=${Site},CN=Sites,CN=Configuration,$BASEDN
##EOF
##        ldbmodify -v -H "$ConfigurationLdb" /tmp/createSiteLinkList.ldif
##        echo "* Sitelink $sitelink associé entre $site et Defaut ==> $?"
##                                                        
#        #siteList: <GUID=${ObjectGUID_DEFAULTIPSITELINK}>;<RMD_ADDTIME=131480617530000000>;<RMD_CHANGETIME=131480617530000000>;<RMD_FLAGS=0>;<RMD_INVOCID=43162d8f-1a5b-4243-a3fa-bf1d8ae65be4>;<RMD_LOCAL_USN=3840>;<RMD_ORIGINATING_USN=3840>;<RMD_VERSION=0>;CN=Default-First-Site-Name,CN=Sites,CN=Configuration,$BASEDN
#        #siteList: <GUID=${ObjectGUID_Site}>;<RMD_ADDTIME=131480617530000000>;<RMD_CHANGETIME=131480617530000000>;<RMD_FLAGS=0>;<RMD_INVOCID=43162d8f-1a5b-4243-a3fa-bf1d8ae65be4>;<RMD_LOCAL_USN=3840>;<RMD_ORIGINATING_USN=3840>;<RMD_VERSION=0>;CN=${Site},CN=Sites,CN=Configuration,$BASEDN
#        echo "* Sitelink $sitelink du site $site crée"
#    else
#        echo "* Vérification sitelink $sitelink du site $site : OK, existe"
#    fi
#        
    echo "Site Link Site-$etab crée"
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
    CURRENT_SID=$(ldbsearch -H /var/lib/samba/private/sam.ldb "(&(objectclass=user)(name=$login))" |grep dn: | cut -d" " -f2)
    if [[ -n "$CURRENT_SID" ]]
    then
        #echo "$login existe"
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
        #echo "$nomGroup existe : $CURRENT_SID"
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
        local nbEleveToAdd=$(( ( RANDOM % "$nbEleve" )  + 1 ))
        #shellcheck disable=SC2034
        for nb in $(seq 1 "$nbEleveToAdd" )
        do
            local noEleve=$(( ( RANDOM % "$nbEleve" )  + 1 ))
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
        etab=$(printf '%08d' "${no_etab}" )
        echo "Etablissement $etab "
        doCreateOUEtablissement
        #site="SITE${no_etab}"
        #doCreateSiteEtablissement
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
    
    if [ -n "$classe" ]
    then
        doCreateGroup "$classe"
        samba-tool group addmembers "$classe" "$login"
    fi
    if [ -n "$niveau" ]
    then
        doCreateGroup "$niveau"
        samba-tool group addmembers "$niveau" "$login"
    fi
    if [ -n "$options" ]
    then
        for option in ${options//|/ }
        do
            doCreateGroup "$option"
            samba-tool group addmembers "$option" "$login"
        done
    fi
    if [ "$TYPE" = "Prof" ]
    then
        doCreateGroup "professeurs"
        samba-tool group addmembers "professeurs" "$login"
    fi
    if [ "$TYPE" = "Eleve" ]
    then
        doCreateGroup "eleves"
        samba-tool group addmembers "eleves" "$login"
    fi
    if [ "$TYPE" = "Administratif" ]
    then
        doCreateGroup "administratifs"
        samba-tool group addmembers "administratifs" "$login"
    fi
    #samba-tool group addmembers "Domain Users" "$nom"
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
    if [ "$INSTANCE_CONFIGURATION" = "ecologie" ]
    then
        doSethImportFichier "$VM_DIR_EOLE_CI_TEST/dataset/ecologie/sid_fixe/domaine_utilisateurs.txt" "EcoUser"
        doSethImportFichier "$VM_DIR_EOLE_CI_TEST/dataset/ecologie/sid_fixe/domaine_machines.txt" "EcoMachine"
    else
        if command -v samba_update_site >/dev/null 2>&1; then
            echo "Create or Update Sites List (Seth >= 2.6.2)"
            AD_HOST_IP_NETMASK="$(CreoleGet adresse_netmask_eth0)"
            AD_HOST_IP_NETWORK="$(CreoleGet adresse_network_eth0)"
            echo "AD_HOST_IP_NETMASK=$AD_HOST_IP_NETMASK"
            cdr=$(mask2cdr "${AD_HOST_IP_NETMASK}" )
            echo "cdr=$cdr"
            cidr="${AD_HOST_IP_NETWORK}/${cdr}"
            echo "cidr=$cidr"
            samba_update_site "Default-First-Site-Name" "$cidr"
            samba_update_site "00000001" "10.1.0.0/16"
            samba_update_site "00000002" "10.2.0.0/16"
        fi
        echo "* Update DNS"
        samba_dnsupdate --verbose --all-names

        echo "* Import Eleve et Profs basique"
        doSethImportFichier "$VM_DIR_EOLE_CI_TEST/dataset/scribe/csv/Test Eleve.csv" "Eleve"
        doSethImportFichier "$VM_DIR_EOLE_CI_TEST/dataset/scribe/csv/Test Prof.csv" "Prof"
        doSethImportFichier "$VM_DIR_EOLE_CI_TEST/dataset/scribe/csv/Test Administratif.csv" "Administratif"
    fi
}

doSethImport "$@"
