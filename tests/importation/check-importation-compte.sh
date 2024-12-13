#!/bin/bash
echo "$0 $1 $2 $3"
TYPE_COMPTE="$1"
NOM="$2"
GROUPE_ATTENDU="$3"
NUMERO_RNE="$4"
PREFIXE_ETAB="$5"

# responsables, eleves, personnels
case "$TYPE_COMPTE" in
    administratifs)
        # les administratifs sont des personnels
        TYPE_COMPTE_OPENLDAP=personnels
        ADMINISTRATIF=oui
        ;;
        
    responsables)
        TYPE_COMPTE_OPENLDAP=responsables
        ADMINISTRATIF=non
        ;;

    eleves)
        TYPE_COMPTE_OPENLDAP=eleves
        ADMINISTRATIF=non
        PREFIX_GROUP="eleves"
        ;;

    personnels)
        ADMINISTRATIF=non
        TYPE_COMPTE_OPENLDAP=personnels
        TYPE_COMPTE=professeurs
        PREFIX_GROUP="profs"
        ;;

    professeurs)
        ADMINISTRATIF=non
        TYPE_COMPTE_OPENLDAP=personnels
        PREFIX_GROUP="profs"
        ;;

    *)
        echo "type de compte nom géré : $TYPE_COMPTE, stop"
        exit 1
esac
NOM_PATH="/home/${NOM:0:1}/$NOM"
NOM_ACA=$(CreoleGet nom_academie)
if [ -z "$NUMERO_RNE" ]
then
    NUMERO_RNE=$(CreoleGet numero_etab)
else
    if [ -z "$PREFIXE_ETAB" ]
    then
        echo "PREFIXE_ETAB doit être donnée en paramétre en mode multi établissemenet"
        exit 1
    fi
fi
export RESULTAT="0"

if [ "${TYPE_COMPTE}" != "responsables" ]
then
    # les non responsables ont un répertoire HOME dans les imports
    if [ ! -d "${NOM_PATH}" ]
    then
        echo "ERREUR: le repertoire '${NOM_PATH}' n'existe pas"
        RESULTAT="1"
    else
        echo "OK: le repertoire '${NOM_PATH}' existe"
    fi
fi

if [ "$ADMINISTRATIF" == "non" ]
then
    # les non administratifs ont un mail dans les imports
    if [ ! -d "/home/mail/$NOM" ]
    then
        echo "ERREUR: le repertoire '/home/mail/$NOM' n'existe pas"
        RESULTAT="1"
    else
        echo "OK: le repertoire '/home/mail/$NOM' existe"
    fi
fi

if [ "$VM_MACHINE" == "etb3.amonecole" ] && ciVersionMajeurAPartirDe "2.8." 
then
    echo "* requete Ldap sur SambaAD"
    result=$(ssh addc ldbsearch -H /var/lib/samba/private/sam.ldb cn="$NOM" dn |grep dn:)
else
    echo "* requete Ldap sur OpenLDAP"
    result=$(ldapsearch -x -LLL -o ldif-wrap=no uid="$NOM" dn)
fi
if [ -z "$result" ]
then
    echo "ERREUR: $NOM n'est pas dans le LDAP ?"
    RESULTAT="1"
else
    if [ "$VM_MACHINE" == "etb3.amonecole" ] && ciVersionMajeurAPartirDe "2.8."
    then
        NOM_DN="CN=$NOM,OU=local,OU=${TYPE_COMPTE_OPENLDAP},OU=utilisateurs,OU=${NUMERO_RNE},OU=${NOM_ACA},OU=education,DC=etb3,DC=lan"
        if [ "$result" == "dn: ${NOM_DN}" ]
        then
            echo "OK: $NOM a le bon Dn"
            if [ "${TYPE_COMPTE}" == "eleves" ]
            then
                # les eleves ont un Divcod
                ssh addc ldbsearch -H /var/lib/samba/private/sam.ldb cn="$NOM" sn cn Divcod Meflcf|grep -v "^# " |grep -v "ref: " |grep -v "^$"
            else 
                ssh addc ldbsearch -H /var/lib/samba/private/sam.ldb cn="$NOM" sn cn |grep -v "^# " |grep -v "ref: " |grep -v "^$"
            fi
        else
            echo "ERREUR: le Dn de $NOM n'est pas le bon"
            echo "RESULTAT: '$result'"
            echo "ATTENDU : 'dn: ${NOM_DN}'"
            RESULTAT="1"
        fi
    else
        NOM_DN="uid=$NOM,ou=local,ou=${TYPE_COMPTE_OPENLDAP},ou=utilisateurs,ou=${NUMERO_RNE},ou=${NOM_ACA},ou=education,o=gouv,c=fr"
        if [ "$result" == "dn: ${NOM_DN}" ]
        then
            echo "OK: $NOM a le bon Dn"
            if [ "${TYPE_COMPTE}" == "eleves" ]
            then
                # les eleves ont un Divcod
                ldapsearch -x -LLL -o ldif-wrap=no uid="$NOM" sn cn Divcod Meflcf
            else 
                ldapsearch -x -LLL -o ldif-wrap=no uid="$NOM" sn cn
            fi
        else
            echo "ERREUR: le Dn de $NOM n'est pas le bon"
            echo "RESULTAT: '$result'"
            echo "ATTENDU : 'dn: ${NOM_DN}'"
            RESULTAT="1"
        fi
    fi
fi

if [ "${TYPE_COMPTE}" != "responsables" ]
then
    # les non responsables doivent pouvoir se connecter ==> ils ont un compte
    result=$(getent passwd "$NOM")
    if [ -z "$result" ]
    then
        echo "ERREUR: 'getent passwd $NOM' n'a pas répondu!"
        RESULTAT="1"
    else
        echo "OK: 'getent passwd $NOM' a répondu"
        echo "$result "
    fi
