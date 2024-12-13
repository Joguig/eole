#!/bin/bash

function doSambaTool()
{
    case "$VM_MACHINE" in
        etb1.amon)
            ciMonitor ssh scribe ssh addc samba-tool "$@"
            ;;
        
        etb3.amonecole)
            # shellcheck disable=SC2029
            ssh addc samba-tool "$@" 
            ;;
        
        *)
            echo "machine inconnue"
            exit 1
            ;;
    esac
}

if [ -n "$1" ]
then
    VM_VERSIONMAJEUR="$1"
fi
echo "Utilise VM_VERSIONMAJEUR=$VM_VERSIONMAJEUR"
case "$VM_MACHINE" in
    etb1.amon)
        AD_ADMIN="Administrator"
        ADMIN_PASSWORD="Eole12345!"
        AD_HOST_NAME="addc.dompedago.etb1.lan"
        AD_REALM="dompedago.etb1.lan"

        ;;
    
    etb3.amonecole)
        AD_ADMIN="Administrator"
        ADMIN_PASSWORD="Eole12345!"
        AD_HOST_NAME="addc.etb3.lan"
        AD_REALM="etb3.lan"
        ;;
    
    *)
        echo "machine inconnue"
        exit 1
        ;;
esac


# ne pas supprimer les 2 lignes !
set -f
IFS=$'\n'
declare -a IP_HOSTS
declare -a NOM_COURTS
declare -a NOM_LONGS

mapfile -t IP_HOSTS < <(CreoleGet adresse_ip_hosts)
mapfile -t NOM_COURTS < <(CreoleGet nom_court_hosts)
mapfile -t NOM_LONGS < <(CreoleGet nom_long_hosts)

set +f
unset IFS

NB_ENTREES=${#IP_HOSTS[@]}
for (( i = 0; i < NB_ENTREES; ))
do
    dc4="$(awk -F. '{print $4}' <<<"${IP_HOSTS[$i]}")"
    echo "${IP_HOSTS[$i]} ${NOM_COURTS[$i]} ${NOM_LONGS[$i]} A  dc4=$dc4"
    
    doSambaTool dns add "${AD_HOST_NAME}" "${AD_REALM}" "${NOM_COURTS[$i]}" A "${IP_HOSTS[$i]}" -U"${AD_ADMIN}%${ADMIN_PASSWORD}"
    
    doSambaTool dns add  "${AD_HOST_NAME}" "${AD_REALM}" "${NOM_LONGS[$i]}" CNAME "${NOM_COURTS[$i]}"."${AD_REALM}" -U"${AD_ADMIN}%${ADMIN_PASSWORD}"
    
    ZONE=""
    case "${IP_HOSTS[$i]}" in
        10.1.1*)
               ZONE="1.1.10"
               ;;
        10.1.2*)
               ZONE="2.1.10"
               ;;
        10.1.3*)
               ZONE="3.1.10"
               ;;
        10.3.2*)
               ZONE="2.3.10"
               ;;
        *)
               echo "cas non géré!"
               ;;
    esac
    if [ -n "$ZONE" ]
    then
        if ! doSambaTool dns zoneinfo "${AD_HOST_NAME}" "${ZONE}.in-addr.arpa" -U"${AD_ADMIN}%${ADMIN_PASSWORD}" 1>/dev/null 2>&1
        then
            echo "   Zone : ${ZONE}.in-addr.arpa a créer"
            doSambaTool dns zonecreate "${AD_HOST_NAME}" "${ZONE}.in-addr.arpa" -U"${AD_ADMIN}%${ADMIN_PASSWORD}"
        else
            echo "   Zone : ${ZONE}.in-addr.arpa existe déjà"
        fi
        echo "${IP_HOSTS[$i]} ${NOM_COURTS[$i]} PTR -> $dc4"
        doSambaTool dns add "${AD_HOST_NAME}" "${ZONE}.in-addr.arpa" "$dc4" PTR "${NOM_COURTS[$i]}.${AD_REALM}."  -U"${AD_ADMIN}%${ADMIN_PASSWORD}"
    fi
    i=$(( i + 1))
done

doSambaTool dns serverinfo "${AD_HOST_NAME}" -U"${AD_ADMIN}%${ADMIN_PASSWORD}"
doSambaTool dns zonelist "${AD_HOST_NAME}" -U"${AD_ADMIN}%${ADMIN_PASSWORD}"
