#!/bin/bash

function doSignalErreur()
{
    local TEXTE="$1"
    local NOM=$2
  
    echo "    ERREUR: $TEXTE"
    if [ -f /tmp/dig.txt ]
    then
        echo "        --dig----------------"
        sed 's/^/        /' </tmp/dig.txt
    fi
    if [ -f /tmp/hosts.txt ]
    then
        echo "        --hosts--------------"
        sed 's/^/        /' </tmp/hosts.txt
    fi
    if [ -f /tmp/test1.txt ]
    then
        echo "        --dig ptr------------"
        sed 's/^/        /' </tmp/test1.txt
    fi
    if [ -f /tmp/test.txt ]
    then
        echo "        --dig ptr  nom-------"
        sed 's/^/        /' </tmp/test.txt
    fi
    echo "        -------------------"
    RESULT="1"
    if [ "$STOP_ON_ERROR" == "oui" ]
    then
        exit 1
    fi
}

function doUseCase()
{
    local DIG_HOST="$1"
    local DESCRIPTION="$2"
    local NOM="$3"
    local NOM_LONG="$4"
    local IP="$5"
    local RESULT_ETC_HOST="$6"
    local RESULT_DIG="$7"
    local RESULT_DIG_INVERSE="$8"
        
    local NB
    local RESULT
    local IP_INVERSE

    RESULT="0"
    rm -f /tmp/hosts.txt
    rm -f /tmp/test.txt
    rm -f /tmp/test1.txt
    rm -f /tmp/dig.txt
    
    echo " "
    echo "*****************************************"
    echo -e "Use Case: $DESCRIPTION"
    echo -e "    NOM COURT:  $NOM"
    echo -e "    NOM LONG:   $NOM_LONG"
    echo -e "    IP:         $IP"
    echo -e "    /etc/hosts: $RESULT_ETC_HOST"
    echo -e "    dig:        $RESULT_DIG"
    echo -e "    dig ptr:    $RESULT_DIG_INVERSE"
    echo -e "    --- "
    if [ "$TEST_HOSTS" == oui ]
    then
        case "$RESULT_ETC_HOST" in 
            PRESENCE_HOST)
               grep "^${IP}[[:space:]]" /etc/hosts >/tmp/hosts.txt
               grep "${NOM_LONG}[[:space:]]*${NOM}" /tmp/hosts.txt >/tmp/test.txt
               NB=$(wc -l </tmp/test.txt)
               if [ "$NB" -ne 1 ]
               then
                   doSignalErreur "    la réponse est '$NB'. L'entrée '$NOM_LONG' n'existe pas dans /etc/hosts (HOST)"
               else
                   echo  "    OK: L'entrée '$NOM_LONG' existe dans /etc/hosts (HOST)"
               fi
               ;;
                   
            PRESENCE_HOST_SANS_NOM_COURT)
               grep "^${IP}[[:space:]]" /etc/hosts >/tmp/hosts.txt
               grep "$NOM_LONG\$" /tmp/hosts.txt >/tmp/test.txt
               NB=$(wc -l </tmp/test.txt)
               if [ "$NB" -ne 1 ]
               then
                   doSignalErreur "    La réponse est '$NB'. L'entrée '$NOM_LONG' n'existe pas dans /etc/hosts (HOST)"
               else
                   echo  "    OK: L'entrée '$NOM_LONG' existe dans /etc/hosts (HOST)"
               fi
               ;;
                   
            ABSENCE_HOST)
               grep "^$IP" /etc/hosts | grep "$NOM_LONG $NOM\$" >/tmp/test.txt
               NB=$(wc -l </tmp/test.txt)
               if [ "$NB" -ne 0 ]
               then
                   doSignalErreur "    la réponse est '$NB'. L'entrée '$NOM_LONG' existe dans /etc/hosts (HOST)"
               else
                   echo  "    OK: L'entrée '$NOM_LONG' n'existe pas dans /etc/hosts (HOST)"
               fi
               ;;
            *)
               echo "    ERREUR: $RESULT_ETC_HOST ! (HOST)"
               return 1
               ;;
        esac
    fi
                                                      
    rm -f /tmp/hosts.txt
    dig "@${DIG_HOST}" "$NOM_LONG" >/tmp/dig.txt
    grep "^$NOM_LONG\." /tmp/dig.txt | grep "$IP\$" >/tmp/test.txt
    NB=$(wc -l </tmp/test.txt)
    case "$RESULT_DIG" in 
        PRESENCE_DIG)
            if [ "$NB" -ne 1 ]
            then
                doSignalErreur "    La réponse est '$NB'. Le DNS ne résoud pas le nom '$NOM_LONG' correctement, l'entrée A devrait exister  (DIG)"
            else
                echo  "    OK: Le DNS résoud l'entrée '$NOM_LONG', le A existe (DIG)"
            fi
            ;;

        ABSENCE_DIG)
            if [ "$NB" -ne 0 ]
            then
                doSignalErreur "    La réponse est '$NB'. Le DNS résoud le nom '$NOM_LONG', l'entrée A ne devrait pas exister  (DIG)"
            else
                echo  "    OK: Le DNS ne résoud pas le nom '$NOM_LONG', l'entrée A n'existe pas (DIG)"
            fi
            ;;
        *)
            echo "    ERREUR PROGRAME ! $RESULT_DIG  (DIG)"
            return 0   
            ;;
    esac
                
    IP_INVERSE=$( echo "$IP" | awk -F'.' '{ print $4 "." $3 "."  $2 "." $1;}' )
    dig "@${DIG_HOST}" -x "$IP" >/tmp/dig.txt
    grep "PTR" /tmp/dig.txt| grep "^$IP_INVERSE\.in-addr\.arpa" >/tmp/test1.txt 
    grep "$NOM" </tmp/test1.txt >/tmp/test.txt 
    NB=$(wc -l </tmp/test.txt)
    case "$RESULT_DIG_INVERSE" in 
        PRESENCE_DIG_INVERSE)
            if [ "$NB" -ne 1 ]
            then
                doSignalErreur "    La réponse est '$NB'. Le DNS ne résoud pas l'IP '${IP_INVERSE}.in-addr.arpa', le PTR n'existe pas (DIGPTR)"
            else
                echo  "    OK: Le DNS résoud l'IP '${IP_INVERSE}.in-addr.arpa', le PTR existe (DIGPTR)"
            fi
            ;;
            
        ABSENCE_DIG_INVERSE)
            if [ "$NB" -ne 0 ]
            then
                doSignalErreur "    la réponse est '$NB'. Le DNS résoud l'IP '${IP_INVERSE}.in-addr.arpa' !, le PTR ne devrait pas exister (DIGPTR)"
            else
                echo  "    OK: Le DNS ne résoud pas l'IP '${IP_INVERSE}.in-addr.arpa', le PTR n'existe pas (DIGPTR)"
            fi
            ;;
        *)
            echo "    ERREUR PROGRAME ! $RESULT_DIG (DIGPTR)"
            return 0   
            ;;
    esac
    
    echo ""
    return "$RESULT"  
}

