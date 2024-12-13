#!/bin/bash

#########################################################################################################
#
# ciGetExceptions : get Ipsets in <fichier>
#
#########################################################################################################
function ciGetExceptionsEth()
{
    declare -a REPONSE
    declare -a REPONSE_A
    PROXY_BYPASS_DOMAIN_ETH=$(CreoleGet "${1}")
    for dns in $PROXY_BYPASS_DOMAIN_ETH
    do
        echo "********** $dns *************"
        
        while /bin/true ; 
        do
            # check ALIAS
            # shellcheck disable=SC2207
			REPONSE=( $(dig +nocmd +noall +answer "$dns" |grep CNAME) )
            CNAME="${REPONSE[4]}"
            if [ -z "$CNAME" ]
            then
                CNAME=$dns
            fi
    
            # check A
            # shellcheck disable=SC2207
			REPONSE_A=( $(dig +nocmd +noall +answer "${CNAME}" |head -1) )
			if [ -z "${REPONSE_A[1]}" ]
			then
                echo "$dns -> $CNAME 0=${REPONSE_A[0]} 1=${REPONSE_A[1]} 2=${REPONSE_A[2]} 3=${REPONSE_A[3]} 4=${REPONSE_A[4]}"
                # je ne boucle pas, test et sort
                dig "${CNAME}" |grep "^${CNAME}"
                break
			else
                if (("${REPONSE_A[1]}" < "100")) 
                then
                    echo "$dns -> $CNAME ${REPONSE_A[1]} ${REPONSE_A[4]}"
                    sleep 5
                    echo "TTL trop court, j'attends un peu ..."
                else
                    dig "${CNAME}" |grep "^${CNAME}"
                    break
                fi
            fi
        done
    done
}

function ciGetExceptions()
{
    echo "* ciGetExceptions"
    for i in $(CreoleGet --list |grep proxy_bypass_domain_eth | awk -F= '{print $1;}' )
    do
        ciGetExceptionsEth "$i"
    done
}

#########################################################################################################
#
# ciGetIpsetsListe : get Ipsets in <fichier>
#
#########################################################################################################
function ciGetIpsetsListe()
{
    local TO_FILE="$1"
    local ips
    local ip
    local tmpfile

    #local D2B=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1})
    #IFS=. read -r i1 i2 i3 i4 <<< "$ip"
    #echo "${D2B[$i1]}" . "${D2B[$i2]}" . "${D2B[$i3]}". "${D2B[$i4]}"
        
    tmpfile="$(mktemp)"
    grep -h "ipset create" /usr/share/era/ipsets/* | sort >"$tmpfile"
    grep -h "ipset add" /usr/share/era/ipsets/* | sort >>"$tmpfile"
    declare ips=("4.23.*.126"
                 "4.23.*.254"
                 "4.26.*.126"
                 "4.26.*.254"
                 "4.26.*.127"
                 "4.27.*.126"
                 "8.26.*.254"
                 "8.27.*.254"
                 "8.27.*.125"
                 "8.27.*.126"
                 "8.253.*.125"
                 "8.253.*.126"
                 "8.253.*.254"
                 "8.254.*.126"
                 "8.254.*.254"
                 "8.254.*.253"
                 "185.75.143.93"
                 "192.221.*.126"
                 "198.78.*.126"
                 "204.160.*.126"
                 "205.128.*.126"
                 "205.128.*.254"
                 "206.33.*.125"
                 "206.33.*.254"
                 "207.123.*.125"
                 "207.123.*.126"
                 "207.123.*.252"
                 "207.123.*.254"
                 "208.178.*.254"
                 "209.84.*.126"
                 "209.84.*.254"
                 "93.184.221.133"
                 "93.184.221.120"
                 )
    for ip in "${ips[@]}"
    do
        pattern="${ip//./\\.}"
        pattern="${pattern//\*/.*}"
        sed -i -e "s/${pattern}/www.ac-dijon.fr/" "$tmpfile"
    done
    sort <"$tmpfile" | uniq >"${TO_FILE}"
    /bin/rm "$tmpfile"
}

#########################################################################################################
#
# Check Ipsets <absolutePath | configuration> [fichierReference]
#
#########################################################################################################
function ciCheckIpsets()
{
    if [[ ! -d "/usr/share/era/ipsets" ]]
    then
        return 0
    fi

    ciPrintMsgMachine "ciCheckIpsets"

    if ciVersionMajeurApres "2.6.2"
    then
        ciSignalHack "bastion regen"
        bastion regen
    fi
    
    ciPrintMsgMachine "do check"
    ciGetDirConfiguration
    REFERENCE_IPSETS=$DIR_CONFIGURATION/ipsets
    CURRENT_IPSETS=/tmp/ipsets.$$

    ciGetIpsetsListe "${CURRENT_IPSETS}"

    if [[ ! -f "$REFERENCE_IPSETS" ]]
    then
       ciPrintMsg "1ere fois que la commande est lancée. sauvegarde et pas d'erreur. Le fichier de référence est $REFERENCE_IPSETS"
       /bin/cp "${CURRENT_IPSETS}" "$REFERENCE_IPSETS"
       return 0
    else
       ciPrintMsg "Le fichier de référence est $REFERENCE_IPSETS"
       TMPDIFF=/tmp/ipsets_diff.$$
       ciDiff "${CURRENT_IPSETS}" "$REFERENCE_IPSETS" >"$TMPDIFF"
       RESULT="$?"
       if [[ "$RESULT" == "0" ]]
       then
           ciPrintMsg "LES REGLES IPSETS SONT CORRECTES"
           /bin/rm -f "$TMPDIFF"
           return 0
       else
           ciGrepDiff "$TMPDIFF"
           ciPrintMsg "> nouvelle par rapport au fichier de référence, < supprimée par rapport au fichier de référence, | changée par rapport au fichier de référence"
           ciSignalAlerte "LES REGLES IPSETS SONT INCORRECTES"

           IPSETS_DERNIER_FILE=${REFERENCE_IPSETS}.dernier
           RESULT="0"
           if [[ ! -f "$IPSETS_DERNIER_FILE" ]]
           then
               RESULT="1"
           else
               ciDiff "$CURRENT_IPSETS" "$IPSETS_DERNIER_FILE" >/dev/null
               RESULT="$?"
           fi

           if [ "$RESULT" == "1" ]
           then
               IPSETS_DATE_FILE=${REFERENCE_IPSETS}.$(date "+%Y-%m-%d_%H:%M:%S")
               ciPrintMsg "Sauvegarde nouveau 'ipsets' dans : $IPSETS_DERNIER_FILE"
               /bin/cp "$CURRENT_IPSETS" "$IPSETS_DERNIER_FILE"
               ciPrintMsg "Sauvegarde nouveau 'ipsets' dans historique : $IPSETS_DATE_FILE"
               /bin/cp "$CURRENT_IPSETS" "$IPSETS_DATE_FILE"
               if [[ "$VM_MAJAUTO" = "DEV" ]]
               then
                   ciPrintMsg "En mode DEV, actualise ${REFERENCE_IPSETS} !"
                   /bin/cp -f "$CURRENT_IPSETS" "${REFERENCE_IPSETS}"
               fi
           else
               ciPrintMsg "La derniere sauvegarde 'ipsets' est dans : $IPSETS_DERNIER_FILE"
           fi
           return 1
       fi
    fi
}
export -f ciCheckIpsets

# execute main si non sourcé
if [[ "${BASH_SOURCE[0]}" == "$0" ]] 
then
   ciGetDirConfiguration
   ciGetExceptions
   ciCheckIpsets
   # Attention : pas de test ici !
fi
