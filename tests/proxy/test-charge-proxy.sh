#!/bin/bash

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
}

function checkMaxJobs()
{
    local PROCESS_TO_COUNT="$1"
    while true
    do
        NB="$(pgrep "$PROCESS_TO_COUNT" |wc -l)"
        if [ "${NB}" -lt 50 ]
        then
            return "${NB}"
        fi
        printf "."
        sleep 5
    done
    return 0
}

function waitEndJobs()
{
    local PROCESS_TO_COUNT="$1"
    local NB
    SECONDS=0   # Reset $SECONDS; counting of seconds will (re)start from 0(-ish).
    while (( SECONDS < 300 )); do
        NB="$(pgrep "$PROCESS_TO_COUNT" |wc -l)"
        if [ "${NB}" -lt 5 ]
        then
            return 0
        else
            echo "$SECONDS, attente !"
            sleep 10
        fi
    done
    echo "ERREUR: après $SECONDS, reste $NB $PROCESS_TO_COUNT en cours!"
    return 1
}

function ciCurlProxy()
{
    local TEMP
    local USERNAME
    local PASSWORD
    
    TEMP="$(mktemp -d /tmp/curl.XXXXXX)"
    USERNAME="${1}"
    shift 
    PASSWORD="${1}"
    shift 
    URL="${1}"
    shift 
    REPONSE_ATTENDUE="${1}"
    shift 
    
    if [ "$MODE" == asynchrone ]
    then
        checkMaxJobs curl
        TIMEOUT_MAX=3
    else
        TIMEOUT_MAX=1
    fi
    NB="$?"
    mkdir -p "${TEMP}" || true
    echo "${USERNAME} ${PASSWORD} ${URL} ${REPONSE_ATTENDUE}" >>/root/audit.test 
    /bin/rm "${TEMP}/*.log" 1>/dev/null 2>/dev/null || true
    echo curl \
         --insecure \
         --proxy "${HOST_PROXY_IP}:${HOST_PROXY_PORT}" \
         --proxy-basic \
         --proxy-user "${USERNAME}:${PASSWORD}" \
         --max-time "$TIMEOUT_MAX" \
         -H "\'user-agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:92.0) Gecko/20100101 Firefox/92.0\'" \
         -L \
         \""${URL}"\" \
         "$@" \
         1>"${TEMP}/curl.cmd"

    curl \
         --insecure \
         --proxy "${HOST_PROXY_IP}:${HOST_PROXY_PORT}" \
         --proxy-basic \
         --proxy-user "${USERNAME}:${PASSWORD}" \
         --max-time "$TIMEOUT_MAX" \
         -H 'user-agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:92.0) Gecko/20100101 Firefox/92.0' \
         -L \
         "${URL}" \
         "$@" \
         1>"${TEMP}/curl.html" \
         2>"${TEMP}/curl.log"
         
    local RESULT=$?
    case $RESULT in
        0)  if grep "EOLE Guardian" "${TEMP}/curl.html" >/dev/null
            then
                if [ "$REPONSE_ATTENDUE" == "SITE_INTERDIT" ]
                then
                    # ok normal
                    #echo "$REPONSE_ATTENDUE : OK ($URL)  $NB"
                    printf "+"
                    /bin/rm -rf "${TEMP}"
                    return 0
                else
                    echo "$REPONSE_ATTENDUE : 407 ($USERNAME $URL : ${TEMP}/curl.html)  $NB"
                    return 1
                fi
            fi
            if grep "ERROR: Cache Access Denied" "${TEMP}/curl.html" >/dev/null
            then
                #cat "${TEMP}/curl.html"
                echo "$REPONSE_ATTENDUE : ERROR: Cache Access Denied ($USERNAME $URL : ${TEMP}/curl.html) $NB"
                return 1
            fi
            if grep "400 Bad Request" "${TEMP}/curl.html" >/dev/null
            then
                if [ "$REPONSE_ATTENDUE" == "BAD_REQUEST" ]
                then
                    # ok normal
                    echo "$REPONSE_ATTENDUE : OK ($URL) $NB"
                    #printf "+"
                    return 0
                else
                    #cat "${TEMP}/curl.html"
                    echo "$REPONSE_ATTENDUE : ERREUR 400 Bad Request ($USERNAME $URL : ${TEMP}/curl.html)  $NB"
                    return 1
                fi
            fi
            if grep "407 Access denied" "${TEMP}/curl.html" >/dev/null
            then
                if [ "$REPONSE_ATTENDUE" == "SITE_INTERDIT" ]
                then
                    # ok normal
                    #echo "$REPONSE_ATTENDUE : OK ($URL)  $NB"
                    printf "+"
                    return 0
                else
                    #cat "${TEMP}/curl.html"
                    echo "$REPONSE_ATTENDUE : 407 ($USERNAME $URL : ${TEMP}/curl.html)  $NB"
                    return 1
                fi
            fi
            if grep "Veuillez configurer le proxy" "${TEMP}/curl.html" >/dev/null
            then
                if [ "$REPONSE_ATTENDUE" == "ALERTE_EOLE" ]
                then
                    echo "$REPONSE_ATTENDUE : OK ($URL) $NB"
                    return 0
                else
                    echo "$REPONSE_ATTENDUE : page type eole ($USERNAME $URL : ${TEMP}/curl.html) $NB"
                    return 1
                fi
            fi
            if [ "$REPONSE_ATTENDUE" == "SITE_AUTORISE" ]
            then
                #echo "$REPONSE_ATTENDUE : OK ($URL) $NB"
                printf "+"
                /bin/rm -rf "${TEMP}"
                return 0
            fi
            if [ "$REPONSE_ATTENDUE" == "SITE_INTERDIT" ]
            then
                #echo "$REPONSE_ATTENDUE : OK ($URL) $NB"
                printf "+"
                /bin/rm -rf "${TEMP}"
                return 0
            fi
            echo "$REPONSE_ATTENDUE : inattendue ! ($URL) $NB"
            return 1
            ;;
       1)  echo "CURL=$RESULT : Unsupported protocol. This build of curl has no support for this protocol. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       2)  echo "CURL=$RESULT : Failed to initialize. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       3)  echo "CURL=$RESULT : URL malformed. The syntax was not correct. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       4)  echo "CURL=$RESULT : A feature or option that was needed to perform the desired request was not enabled or was explicitly disabled at build-time. To make curl able to do this, you probably need another build of libcurl! ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       5)  echo "CURL=$RESULT : Couldn't resolve proxy. The given proxy host could not be resolved. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       6)  echo "CURL=$RESULT : Couldn't resolve host. The given remote host was not resolved. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       7)  echo "CURL=$RESULT : Failed to connect to host. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       8)  echo "CURL=$RESULT : Weird server reply. The server sent data curl couldn't parse. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       9)  echo "CURL=$RESULT : FTP access denied. The server denied login or denied access to the particular resource or directory you wanted to reach. Most often you tried to change to a directory that doesn't exist on the server. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       10) echo "CURL=$RESULT : FTP accept failed. While waiting for the server to connect back when an active FTP session is used, an error code was sent over the control connection or similar. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       11) echo "CURL=$RESULT : FTP weird PASS reply. Curl couldn't parse the reply sent to the PASS request. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       12) echo "CURL=$RESULT : During an active FTP session while waiting for the server to connect back to curl, the timeout expired. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       13) echo "CURL=$RESULT : FTP weird PASV reply, Curl couldn't parse the reply sent to the PASV request. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       14) echo "CURL=$RESULT : FTP weird 227 format. Curl couldn't parse the 227-line the server sent. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       15) echo "CURL=$RESULT : FTP can't get host. Couldn't resolve the host IP we got in the 227-line. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       16) echo "CURL=$RESULT : HTTP/2 error. A problem was detected in the HTTP2 framing layer. This is somewhat generic and can be one out of several problems, see the error message for details. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       17) echo "CURL=$RESULT : FTP couldn't set binary. Couldn't change transfer method to binary. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       18) echo "CURL=$RESULT : Partial file. Only a part of the file was transferred. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       19) echo "CURL=$RESULT : FTP couldn't download/access the given file, the RETR (or similar) command failed. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       21) echo "CURL=$RESULT : FTP quote error. A quote command returned error from the server. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       22) echo "CURL=$RESULT : HTTP page not retrieved. The requested url was not found or returned another error with the HTTP error code being 400 or above. This return code only appears if -f, --fail is used. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       23) echo "CURL=$RESULT : Write error. Curl couldn't write data to a local filesystem or similar. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       25) echo "CURL=$RESULT : FTP couldn't STOR file. The server denied the STOR operation, used for FTP uploading. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       26) echo "CURL=$RESULT : Read error. Various reading problems. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       27) echo "CURL=$RESULT : Out of memory. A memory allocation request failed. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       28) #echo "CURL=$RESULT : Operation timeout. The specified time-out period was reached according to the conditions. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       30) echo "CURL=$RESULT : FTP PORT failed. The PORT command failed. Not all FTP servers support the PORT command, try doing a transfer using PASV instead! ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       31) echo "CURL=$RESULT : FTP couldn't use REST. The REST command failed. This command is used for resumed FTP transfers.($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       33) echo "CURL=$RESULT : HTTP range error. The range 'command' didn't work. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       34) echo "CURL=$RESULT : HTTP post error. Internal post-request generation error. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       35) echo "CURL=$RESULT : SSL connect error. The SSL handshaking failed. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       36) echo "CURL=$RESULT : Bad download resume. Couldn't continue an earlier aborted download. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       37) echo "CURL=$RESULT : FILE couldn't read file. Failed to open the file. Permissions? ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       38) echo "CURL=$RESULT : LDAP cannot bind. LDAP bind operation failed. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       39) echo "CURL=$RESULT : LDAP search failed. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       41) echo "CURL=$RESULT : Function not found. A required LDAP function was not found. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       42) echo "CURL=$RESULT : Aborted by callback. An application told curl to abort the operation. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       43) echo "CURL=$RESULT : Internal error. A function was called with a bad parameter. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       45) echo "CURL=$RESULT : Interface error. A specified outgoing interface could not be used. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       47) echo "CURL=$RESULT : Too many redirects. When following redirects, curl hit the maximum amount. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       48) echo "CURL=$RESULT : Unknown option specified to libcurl. This indicates that you passed a weird option to curl that was passed on to libcurl and rejected. Read up in the manual! ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       49) echo "CURL=$RESULT : Malformed telnet option. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       51) echo "CURL=$RESULT : The peer's SSL certificate or SSH MD5 fingerprint was not OK. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       52) echo "CURL=$RESULT : The server didn't reply anything, which here is considered an error. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       53) echo "CURL=$RESULT : SSL crypto engine not found. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       54) echo "CURL=$RESULT : Cannot set SSL crypto engine as default. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       55) echo "CURL=$RESULT : Failed sending network data. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       56) echo "CURL=$RESULT : Failure in receiving network data. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       58) echo "CURL=$RESULT : Problem with the local certificate. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       59) echo "CURL=$RESULT : Couldn't use specified SSL cipher. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       60) echo "CURL=$RESULT : Peer certificate cannot be authenticated with known CA certificates. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       61) echo "CURL=$RESULT : Unrecognized transfer encoding. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       62) echo "CURL=$RESULT : Invalid LDAP URL. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       63) echo "CURL=$RESULT : Maximum file size exceeded. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       64) echo "CURL=$RESULT : Requested FTP SSL level failed. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       65) echo "CURL=$RESULT : Sending the data requires a rewind that failed. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       66) echo "CURL=$RESULT : Failed to initialise SSL Engine. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       67) echo "CURL=$RESULT : The user name, password, or similar was not accepted and curl failed to log in. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       68) echo "CURL=$RESULT : File not found on TFTP server. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       69) echo "CURL=$RESULT : Permission problem on TFTP server. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       70) echo "CURL=$RESULT : Out of disk space on TFTP server. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       71) echo "CURL=$RESULT : Illegal TFTP operation. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       72) echo "CURL=$RESULT : Unknown TFTP transfer ID. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       73) echo "CURL=$RESULT : File already exists (TFTP). ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       74) echo "CURL=$RESULT : No such user (TFTP). ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       75) echo "CURL=$RESULT : Character conversion failed. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       76) echo "CURL=$RESULT : Character conversion functions required. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       77) echo "CURL=$RESULT : Problem with reading the SSL CA cert (path? access rights?). ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       78) echo "CURL=$RESULT : The resource referenced in the URL does not exist. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       79) echo "CURL=$RESULT : An unspecified error occurred during the SSH session. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       80) echo "CURL=$RESULT : Failed to shut down the SSL connection. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       82) echo "CURL=$RESULT : Could not load CRL file, missing or wrong format (added in 7.19.0). ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       83) echo "CURL=$RESULT : Issuer check failed (added in 7.19.0). ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       84) echo "CURL=$RESULT : The FTP PRET command failed ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       85) echo "CURL=$RESULT : RTSP: mismatch of CSeq numbers ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       86) echo "CURL=$RESULT : RTSP: mismatch of Session Identifiers ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       87) echo "CURL=$RESULT : unable to parse FTP file list ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       88) echo "CURL=$RESULT : FTP chunk callback reported error ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       89) echo "CURL=$RESULT : No connection available, the session will be queued ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       90) echo "CURL=$RESULT : SSL public key does not matched pinned public key ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       91) echo "CURL=$RESULT : Invalid SSL certificate status. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
       92) echo "CURL=$RESULT : Stream error in HTTP/2 framing layer. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
      130) echo "CURL=$RESULT : erreur inconnue ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
           ;;
       *)  echo "CURL=$RESULT : More error codes will appear here in future releases. The existing ones are meant to never change. ($USERNAME $URL : ${TEMP}/curl.html ${TEMP}/curl.log)"
            ;;
    esac
    return $RESULT
}
function doTestProxyToUser()
{
    local numero
    local login
    local password
    
    numero="${1}"
    if [ "$numero" = "numero" ]
    then
        # entete !
        return 0 
    fi
    login="${2}@domscribe.ac-test.fr"
    password="${3}"
    
    # site basique
    ciCurlProxy "$login" "$password" "http://www.google.fr/" SITE_AUTORISE
    #ciCurlProxy "$login" "$password" "http://dev-eole.ac-dijon.fr/" BAD_REQUEST
    
    while IFS=',' read -r URL ACTION
    do
        if [ "$MODE" == synchrone ]
        then
            ciCurlProxy "$login" "$password" "http://$URL" "$ACTION"
        else
            ( ciCurlProxy "$login" "$password" "http://$URL" "$ACTION" ) &
        fi 
    done </root/urls
    echo "---------------------------------------------------------------------------------------------------------------------------------"
}

