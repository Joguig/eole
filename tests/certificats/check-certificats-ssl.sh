#!/bin/bash

testSSLPort()
{
  echo "SSLPort $1 ${IP_LOCAL} $titre"
  echo "x" | timeout 10 openssl s_client -connect "$1" -servername "$HOSTNAME_LONG" -showcerts 2>/tmp/showcerts.err >/tmp/showcerts
  cdu=$?
  if [ "$cdu" == "0" ]
  then
    grep "Verification:" </tmp/showcerts  | sed 's/^/    /'
    grep "subject=" </tmp/showcerts | sed 's/^/    /'
    grep "issuer=" </tmp/showcerts | sed 's/^/    /'
    grep "Cipher is " </tmp/showcerts  | sed 's/^/    /'
    echo ""
    return 0
  fi
  
  if [ "$cdu" == "1" ]
  then
      if grep "CONNECTED(00000003)" </tmp/showcerts
      then
         grep "Verification:" </tmp/showcerts  | sed 's/^/    /'
         grep "subject=" </tmp/showcerts | sed 's/^/    /'
         grep "issuer=" </tmp/showcerts | sed 's/^/    /'
         grep "Cipher is " </tmp/showcerts  | sed 's/^/    /'
         echo ""
         return 0
      fi
  fi

  echo "---------------------------------"
  echo "ERREUR:  $1 -> $cdu"
  cat /tmp/showcerts
  echo "---------------------------------"
  cat /tmp/showcerts.err
  echo "---------------------------------"
  RESULT="1"
  echo ""
}

testAccesSSL()
{
	local port="${1}"
    local titre="${2}"
#	local testSSLV3="${2}"
	
	if netstat -ntl| grep "127.0.0.1:$port " >/dev/null
	then
	    echo "********************************"
    	testSSLPort "127.0.0.1:$port"
	    echo "********************************"
	    return
	fi

	if netstat -ntl| grep "0.0.0.0:$port " >/dev/null
	then
	    echo "********************************"
    	testSSLPort "127.0.0.1:$port"
    	testSSLPort "$IP_LOCAL:$port"
	    echo "********************************"
	    return
	fi
}

testAccesHTTPS()
{
	local port="${1}"
    local titre="${2}"
    echo "testAccesHTTPS $port"
    
    if netstat -ntl| grep "127.0.0.1:$port "
    then
        echo "********************************"
        #testSSLPort "127.0.0.1:$port"
        if ciVersionMajeurAvant "2.9.0"
        then
            curl --connect-timeout 5 -vvI "https://127.0.0.1:$port/"
        else
            echo "Curl avec SNI "
            # https://stackoverflow.com/questions/12941703/use-curl-with-sni-server-name-indication
            curl --connect-timeout 5 --resolve "$HOSTNAME_LONG:$port:127.0.0.1" -vvI "https://127.0.0.1:$port/"
        fi
        echo "curl -> $?"

        echo "********************************"
    fi

    if netstat -ntl| grep "0.0.0.0:$port "
    then
        echo "********************************"
        #testSSLPort "$IP_LOCAL:$port"
        if ciVersionMajeurAvant "2.9.0"
        then
            curl --connect-timeout 5 -vvI "https://$IP_LOCAL:$port/"
        else
            echo "Curl avec SNI "
            # https://stackoverflow.com/questions/12941703/use-curl-with-sni-server-name-indication
            curl --connect-timeout 5 --resolve "$HOSTNAME_LONG:$port:$IP_LOCAL" -vvI "https://$IP_LOCAL:$port/"
        fi
        echo "curl -> $?"

        echo "********************************"
    fi
}

function AfficheCertificatWithCreole()
{
	if ! command -v CreoleGet >/dev/null
	then
		return 0	
	fi

	SERVER_CERT=$(CreoleGet server_cert "")
	if [ -n "${SERVER_CERT}" ]
	then
	    echo "  Affiche info certificat Server ${IP_LOCAL} ${SERVER_CERT}"
		openssl x509 -in "${SERVER_CERT}" -noout -issuer -subject -dates | sed 's/^/    /'
	fi
	APACHE_CERT=$(CreoleGet apache_cert "")
	if [ -n "${APACHE_CERT}" ]
	then
	    echo "  Affiche info certificat Apache ${IP_LOCAL} ${APACHE_CERT}"
		if [ "${APACHE_CERT}" != "${SERVER_CERT}" ]
		then
			openssl x509 -in "${APACHE_CERT}" -noout -issuer -subject -dates | sed 's/^/    /'
		else
			echo "    certificat Apache idem Server : ok"
		fi
	fi
	EOLESSO_CERT=$(CreoleGet eolesso_cert "")
	if [ -n "${EOLESSO_CERT}" ]
	then
	    echo "  Affiche info certificat EoleSSO ${IP_LOCAL} ${EOLESSO_CERT}"
		if [ "${EOLESSO_CERT}" != "${SERVER_CERT}" ]
		then
			openssl x509 -in "${EOLESSO_CERT}" -noout -issuer -subject -dates | sed 's/^/    /'
		else
			echo "    certificat EoleSSO idem Server : ok"
		fi
	fi

    AD_SERVER_FULLNAME=$(CreoleGet ad_server_fullname "")
    if [ -n "${AD_SERVER_FULLNAME}" ]
    then
        echo "  Affiche info accès LDAPS vers Samba ${IP_LOCAL} ${AD_SERVER_FULLNAME}"
        echo "x" | timeout 10 openssl s_client -connect "${AD_SERVER_FULLNAME}:636" -quiet

        echo "  Check wget nginx https://${AD_SERVER_FULLNAME}"
        wget --no-check-certificate https://"${AD_SERVER_FULLNAME}"
    fi

}