if [ -z "$STOP_ON_ERROR" ]
then
    STOP_ON_ERROR=non
fi
RESULT="0"
if [ -n "$1" ]
then
    VM_VERSIONMAJEUR="$1"
fi
echo "Utilise VM_VERSIONMAJEUR=$VM_VERSIONMAJEUR, VM_MACHINE=$VM_MACHINE"

case "$VM_MACHINE" in
    etb1.amon)
          if [ "$VM_VERSIONMAJEUR" = 2.8.1 ]
          then
              DIG_HOST=10.1.3.11
              DIG_AD=10.1.3.11
          else
              DIG_HOST=localhost
              DIG_AD=localhost
          fi
          TEST_HOSTS=oui
          ;;
    
    etb1.scribe)
          if [ "$VM_VERSIONMAJEUR" = 2.8.1 ]
          then
              DIG_HOST=10.1.3.11
              DIG_AD=10.1.3.11
          else
              DIG_HOST=$VM_ETH0_DNS
              DIG_AD=$VM_ETH0_DNS
          fi
          TEST_HOSTS=oui
          ;;

    etb1*)
          if [ "$VM_VERSIONMAJEUR" = 2.8.1 ]
          then
              DIG_HOST=10.1.3.11
              DIG_AD=10.1.3.11
          else
              DIG_HOST=$VM_ETH0_DNS
              DIG_AD=$VM_ETH0_DNS
          fi
          TEST_HOSTS=no
          ;;
          
    etb3.amonecole)
          if [ "$VM_VERSIONMAJEUR" = 2.8.1 ]
          then
              DIG_HOST=192.0.2.56
              DIG_AD=10.3.2.5
          else
              DIG_HOST=192.0.2.53
              DIG_AD=192.0.2.53
          fi
          TEST_HOSTS=oui
          ;;
    
    etb3*)
          if [ "$VM_VERSIONMAJEUR" = 2.8.1 ]
          then
              DIG_HOST=10.3.2.5
              DIG_AD=10.3.2.5
          else
              DIG_HOST=$VM_ETH0_DNS
              DIG_AD=$VM_ETH0_DNS
          fi
          TEST_HOSTS=no
          ;;

    *)
          echo "machine inconnue"
          exit 1
          ;;      