function doTestProxyToAllUserFromFile()
{
    local numero
    local login
    local password
    local FICHIER
    local TYPE
    declare -a INFO_COMPTES

    FICHIER="$1"
    TYPE="$2"
    numero=""
    login=""
    password=""
    echo "doTestProxyToAllUserFromFile: FICHIER=$FICHIER TYPE=$TYPE"
    while IFS=';' read -ra INFO_COMPTES
    do
        if [ "$TYPE" = "Prof" ]
        then
            #numero;nom;prenom;sexe;date;login;password;classes;options
            #1;Prof1;Prenom;M;01011950;prof1;eole;;
            numero="${INFO_COMPTES[0]}"
            login="${INFO_COMPTES[5]}"
            password="${INFO_COMPTES[6]}"
            doTestProxyToUser "$numero" "$login" "$password" 
        fi

        if [ "$TYPE" = "Administratif" ]
        then
            #numero;nom;prenom;sexe;date;login;password;classes;options
            #1;Prof1;Prenom;M;01011950;prof1;eole;;
            numero="${INFO_COMPTES[0]}"
            login="${INFO_COMPTES[5]}"
            password="${INFO_COMPTES[6]}"
            doTestProxyToUser "$numero" "$login" "$password" 
        fi

        if [ "$TYPE" = "Eleve" ]
        then
            #numero;nom;prenom;sexe;date;classe;niveau;login;password;options
            #1;Eleve1;Prenom;M;01012000;c31;3eme;c31e1;eole;
            numero="${INFO_COMPTES[0]}"
            login="${INFO_COMPTES[7]}"
            password="${INFO_COMPTES[8]}"
            doTestProxyToUser "$numero" "$login" "$password" 
        fi
    done <"$FICHIER"
}

trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   
    printf '%s' "$var"
}


echo "Début $0 : $1"
MODE="${2:-synchrone}"
cd /tmp || exit 1
CDU=0
/bin/rm -rf "/tmp/curl.*" 2>/dev/null

HOST_PROXY_IP=proxy.ac-test.fr
HOST_PROXY_PORT=3128

# OOM_DISABLE on $DAEMON_PID
DAEMON_PID=$$
echo -17 >"/proc/${DAEMON_PID}/oom_adj"

ciResetProxy
/bin/rm /root/audit.test 2>/dev/null 1>/dev/null

if [ "$1" == "oneshot" ]
then
    echo "***********************************************************"
    doTestProxyToUser "0" "admin" "Eole12345!"
    waitEndJobs curl
fi

if [ "$1" == "highload" ]
then
    echo "***********************************************************"
    echo "* proxy: clearlogs"
    doTestProxyToAllUserFromFile "$VM_DIR_EOLE_CI_TEST/dataset/scribe/csv/Test Eleve.csv" "Eleve"
    doTestProxyToAllUserFromFile "$VM_DIR_EOLE_CI_TEST/dataset/scribe/csv/Test Prof.csv" "Prof"
    #doTestProxyToAllUserFromFile "$VM_DIR_EOLE_CI_TEST/dataset/scribe/csv/Test Administratif.csv" "Administratif"
    waitEndJobs curl

fi

echo "*******************"
echo "* wc -l /root/audit.test (nombre de curl effectué)"
wc -l /root/audit.test

echo "* wc -l /root/urls (nombre de curl a faire par user)"
wc -l /root/urls

echo "Fin $0 CDU=$CDU"
exit 0
