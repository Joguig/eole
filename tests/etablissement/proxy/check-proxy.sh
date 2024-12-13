#!/bin/bash

function checkAccesDenied()
{
    if [ ! -f "$1" ]
    then
        echo "checkAccesDenied : pas de réponse"
        return 1
    fi
    
    if grep "407 Access denied" "$1" >/dev/null
    then
        #cat $1
        echo "checkAccesDenied : ERREUR ACCES REFUSE 407 ($1)"
        return 1
    fi
    if grep "Veuillez configurer le proxy" "$1" >/dev/null
    then
        #cat $1
        echo "checkAccesDenied : ERREUR ACCES REFUSE page type eole ($1)"
        return 1
    fi
    echo "checkAccesDenied : ACCES AUTORISÉ ($1)"
    return 0
}

function checkEOLE()
{
    if [ ! -f "$1" ]
    then
        echo "checkEOLE : pas de réponse"
        return 1
    fi
    
    if grep "<h1>Ensemble Ouvert Libre" "$1" >/dev/null
    then
        echo "checkEOLE : OK ($1)"
        return 0
    else
        #cat $1
        echo "checkEOLE : ERREUR ($1)"
        return 1
    fi
}

function checkGoogle()
{
    if [ ! -f "$1" ]
    then
        echo "checkGoogle : pas de réponse"
        return 1
    fi
    
    if grep "<title>Google</title>" "$1" >/dev/null
    then
        echo "checkGoogle : OK ($1)"
        return 0
    else
        #cat $1
        echo "checkGoogle : ERREUR ($1)"
        return 1
    fi
}

function ciResetProxy()
{
    unset http_proxy
    unset https_proxy
    unset ftp_proxy
    unset rsync_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset FTP_PROXY
    unset RSYNC_PROXY
    unset no_proxy
    [ -f /root/.wgetrc ] && rm /root/.wgetrc
    [ -f /root/.netrc ] && rm /root/.netrc
    [ -f /root/.gitconfig ] && rm /root/.gitconfig
    [ -f /root/.curlrc ] && rm /root/.curlrc
    [ -f /tmp/gitproxy ] && rm /tmp/gitproxy
    [ -f /tmp/gitproxync ] && rm /tmp/gitproxync
    [ -f /etc/apt/apt.conf.d/02eoleproxy ] && rm /etc/apt/apt.conf.d/02eoleproxy
    if command -v git >>/dev/null 2>&1
    then
        git config --global http.sslVerify false
        git config --global --unset-all http.proxy
        unset GIT_PROXY_COMMAND
        unset GIT_SSL_NO_VERIFY
        unset GIT_CURL_VERBOSE
        unset GIT_DEBUG_LOOKUP
        unset GIT_TRANSLOOP_DEBUG
        unset GIT_TRANSPORT_HELPER_DEBUG
        unset GIT_TRACE_PACKET
    fi
}

function ciCheckAptGet()
{
    echo "****************************************************"
    echo "TEST APT-GET : les sites ubuntu sont dans domaines_noauth" 
    echo "****************************************************"
    if [ "$USE_PROXY" == oui ]
    then
        echo Acquire::http::Proxy "\"http://${HOST_PROXY_PREFIX}${HOST_PROXY_IP}:3128\"\;" >/etc/apt/apt.conf.d/02eoleproxy
    fi
    echo "* cat /etc/apt/apt.conf.d/02eoleproxy"
    if [ -f /etc/apt/apt.conf.d/02eoleproxy ];then
        cat /etc/apt/apt.conf.d/02eoleproxy
    else
        echo "fichier /etc/apt/apt.conf.d/02eoleproxy absent"
    fi
    
    echo "* apt-get update"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    RESULT=$?
    
    if ! command -v socat >>/dev/null 2>&1
    then
        apt-get install -y socat
    fi
    if ! command -v nc >>/dev/null 2>&1
    then
        apt-get install -y nc
    fi
    if ! command -v git >>/dev/null 2>&1
    then
        apt-get install -y git
    fi
    return $RESULT
}

function ciWGet()
{
    [ -f /tmp/wget.log ] && rm /tmp/wget.log
    wget -d -v --no-check-certificate "$@" 2>/tmp/wget.log
    local RESULT=$?
    case $RESULT in
        0)  echo "WGET=$RESULT : No problems occurred"
            ;;
        1)  echo "WGET=$RESULT : Generic error code"
            ;;    
        2)  echo "WGET=$RESULT : Parse error — for instance, when parsing command-line options, the .wgetrc or .netrc…"
            ;;    
        3)  echo "WGET=$RESULT : File I/O error"
            ;;    
        4)  echo "WGET=$RESULT : Network failure"
            ;;    
        5)  echo "WGET=$RESULT : SSL verification failure"
            ;;    
        6)  echo "WGET=$RESULT : Username/password authentication failure"
            ;;    
        7)  echo "WGET=$RESULT : Protocol errors"
            ;;    
        8)  echo "WGET=$RESULT : Server issued an error response"
            ;;
        *)  echo "WGET=$RESULT : exit code inconnue !!!!"
            ;;
    esac
    if [ "$RESULT" -ne 0 ]
    then
        cat /tmp/wget.log
    fi
    return $RESULT
}