esac
echo "Utilise DIG_HOST=$DIG_HOST, DIG_AD=$DIG_AD, TEST_HOSTS=$TEST_HOSTS"

if [ "$VM_ETABLISSEMENT" == "etb1" ]
then
    doUseCase "${DIG_HOST}" \
              "ETB1 : Le serveur DNS résoud le nom de la machine avec l'adresse IP eth0. " \
              "amon" \
              "amon.etb1.lan" \
              "192.168.0.31" \
              "PRESENCE_HOST" \
              "PRESENCE_DIG" \
              "PRESENCE_DIG_INVERSE"
              
    doUseCase "${DIG_HOST}" \
              "ETB1 : Le serveur DNS résoud le nom de l'interface eth1." \
              "admin" \
              "admin.etb1.lan" \
              "10.1.1.1" \
              "PRESENCE_HOST" \
              "PRESENCE_DIG" \
              "PRESENCE_DIG_INVERSE"
              
    doUseCase "${DIG_HOST}" \
              "ETB1 : Le serveur DNS résoud l'adresse wpad. " \
              "wpad" \
              "wpad.etb1.lan" \
              "192.168.0.31" \
              "PRESENCE_HOST" \
              "PRESENCE_DIG" \
              "PRESENCE_DIG_INVERSE"
    
    doUseCase "${DIG_HOST}" \
              "ETB1 : Résolution inverse de l'adresse IP eth0 pour 'domsupp1.lan' " \
              "amon" \
              "amon.domsupp1.lan" \
              "192.168.0.31" \
              "PRESENCE_HOST_SANS_NOM_COURT" \
              "PRESENCE_DIG" \
              "PRESENCE_DIG_INVERSE"
    
    doUseCase "${DIG_HOST}" \
              "ETB1 : Host 1: zone admin, domaine existant :" \
              "scribepedago" \
              "scribepedago.etb1.lan" \
              "10.1.2.5" \
              "PRESENCE_HOST" \
              "PRESENCE_DIG" \
              "PRESENCE_DIG_INVERSE"
    
    doUseCase "${DIG_HOST}" \
              "ETB1 : Host 2 : zone admin sur domaine supplémentaire" \
              "srvetb1" \
              "srvetb1.domsupp1.lan" \
              "10.1.3.5" \
              "PRESENCE_HOST" \
              "PRESENCE_DIG" \
              "PRESENCE_DIG_INVERSE"
    
    doUseCase "${DIG_HOST}" \
              "ETB1 : Host 3 : Le serveur DNS ne résoud pas un nom d'host déclaré dans un autre domaine (Pas de ANSWER SECTION)." \
              "scribeadmin" \
              "scribeadmin.domsupp1.lan" \
              "10.1.3.5" \
              "ABSENCE_HOST" \
              "ABSENCE_DIG" \
              "ABSENCE_DIG_INVERSE"
    
    doUseCase "${DIG_HOST}" \
              "ETB1 : Host 4 : zone admin, domaine inexistant :\n Un domaine déclaré dans l' hôte 'pc-linux.dominexistant.lan' (host supplémentaire) est traité comme un domaine local supplémentaire." \
              "pc-linux" \
              "pc-linux.dominexistant.lan" \
              "10.1.2.51" \
              "PRESENCE_HOST" \
              "ABSENCE_DIG" \
              "ABSENCE_DIG_INVERSE"
    echo "ATTENTION FIXME #7974 (devrait être PRESENCE_DIG PRESENCE_DIG_INVERSE?)"
    
    doUseCase "${DIG_HOST}" \
              "ETB1 : Host 5: host avec une adresse IP externe au serveur amon.etb1.lan :\nLe DNS n'est pas master d'une plage d'adresse IP externe au serveur amon.etb1.ac-test.fr (Pas de ANSWER SECTION)." \
              "horsplage" \
              "horplage.etb1.lan" \
              "10.1.5.5" \
              "PRESENCE_HOST" \
              "ABSENCE_DIG" \
              "ABSENCE_DIG_INVERSE"
    
    doUseCase "${DIG_HOST}" \
              "ETB1 : Authentification NTLM/SMB : scribe " \
              "scribe" \
              "scribe.etb1.lan" \
              "10.1.3.5" \
              "PRESENCE_HOST" \
              "PRESENCE_DIG" \
              "PRESENCE_DIG_INVERSE"
    
    doUseCase "${DIG_HOST}" \
              "ETB1 : Authentification NTLM/SMB : horus" \
              "horus" \
              "horus.etb1.lan" \
              "10.1.1.10" \
              "PRESENCE_HOST" \
              "PRESENCE_DIG" \
              "PRESENCE_DIG_INVERSE"
