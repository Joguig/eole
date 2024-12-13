#!/bin/bash

log() {
    echo "$1"
}

doDownload() {
    # copy of the function __fetch_url from bootstrap-salt.sh
    # shellcheck disable=SC2086
    curl $_CURL_ARGS -L -s -f -o "$1" "$2" >/dev/null 2>&1     ||
        wget $_WGET_ARGS -q -O "$1" "$2" >/dev/null 2>&1       ||
            fetch $_FETCH_ARGS -q -o "$1" "$2" >/dev/null 2>&1 ||  # FreeBSD
                fetch -q -o "$1" "$2" >/dev/null 2>&1          ||  # Pre FreeBSD 10
                    (log "$2 failed to download to $1"; exit 4)
}


errorGuardian() {
    log "La réponse du serveur n'est pas la bonne"
    log "Vérifier votre configuration de filtrage. exit=4"
    exit 4
}

doInstallApt() {
    local URL="$1"
    local DISTRIB="$2"
    local RELEASE="$3"
    local ARCHITECTURE="$4"
    local SALT_VERSION="$5"
    local SALT_RELEASE="$6"
    
    echo "SALT_VERSION=$SALT_VERSION (override)"
    echo "SALT_RELEASE=$SALT_RELEASE (override)"

    wget --no-check-certificate -O /tmp/SALTSTACK-GPG-KEY1.pub "${URL}/${RELEASE}/${ARCHITECTURE}/${SALT_RELEASE}/SALTSTACK-GPG-KEY.pub"
    if [ -f /tmp/SALTSTACK-GPG-KEY1.pub ]
    then
       gpg --dearmor </tmp/SALTSTACK-GPG-KEY1.pub >/etc/apt/trusted.gpg.d/SALTSTACK-GPG-KEY1.gpg
    else 
        echo "* Impossible de télécharger SALTSTACK-GPG-KEY1.pub (release) !, (pb proxy ?), stop"
        wget --no-check-certificate -O /tmp/SALTSTACK-GPG-KEY.pub "${URL}/${RELEASE}/${ARCHITECTURE}/archive/${SALT_VERSION}/SALTSTACK-GPG-KEY.pub"
        if [ ! -f /tmp/SALTSTACK-GPG-KEY.pub ]
        then
          echo "* Impossible de télécharger SALTSTACK-GPG-KEY.pub (version) !, (pb proxy ?), stop"
          exit 1
        fi
        gpg --dearmor </tmp/SALTSTACK-GPG-KEY.pub >/etc/apt/trusted.gpg.d/SALTSTACK-GPG-KEY.gpg
    fi

    echo "deb [arch=${ARCHITECTURE}] ${URL}/${RELEASE}/${ARCHITECTURE}/${SALT_RELEASE} ${DISTRIB} main" >/etc/apt/sources.list.d/saltstack.list
    cat /etc/apt/sources.list.d/saltstack.list
    if ! sudo apt-get update
    then
      echo "Erreur lors de 'apt update'!, (pb proxy ?), stop"
      exit 1
    fi
    if ! sudo apt-get install -y salt-minion
    then
      echo "Erreur lors de 'apt install salt-minion'!, (pb proxy ?), stop"
      exit 1
    fi
}

doBootstrap()
{
    if [ -n "$http_proxy" ]
    then
       SALT_ARG="-H $http_proxy"
    else
       SALT_ARG=""
    fi

    ARCHITECTURE="$(dpkg --print-architecture)"
    log "ARCHITECTURE=$ARCHITECTURE"
    SALT_VERSION=$(grep "salt-version-${ARCHITECTURE}=" /tmp/installMinion.conf|sed 's/.*=//')
    log "SALT_VERSION=$SALT_VERSION"
    DISTRIB="$(lsb_release -sc)"
    log "DISTRIB=$DISTRIB"

    #############################################################################
    # Phase 3 : cas non géré !!
    #############################################################################
    case "$DISTRIB" in
        #############################################################################
        # Phase 3 : cas linuxMint jammy
        #############################################################################
        #jammy|vera|vanessa|victoria)
          #victoria Mint 21.2
          #vanessa Mint 21
          #vera Mint 21.1
          #jammy   22 04
          # Onedir
        #  doInstallApt "https://packages.broadcom.com/salt/py3/ubuntu" "jammy" "22.04" "$ARCHITECTURE" "3006" "3006" 
        #  ;;
    
        #############################################################################
        # Phase 3 : cas linuxMint focal
        #############################################################################
        #focal|hirsute|impish|uma|una|ulyana|ulyssa)
          #una     Mint 20.3
          #uma     Mint 20.2
          #Ulyssa  Mint 20.1
          #ulyana  Mint 20.0
          #impish  21 10
          #hirsute 21 04
          # legacy
          #doInstallApt "https://packages.broadcom.com/py3/ubuntu" "focal" "20.04" "$ARCHITECTURE" "3005" "3005"
          #;;

        ulyana|virginia)
          log "Cas 1 : --> 3005"
          if sudo bash -x "$saltMinionFile" "onedir" "3005"
          then
            log "install avec bootstrap ok."
            return 0
          fi
          ;;

       *)
          log "Cas général : --> 3004"
          #############################################################################
          # Phase 3 : essai ave 'stable'
          #############################################################################
          if sudo sh "$saltMinionFile" "$SALT_ARG" -x python3 -P onedir "3004"
          then
            log "install avec bootstrap ok."
            return 0
          fi
            
          #############################################################################
          # Phase 3 : essai ave 'onedir'
          #############################################################################
          log "Cas général, Erreur bootstrap --> essai stable"
          if sudo sh "$saltMinionFile" "$SALT_ARG" -x python3 -P stable "3004"
          then
            log "install avec bootstrap Onedir ok."
            return 0
          fi

          ;; 
    esac
}

doInstallMinion()
{
    log "installMinion-Futur.sh LOCAL"

    saltMinionFile="./bootstrap-salt.sh"

    doBootstrap
    log "salt-minion ok"
}

doInstallMinion