function AfficheCertificatWithoutCreole()
{
    if [ -f /usr/lib/eole/samba4.sh ]
    then
        # shellcheck disable=SC1091,SC1090
        . /usr/lib/eole/samba4.sh
        if declare -F check_certificat_samba
        then 
            # force la vérification et le renouvellement des certificats
            echo "Force la vérification et le renouvellement des certificats (avec un délai de 100000000s)"
            check_certificat_samba 100000000
        else
            echo "pas de fonction 'check_certificat_samba' sur cette version" 
        fi
    fi

    echo "Certificat SAMBA LDAPS :"
    TLS_ENABLED=$(testparm -s --parameter-name='tls enabled' 2>/dev/null)
    if [ "${TLS_ENABLED^^}" = YES ]
    then
        printf ".  %s => " "Certificat"
        TLS_CERTFILE=$(testparm -s --parameter-name='tls certfile' 2>/dev/null)
        if [ -f "${TLS_CERTFILE}" ]
        then
            if ! openssl x509 -enddate -noout -in "${TLS_CERTFILE}" -checkend 604800 >/tmp/samba_cert.info
            then
                if ! openssl x509 -enddate -noout -in "${TLS_CERTFILE}" -checkend 0 >/tmp/samba_cert.info
                then
                    MSG=$(awk -F= '/notAfter/ { print $2; }' /tmp/samba_cert.info)
                    echo "ERREUR: Expiré (${MSG})"
                else
                    MSG=$(awk -F= '/notAfter/ { print $2; }' /tmp/samba_cert.info)
                    echo  "Expiration dans moins d'une semaine (${MSG})"
                fi
            else
                MSG=$(awk -F= '/notAfter/ { print $2; }' /tmp/samba_cert.info)
                echo "Ok (${MSG})"
            fi
        else
            echo "Fichier CERT ${TLS_CERTFILE} manquant"
        fi
        printf ".  %s => " "CA"
        TLS_CAFILE=$(testparm -s --parameter-name='tls cafile' 2>/dev/null)
        if [ -f "${TLS_CAFILE}" ]
        then
            if ! openssl x509 -enddate -noout -in "${TLS_CAFILE}" -checkend 604800 >/tmp/samba_cert.info
            then
                if ! openssl x509 -enddate -noout -in "${TLS_CAFILE}" -checkend 0 >/tmp/samba_cert.info
                then
                    MSG=$(awk -F= '/notAfter/ { print $2; }' /tmp/samba_cert.info)
                    echo "ERREUR: Expiré (${MSG})"
                else
                    MSG=$(awk -F= '/notAfter/ { print $2; }' /tmp/samba_cert.info)
                    echo  "Expiration dans moins d'une semaine (${MSG})"
                fi
            else
                MSG=$(awk -F= '/notAfter/ { print $2; }' /tmp/samba_cert.info)
                echo "Ok (${MSG})"
            fi
        else
            echo  "Fichier CA ${TLS_CAFILE} manquant"
        fi
    else
        printf ".  %s => " "LDAPS"
        echo "Supportée"
    fi
    echo
    #echo | openssl s_client -servername shellhacks.com -connect shellhacks.com:443 2>/dev/null | openssl x509

}

function TestsSSL()
{
    export DEBIAN_FRONTEND=noninteractive
	if ! command -v timeout >/dev/null
	then
		apt-get -y install timeout 
	fi
	if ! command -v netstat >/dev/null
	then
		apt-get -y install net-tools
	fi
	if ! command -v curl >/dev/null
	then
		apt-get -y install curl
	fi
	
	if [ -f /etc/eole/samba4-vars.conf ]
	then
		# shellcheck disable=SC1091,SC1090
		. /etc/eole/samba4-vars.conf
		IP_LOCAL=$AD_HOST_IP
		if [ "${VM_MODULE}" == seth ]
		then
			echo "IP_LOCAL=${IP_LOCAL} sur Seth !"    
		else
			echo "IP_LOCAL=${IP_LOCAL} dans Conteneur !"    
		fi	
	else
		IP_LOCAL=$VM_ETH0_IP
		echo "IP_LOCAL=${IP_LOCAL}"
	fi

	AfficheCertificatWithCreole
	AfficheCertificatWithoutCreole

	#testAccesSSL "465" bizarre ! 
    testAccesHTTPS "443" "https"
	testAccesSSL "631" CPUS
	testAccesSSL "636" LDAPS
	testAccesSSL "993" "993"
	testAccesSSL "995" IMAPS
	testAccesSSL "4200" EAD2
	testAccesHTTPS "8443" "https-alt"
	testAccesSSL "7080" ZEPHIR
}

if [ -d /var/lib/lxc/addc ]
then
	cp -f "$0" /var/lib/lxc/addc/rootfs/tmp/check-certificats-ssl.sh
    echo "Execute $0 dans le conteneur ADDC"
    lxc-attach -n addc -- /bin/bash /tmp/check-certificats-ssl.sh "$@"
	# on continue ici pour les certificats sur le Membre
fi

HOSTNAME_LONG=$(hostname -f)
echo "HOSTNAME_LONG=$HOSTNAME_LONG"
RESULT="0"
TestsSSL
exit "$RESULT"
	