fi

if [ "$VM_ETABLISSEMENT" == "etb3" ]
then
    doUseCase "${DIG_HOST}" \
              "ETB3 : Le serveur DNS résoud le nom de la machine avec l'adresse IP eth0. " \
              "amonecole" \
              "amonecole.etb3.lan" \
              "192.168.0.33" \
              "PRESENCE_HOST" \
              "PRESENCE_DIG" \
              "PRESENCE_DIG_INVERSE"
              
    doUseCase "${DIG_HOST}" \
              "ETB3 : Le serveur DNS résoud le nom de l'interface eth1." \
              "pedago" \
              "pedago.etb3.lan" \
              "10.3.2.1" \
              "PRESENCE_HOST" \
              "PRESENCE_DIG" \
              "PRESENCE_DIG_INVERSE"
              
    doUseCase "${DIG_HOST}" \
              "ETB3 : Le serveur DNS résoud l'adresse wpad. " \
              "wpad" \
              "wpad.etb3.lan" \
              "192.168.0.33" \
              "PRESENCE_HOST" \
              "PRESENCE_DIG" \
              "PRESENCE_DIG_INVERSE"
    
    doUseCase "${DIG_HOST}" \
              "ETB3 : Résolution inverse de l'adresse IP eth0 pour 'domsupp1.lan' " \
              "amonecole" \
              "amonecole.domsupp1.lan" \
              "192.168.0.33" \
              "PRESENCE_HOST_SANS_NOM_COURT" \
              "PRESENCE_DIG" \
              "PRESENCE_DIG_INVERSE"
    
    doUseCase "${DIG_HOST}" \
              "ETB3 : Host 2 : zone admin sur domaine supplémentaire" \
              "envole" \
              "envole.etb3.lan" \
              "10.3.2.10" \
              "PRESENCE_HOST" \
              "PRESENCE_DIG" \
              "PRESENCE_DIG_INVERSE"
    
    doUseCase "${DIG_HOST}" \
              "ETB3 : Host 3 : Le serveur DNS ne résoud pas un nom d'host déclaré dans un autre domaine (Pas de ANSWER SECTION)." \
              "smbsrv" \
              "smbsrv.domsupp1.lan" \
              "10.3.2.30" \
              "PRESENCE_HOST" \
              "PRESENCE_DIG" \
              "PRESENCE_DIG_INVERSE"
    
    doUseCase "${DIG_HOST}" \
              "ETB3 : Host 4 : zone admin, domaine inexistant :\n Un domaine déclaré dans l' hôte 'pc-linux.dominexistant.lan' (host supplémentaire) est traité comme un domaine local supplémentaire." \
              "pc-linux" \
              "pc-linux.dominexistant.lan" \
              "10.3.2.51" \
              "PRESENCE_HOST" \
              "ABSENCE_DIG" \
              "ABSENCE_DIG_INVERSE"
    echo "ATTENTION FIXME #7974 (devrait être PRESENCE_DIG PRESENCE_DIG_INVERSE?)"
    
    doUseCase "${DIG_HOST}" \
              "ETB3 : Host 5 host avec une adresse IP externe au serveur amon.etb1.lan :\nLe DNS n'est pas master d'une plage d'adresse IP externe au serveur amon.etb1.ac-test.fr (Pas de ANSWER SECTION)." \
              "horsplage" \
              "horsplage.etb3.lan" \
              "10.3.10.5" \
              "PRESENCE_HOST" \
              "ABSENCE_DIG" \
              "ABSENCE_DIG_INVERSE"
    
    doUseCase "${DIG_HOST}" \
              "ETB3 : Authentification NTLM/SMB : scribe " \
              "scribe" \
              "scribe.etb3.lan" \
              "10.3.2.3" \
              "PRESENCE_HOST_SANS_NOM_COURT" \
              "PRESENCE_DIG" \
              "PRESENCE_DIG_INVERSE"
fi

echo "*****************************************"
echo "SORTIE = $RESULT"
exit "$RESULT"
