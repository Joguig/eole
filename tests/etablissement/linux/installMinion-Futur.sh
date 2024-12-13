#!/bin/bash
set -e

# Penser à mettre à jour le lien vers OS supporté en cas de mise à jour dans index.html
VERSION=3007.1
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

doInstallUbuntu2004() {
    
    log "Cas doInstallUbuntu2004"
    echo "no_proxy=$no_proxy"
    echo "http_proxy=$http_proxy"

    if ! command -v curl
    then
        apt-get install -y curl
    fi
     
    mkdir -p /etc/apt/keyrings
    chmod 755 /etc/apt/keyrings
    doDownload "/etc/apt/keyrings/eole-outils.gpg" "http://eole.ac-dijon.fr/outils/project/outils.asc"
    if [ ! -f /etc/apt/keyrings/eole-outils.gpg ]
    then
        echo "* Impossible de télécharger outils.asc !, (pb proxy ?), stop"
        exit 1
    fi
    chmod 644 /etc/apt/keyrings/eole-outils.gpg

    echo 'Package: salt-*
Pin: version '${VERSION}'.*
Pin-Priority: 1001' | sudo tee /etc/apt/preferences.d/salt-pin-1001
   
    echo "deb [signed-by=/etc/apt/keyrings/eole-outils.gpg arch=amd64] http://test-eole.ac-dijon.fr/outils focal/snapshots/salt-${VERSION} focal main" | sudo tee /etc/apt/sources.list.d/saltstack.list
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

doInstallUbuntu2204() {
    
    log "Cas doInstallUbuntu2204"
    echo "no_proxy=$no_proxy"
    echo "http_proxy=$http_proxy"

    if ! command -v curl
    then
        apt-get install -y curl
    fi
     
    mkdir -p /etc/apt/keyrings
    chmod 755 /etc/apt/keyrings
    doDownload "/etc/apt/keyrings/eole-outils.gpg" "http://eole.ac-dijon.fr/outils/project/outils.asc"
    if [ ! -f /etc/apt/keyrings/eole-outils.gpg ]
    then
        echo "* Impossible de télécharger SALTSTACK-GPG-KEY.pub (version) !, (pb proxy ?), stop"
        exit 1
    fi
    chmod 644 /etc/apt/keyrings/eole-outils.gpg

    echo 'Package: salt-*
Pin: version '${VERSION}'.*
Pin-Priority: 1001' | sudo tee /etc/apt/preferences.d/salt-pin-1001
   
    echo "deb [signed-by=/etc/apt/keyrings/eole-outils.gpg arch=amd64] http://test-eole.ac-dijon.fr/outils focal/snapshots/salt-${VERSION} jammy main" | sudo tee /etc/apt/sources.list.d/saltstack.list
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

doInstallUbuntu2404() {
     
    log "Cas doInstallUbuntu2404"
    echo "no_proxy=$no_proxy"
    echo "http_proxy=$http_proxy"

    if ! command -v curl
    then
        apt-get install -y curl
    fi
     
    mkdir -p /etc/apt/keyrings
    chmod 755 /etc/apt/keyrings
    doDownload "/etc/apt/keyrings/eole-outils.gpg" "http://eole.ac-dijon.fr/outils/project/outils.asc"
    if [ ! -f /etc/apt/keyrings/eole-outils.gpg ]
    then
        echo "* Impossible de télécharger SALTSTACK-GPG-KEY.pub (version) !, (pb proxy ?), stop"
        exit 1
    fi
    chmod 644 /etc/apt/keyrings/eole-outils.gpg

    echo 'Package: salt-*
Pin: version '${VERSION}'.*
Pin-Priority: 1001' | sudo tee /etc/apt/preferences.d/salt-pin-1001
   
    echo "deb [signed-by=/etc/apt/keyrings/eole-outils.gpg arch=amd64] http://test-eole.ac-dijon.fr/outils focal/snapshots/salt-${VERSION} noble main" | sudo tee /etc/apt/sources.list.d/saltstack.list
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

doInstallDebian12() {
     
    log "Cas doInstallDebian12"
    echo "no_proxy=$no_proxy"
    echo "http_proxy=$http_proxy"

    if ! command -v curl
    then
        apt-get install -y curl
    fi
     
    mkdir -p /etc/apt/keyrings
    chmod 755 /etc/apt/keyrings
    doDownload "/etc/apt/keyrings/eole-outils.gpg" "http://eole.ac-dijon.fr/outils/project/outils.asc"
    if [ ! -f /etc/apt/keyrings/eole-outils.gpg ]
    then
        echo "* Impossible de télécharger SALTSTACK-GPG-KEY.pub (version) !, (pb proxy ?), stop"
        exit 1
    fi
    chmod 644 /etc/apt/keyrings/eole-outils.gpg

    echo 'Package: salt-*
Pin: version '${VERSION}'.*
Pin-Priority: 1001' | sudo tee /etc/apt/preferences.d/salt-pin-1001
   
    echo "deb [signed-by=/etc/apt/keyrings/eole-outils.gpg arch=amd64] http://test-eole.ac-dijon.fr/outils focal/snapshots/salt-${VERSION} bookworm main" | sudo tee /etc/apt/sources.list.d/saltstack.list
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

        bookworm)
          
          if  doInstallDebian12
          then
            log "install avec bootstrap ok."
            return 0
          fi
          ;;
        
        #############################################################################
        # Phase 3 : cas linuxMint 2404
        #############################################################################
        noble|wilma)
          
          if  doInstallUbuntu2404
          then
            log "install avec bootstrap ok."
            return 0
          fi
          ;;

        #############################################################################
        # Phase 3 : cas linuxMint 2204
        #############################################################################
        jammy|vera|vanessa|victoria|virginia)
          #virginia Mint 21.3
          #victoria Mint 21.2
          #vanessa Mint 21
          #vera Mint 21.1
          #jammy   22 04
          if doInstallUbuntu2204
          then
            log "install avec bootstrap ok."
            return 0
          fi
          ;;

        #############################################################################
        # Phase 3 : cas linuxMint 2004
        #############################################################################
        focal|hirsute|impish|uma|una|ulyana)
          #una     Mint 20.3
          #uma     Mint 20.2
          #Ulyssa  Mint 20.1
          #ulyana  Mint 20.0
          #impish  21 10
          #hirsute 21 04
          # legacy
          if doInstallUbuntu2004
          then
            log "install avec bootstrap ok."
            return 0
          fi
          ;;

       *)
          log "Cas général : --> $VERSION"
          #############################################################################
          # Phase 3 : essai avex 'stable'
          #############################################################################
          log "Cas général, Erreur bootstrap --> essai stable"
          if sudo sh "$saltMinionFile" "$SALT_ARG" -x python3 -P stable "$VERSION"
          then
            log "install avec bootstrap Onedir ok."
            return 0
          fi

          ;; 
    esac
}