function ciWGetProxy()
{
    ciWGet -e use_proxy=on --proxy-user=admin --proxy-passwd=eole -e http_proxy="${HOST_PROXY_IP}:${HOST_PROXY_PORT}" -e https_proxy="${HOST_PROXY_IP}:${HOST_PROXY_PORT}" --tries=2 "$@"
    return $? 
}

function ciCurl()
{
    #CURLOPT_DEBUGDATA=0
    #CURLOPT_VERBOSE=0
    [ -f /tmp/curl.log ] && rm /tmp/curl.log
    echo "curl --trace /tmp/curl.log $*"
    curl --trace /tmp/curl.log "$@" 
    local RESULT=$?
    if [ "$RESULT" -ne 0 ]
    then
        #cat /tmp/curl.log
        echo "ciCur $*"
        echo "CURL=$RESULT"
    else
        echo "CURL=$RESULT"
    fi
    return $RESULT
}

function ciCheckBpEole()
{
    ciResetProxy
    
    echo ""
    echo "*******************************************************************"
    echo "TEST bp-eole.ac-dijon.fr : le site est dans domaines_noauth" 
    [ -f /tmp/bp-eole.ac-dijon.fr.html ] && rm /tmp/bp-eole.ac-dijon.fr.html
    if [ "$USE_PROXY" == oui ]
    then
        ciWGetProxy http://bp-eole.ac-dijon.fr/ -O /tmp/bp-eole.ac-dijon.fr.html
    else
        ciWGet --tries=2 http://bp-eole.ac-dijon.fr/ -O /tmp/bp-eole.ac-dijon.fr.html
    fi
    checkAccesDenied /tmp/bp-eole.ac-dijon.fr.html || return $?
    checkEOLE /tmp/bp-eole.ac-dijon.fr.html || return $?
    return 0
}

function ciCheckGoogle()
{
    ciResetProxy
    
    echo ""
    echo "*******************************************************************"
    echo "TEST http://www.google.fr : le site n'est dans domaines_noauth"
    [ -f /tmp/www.google.fr.html ] && rm /tmp/www.google.fr.html
    if [ "$USE_PROXY" == oui ]
    then
        ciWGetProxy http://www.google.fr/ -O /tmp/www.google.fr.html
    else
        ciWGet "http://www.google.fr/" -O /tmp/www.google.fr.html
    fi
    checkAccesDenied /tmp/www.google.fr.html || return $?
    checkGoogle /tmp/www.google.fr.html || return $?
    return 0
}

function ciCheckGoogleHttps()
{
    ciResetProxy
    
    echo ""
    echo "*******************************************************************"
    echo "TEST https://www.google.fr : le site n'est dans domaines_noauth"
    [ -f /tmp/www.google.fr.html ] && rm /tmp/www.google.fr.html
    if [ "$USE_PROXY" == oui ]
    then
        ciWGetProxy https://www.google.fr/ -O /tmp/www.google.fr.html
    else
        ciWGet "https://www.google.fr/" -O /tmp/www.google.fr.html
    fi
    checkAccesDenied /tmp/www.google.fr.html || return $?
    checkGoogle /tmp/www.google.fr.html || return $?
    return 0
}

function ciCheckDevEoleHttps()
{
    ciResetProxy
    
    echo ""
    echo "*******************************************************************"
    echo "TEST https://dev-eole.ac-dijon.fr : le site n'est dans domaines_noauth"
    [ -f /tmp/dev-eole.ac-dijon.fr.html ] && rm /tmp/dev-eole.ac-dijon.fr.html
    if [ "$USE_PROXY" == oui ]
    then
        ciWGetProxy https://dev-eole.ac-dijon.fr/ -O /tmp/dev-eole.ac-dijon.fr.html
    else
        ciWGet "https://dev-eole.ac-dijon.fr/" -O /tmp/dev-eole.ac-dijon.fr.html
    fi
    checkAccesDenied /tmp/dev-eole.ac-dijon.fr.html
    checkEOLE /tmp/dev-eole.ac-dijon.fr.html
    RESULT=$?
}