fi

if [ "${TYPE_COMPTE}" == "eleves" ] || [ "${TYPE_COMPTE}" == "professeurs" ] || [ "${TYPE_COMPTE}" == "personnels" ]
then
    # maj samba 4.13 (#33443)
    if ciVersionMajeurAvant "2.6.0"
    then
        GroupesCompte=$(CreoleRun "id -Gn $NOM" partage | tr ' ' '\n' | sort)
        GroupesAttendu="DomainUsers"
        GroupesAttenduAvecUsers="DomainUsers"
        if [ "$NOM" == "profpo" ]
        then
             GroupesAttendu="${GroupesAttendu},PrintOperators"
             GroupesAttenduAvecUsers="${GroupesAttenduAvecUsers},PrintOperators"
        fi
    else
        GroupesCompte=$(CreoleRun "id -Gn $NOM -z" partage | tr '\0' '\n' | sort)
        GroupesAttendu="domain users"
        GroupesAttenduAvecUsers="domain users"
        # maj samba 4.13 (#33443)
        if [ "$VM_VERSIONMAJEUR" != "2.7.1" ] && [ "$VM_MACHINE" != "aca.envole" ]
        then
            if ciVersionMajeurAvant "2.9.0" && [ "$VM_MACHINE" != "etb3.amonecole" ]
            then
                GroupesAttendu="${GroupesAttendu},BUILTIN\users"
                GroupesAttenduAvecUsers="${GroupesAttenduAvecUsers},BUILTIN\users"
            else
                GroupesAttendu="${GroupesAttendu},BUILTIN/users"
                GroupesAttenduAvecUsers="${GroupesAttenduAvecUsers},BUILTIN/users"
            fi
        fi
        GroupesAttendu="${GroupesAttendu},${NOM}"
        GroupesAttenduAvecUsers="${GroupesAttenduAvecUsers},${NOM}"
    fi
    #lower pour l'affichage ACL
    RNE_EN_MINUSCULE="${NUMERO_RNE,,}"
    if [ -n "$PREFIXE_ETAB" ]
    then
        GroupesAttendu="${GroupesAttendu},${RNE_EN_MINUSCULE}"
        GroupesAttenduAvecUsers="${GroupesAttenduAvecUsers},${RNE_EN_MINUSCULE}"
        #PREFIXE_ETAB_EN_MINUSCULE="${PREFIXE_ETAB,,}"
        GroupesAttendu="${GroupesAttendu},${PREFIX_GROUP}-${RNE_EN_MINUSCULE}"
        GroupesAttenduAvecUsers="${GroupesAttenduAvecUsers},${PREFIX_GROUP}-${RNE_EN_MINUSCULE}"
        #if [ "$VM_VERSIONMAJEUR" \> "2.7.1" ]
        #then
        #    GroupesAttendu="${GroupesAttendu},${PREFIX_GROUP}-${RNE_EN_MINUSCULE}"
        #fi
    fi
    if [ -n "$GROUPE_ATTENDU" ]
    then
        GroupesAttendu="${GroupesAttendu},${GROUPE_ATTENDU}"
        GroupesAttenduAvecUsers="${GroupesAttenduAvecUsers},${GROUPE_ATTENDU}"
    fi
    GroupesAttendu="${GroupesAttendu},${TYPE_COMPTE}"
    GroupesAttenduAvecUsers="${GroupesAttenduAvecUsers},${TYPE_COMPTE}"
    GroupesAttendu=$(echo "${GroupesAttendu}"| sed 's/,/\n/g' | sort)
    GroupesAttenduAvecUsers=$(echo "${GroupesAttenduAvecUsers}"| sed 's/,/\n/g' | sort)

    # shellcheck disable=SC2001
    echo "$GroupesCompte" | sed 's/\t//g' >/tmp/GroupesCompte
    # shellcheck disable=SC2001
    echo "$GroupesAttendu" | sed 's/\t//g' >/tmp/GroupesAttendu
    # shellcheck disable=SC2001
    echo "$GroupesAttenduAvecUsers" | sed 's/\t//g' >/tmp/GroupesAttenduAvecUsers
    
    echo "***************** Groupes de $NOM ****************************************"
    echo "*** Attendu    ****************************************   Importé **********" 
    
    diff --ignore-blank-lines --ignore-all-space --ignore-tab-expansion --ignore-space-change --side-by-side /tmp/GroupesAttendu /tmp/GroupesCompte
    result="$?"
    echo "result sans Users=$result"
    if [ "$result" -ne 0 ]
    then
        diff --ignore-blank-lines --ignore-all-space --ignore-tab-expansion --ignore-space-change --side-by-side /tmp/GroupesAttenduAvecUsers /tmp/GroupesCompte
        result="$?"
        echo "result avec Users =$result"
        if [ "$result" -ne 0 ]
        then
            echo "l'utilisateur $NOM n'appartient pas aux bons groupes"
            echo "------------"
            hexdump -C /tmp/GroupesAttendu | tee /tmp/GroupesAttendu.hex 
            echo "------------"
            hexdump -C /tmp/GroupesCompte | tee /tmp/GroupesCompte.hex
            echo "------------"
            diff /tmp/GroupesAttendu.hex /tmp/GroupesCompte.hex
            echo "$?"
            RESULTAT="1"
        fi
    else
        echo "La liste des groupes de l'utilisateur $NOM est correcte"
    fi
fi

exit $RESULTAT