doInstallMinion() {
    log "installMinion-Futur.sh "
    #############################################################################
    # Phase 2 : check Slat dns
    #############################################################################
    log "check 'salt' dns resolution ?"
    SaltMasterHost=$(getent hosts salt 2> /dev/null | awk '{print $2}')
    if [ -z "${SaltMasterHost}" ]
    then
        log "La résolution du nom 'salt' n'est pas fonctionnelle. Configurer l'enregistrement DNS sur le serveur DNS. exit=3"
        exit 3
    fi
    log "La résolution du nom 'salt' est fonctionnelle: ${SaltMasterHost}"
    export no_proxy="salt,${SaltMasterHost}"
    
    #############################################################################
    # Phase 2 : get installMinion.conf
    #############################################################################
    doDownload /tmp/installMinion.conf http://salt/joineole/installMinion.conf
    if [ ! -f /tmp/installMinion.conf ]
    then
        echo "Impossible de télécharger http://salt/joineole/installMinion.conf !, (pb proxy ?), stop"
        exit 1
    fi
    cat /tmp/installMinion.conf
    
    #############################################################################
    # Phase 3 : téléchargement de 'bootstrap-salt' depuis le scribe
    #############################################################################
    saltMinionUrl="http://$SaltMasterHost/joineole/bootstrap-salt/bootstrap-salt.sh"
    saltMinionFile="/tmp/bootstrap-salt.sh"
    if [ -f "$saltMinionFile" ]
    then
        /bin/rm -f "$saltMinionFile"
    fi
    doDownload "$saltMinionFile" "$saltMinionUrl"
    if [ -f "$saltMinionFile.sha256" ]
    then
       /bin/rm -f "$saltMinionFile.sha256"
    fi
    doDownload "$saltMinionFile.sha256" "$saltMinionUrl.sha256"
    cd /tmp
    sha256sum -c "$saltMinionFile.sha256"
    cd -
    if grep -q guardian "$saltMinionFile" 
    then
       errorGuardian
    fi

    #############################################################################
    # Phase 7 : install du service ?
    #############################################################################
    doBootstrap
    
    #############################################################################
    # Phase 8 : configuration du minion avant re démarrage
    ######### ####################################################################
    if [ ! -f /salt/conf/minion.d/startup.conf ]; then
        log "---"
        log "Ecriture de /salt/conf/minion.d/startup.conf"
        sudo salt-call --local file.write /etc/salt/minion.d/startup.conf 'startup_states: hightstate'
        log "Ajout des rôles ad/member, veyon/master et veyon/client"
        sudo salt-call --local grains.append roles '["ad/member", "veyon/master", "veyon/client"]'

        #############################################################################
        # Phase 9 : redémarrage
        #############################################################################
        log "restart salt-minion..."
        sudo systemctl restart salt-minion.service
        
        log "force state.highstate apply..."
        sudo salt-call -l info state.highstate apply
    fi
    log "salt-minion ok"
}

doInstallMinion

exit 0
