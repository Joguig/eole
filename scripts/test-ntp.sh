#!/bin/bash

# shellcheck disable=SC1091
. "$(CreoleGet container_path_domaine)/etc/eole/samba4-vars.conf"

    TIMEOUT=120
    SLEEP_TIME=10
    MAX_ATTEMPT=$(( TIMEOUT / SLEEP_TIME ))

    attempt=0
    is_sync=false
    wanted_peer=false

    # récupére la liste des IP des Server NTP (avec résolution si besoin)
    PATTERN_IPV4="(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])"
    # le DC de référence doit être en premier !
    NTP_SERVERS_IP="$(CreoleGet serveur_ntp)"
    if [ -n "${AD_ADDITIONAL_DC_IP}" ]
    then
        echo "Ajout DC en 1er : $AD_ADDITIONAL_DC_IP"
        NTP_SERVERS_IP="${AD_ADDITIONAL_DC_IP// }\n"
    fi

    for ntp_server in $NTP_SERVERS
    do
        if ! [[ "${ntp_server}" =~ ^${PATTERN_IPV4}$ ]]
        then
            ntp_server_ips=$(dig @"$AD_REALM" +short "$ntp_server")
        else
            ntp_server_ips="$ntp_server"
        fi
        echo "Ajout DC : $ntp_server_ips"
        NTP_SERVERS_IP="${NTP_SERVERS_IP}${ntp_server_ips}\n"
    done
    SERVEUR_NTP="$(CreoleGet serveur_ntp)"
    if [ -n "$SERVEUR_NTP" ]
    then
        NTP_SERVERS_IP="${NTP_SERVERS_IP}${SERVEUR_NTP}\n"
    fi
    echo "Ajout NTP général : $SERVEUR_NTP"
    echo "Serveur Ntp : "
    echo -e $NTP_SERVERS_IP

    # on attend la synchronisation avec une sortie (break) si le nombre de tentatives est épuisé
    while ! $is_sync
    do
        while read -r assid
        do
            echo "- assid : $assid"
            # récupére le srcadr = IP (rv=readvar)
            sync_data=$(ntpq -n -c "rv $assid srcadr")
            srcadr="${sync_data//srcadr=}" # enleve 'srcadr='
            if [ "$srcadr" = "0.0.0.0" ]
            then
                echo "    srcadr : pas de réponse valable"
                continue
            fi

            while read -r ntp_server_ip
            do
                echo "  - ntp_server_ip : $ntp_server_ip"
                if [ "$srcadr" == "$ntp_server_ip" ] # le service ntp a retourné des informations pour ce pair donné
                then
                    # le service ntp a retourné des informations pour ce pair donné
                    wanted_peer=true

                    # récupére le 'reach' (rv=readvar)
                    sync_data=$(ntpq -n -c "rv $assid reach")
                    reach="${sync_data//reach=}"    # enleve 'reach='
                    reach=1
                    if [ "${reach}" = "177" ] || [ "${reach}" = "377" ]
                    then
                        # le service NTP atteste la synchronisation
                        is_sync=true
                        echo "Horloge synchronisée sur ${srcadr} (avec un offset de ${offset}s)"
                    elif [ "${reach}" -gt 0 ]
                    then
                        # récupére l' offset
                        sync_data=$(ntpq -n -c "rv $assid offset")
                        offset="${sync_data//offset=}" # enleve 'offset='
                        decalage="$offset"
                        offset="${offset#-}"        # enleve '-'
                        offset="${offset#+}"        # enleve '+'
                        offset="${offset//./}"      # enleve '.' multiple
                        if [ "$offset" -lt "300000" ]
                        then
                            # le service NTP n’atteste pas la synchronisation mais le serveur de référence est joignable et
                            # l’offset est en deça de la limite admise pour les échanges kerberos (5 minutes exprimées en millisecondes)
                            is_sync=true
                            echo "Horloge synchronisée sur ${srcadr} (avec un offset non attesté de ${decalage}s)"
                        else
                            echo "Horloge non synchronisée sur ${srcadr} décalage de ${decalage}s"
                        fi
                    fi
                    # on peut donc sortie de la boucle
                    break
                fi
            done <<< "$(echo -e "${NTP_SERVERS_IP}")"
            if ${is_sync}
            then
                break
            fi
        done <<< "$(ntpq -c 'as' | sed -e '1,2d' -e 's/\s\+/ /g' -e 's/^\s\+//' | cut -f2 -d ' ')"

        if ! $is_sync
        then
            # si on n’a pas épuisé le nombre de tentatives permises, on boucle après avoir affiché, une fois, qu’on attend la synchronisation
            if [ $attempt -lt $MAX_ATTEMPT ]
            then
                if [ $attempt -eq 0 ]
                then
                    echo -n "En attente de synchronisation "
                else
                    echo -n "."
                fi
                attempt=$(( attempt + 1))
                sleep $SLEEP_TIME
            else
                echo
                echo "Délai d'attente dépassé"
                break
            fi
        fi
    done

    if $is_sync
    then
        exit 0
    elif $wanted_peer
    then
        . /usr/lib/eole/diagnose.sh
        echo "Diagnostique de la configuration NTP :"
        TestNTP "$(CreoleGet serveur_ntp)"
        EchoRouge "Impossible de synchroniser l'horloge du serveur"
        exit 1
    else
        . /usr/lib/eole/ihm.sh
        EchoRouge "Le serveur NTP local ne se met pas à l'heure sur les serveurs NTP configurés"
        exit 1
    fi
fi