function ciCheckDevEoleHttpsGitInfoRefs()
{
    ciResetProxy
    
    echo ""
    echo "*******************************************************************"
    echo "Curl eole-proxy.git/info/refs?service=git-upload-pack !"   
    if [ "$USE_PROXY" == oui ]
    then
        ciWGetProxy "https://dev-eole.ac-dijon.fr/git/eole-proxy.git/info/refs?service=git-upload-pack" -O /tmp/git-upload-pack
    else
        ciWGet "https://dev-eole.ac-dijon.fr/git/eole-proxy.git/info/refs?service=git-upload-pack" -O /tmp/git-upload-pack
    fi    
    checkAccesDenied /tmp/git-upload-pack
    return $?
}

function ciCdu()
{
   CDU="$1"
   echo "Erreur: ciCdu $CDU"
   #exit 1
}

function ciCheckGitDevEole()
{
    ciResetProxy
    
    echo ""
    echo "*******************************************************************"
    if [ "$USE_PROXY" == oui ]
    then
       echo "git clone eole-proxy par ${HOST_PROXY_PORT}"   
       git config --global http.sslverify "false"
       git config --global http.proxy "http://${HOST_PROXY_PREFIX}${HOST_PROXY_IP}:${HOST_PROXY_PORT}"
       git config --global https.proxy "http://${HOST_PROXY_PREFIX}${HOST_PROXY_IP}:${HOST_PROXY_PORT}"
    else
       echo "git clone eole-proxy sans proxy"   
    fi
    [ -d /tmp/eole-proxy ] && rm -rf /tmp/eole-proxy
    
    #export GIT_PROXY_COMMAND=/tmp/gitproxy
    export GIT_SSL_NO_VERIFY=true
    #export GIT_CURL_VERBOSE=1
    #export GIT_DEBUG_LOOKUP=1
    #export GIT_TRANSLOOP_DEBUG=1
    #export GIT_TRANSPORT_HELPER_DEBUG=1
    #export GIT_TRACE_PACKET=1
    cd /tmp || exit 1
    git clone https://dev-eole.ac-dijon.fr/git/eole-proxy.git 
    if [ -d /tmp/eole-proxy ] 
    then
        echo "* clone OK"
        return 0
    else
        if [ -f /tmp/git.log ] 
        then
            cat /tmp/git.log
        else
            echo "* pas de fichier /tmp/git.log"
        fi
        return 1
    fi 
}

echo "Début $0"

cd /tmp || exit 1
CDU=0
USE_PROXY=oui

if [ "$VM_ETH0_NAME" == academie ]
then
    USE_PROXY=non
    echo "USE_PROXY=$USE_PROXY"
    ciCheckAptGet || ciCdu 1
    ciCheckBpEole || ciCdu 2
    ciCheckGoogle || ciCdu 3
    ciCheckGoogleHttps || ciCdu 4
    ciCheckDevEoleHttps || ciCdu 5
    ciCheckDevEoleHttpsGitInfoRefs || ciCdu 6
    ciCheckGitDevEole || ciCdu 8
fi

if [ "$VM_ETH0_NAME" == academie ]
then
    USE_PROXY=oui
    HOST_PROXY_IP=proxy.eole.lan
    HOST_PROXY_PORT=3128
    HOST_PROXY_PREFIX=

    echo "USE_PROXY=$USE_PROXY"
    echo "HOST_PROXY_IP=$HOST_PROXY_IP"
    echo "HOST_PROXY_PORT=$HOST_PROXY_PORT"
    echo "HOST_PROXY_PREFIX=$HOST_PROXY_PREFIX"
    
    ciCheckAptGet || ciCdu 11
    ciCheckBpEole || ciCdu 12
    ciCheckGoogle || ciCdu 13
    ciCheckGoogleHttps || ciCdu 14
    ciCheckDevEoleHttps || ciCdu 15
    ciCheckDevEoleHttpsGitInfoRefs || ciCdu 16
    ciCheckGitDevEole || ciCdu 18
else
    USE_PROXY=oui
    HOST_PROXY_IP=${VM_ETH0_GW}
    HOST_PROXY_PORT=3127
    HOST_PROXY_PREFIX=admin:eole@

    echo "USE_PROXY=$USE_PROXY"
    echo "HOST_PROXY_IP=$HOST_PROXY_IP"
    echo "HOST_PROXY_PORT=$HOST_PROXY_PORT"
    echo "HOST_PROXY_PREFIX=$HOST_PROXY_PREFIX"
    
    ciCheckAptGet || ciCdu 21
    (HOST_PROXY_PORT=3128 ciCheckBpEole ) || ciCdu 22
    ciCheckGoogle || ciCdu 23
    ciCheckGoogleHttps || ciCdu 24
    ciCheckDevEoleHttps || ciCdu 25
    ciCheckDevEoleHttpsGitInfoRefs || ciCdu 26
    #ciCheckGitDevEole || ciCdu 27
    #(HOST_PROXY_PORT=3128 ciCheckGitDevEole) || ciCdu 28
fi

echo "Fin $0 CDU=$CDU"
exit 0
