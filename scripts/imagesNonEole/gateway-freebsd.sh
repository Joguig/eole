#!/bin/bash
# shellcheck disable=SC2034,SC2148,SC2009

# shellcheck disable=SC1091
source /root/EoleCiFunctions.sh
ciGetContext

# shellcheck disable=SC1091
source /mnt/eole-ci-tests/scripts/imagesNonEole/functions.sh

/bin/bash /mnt/eole-ci-tests/scripts/service/CheckUpdate.sh

echo "FRESHINSTALL_IMAGE=$FRESHINSTALL_IMAGE"
echo "DAILY_IMAGE=$DAILY_IMAGE"
IMAGE_FINALE=${1:-$DAILY_IMAGE}
IMAGE_SOURCE=${2:-$FRESHINSTALL_IMAGE}
echo "IMAGE_SOURCE=$IMAGE_SOURCE"
echo "IMAGE_FINALE=$IMAGE_FINALE"
export DEBIAN_FRONTEND=noninteractive
    
ciPrintMsgMachine "* Gateway Freebsd"
#if [ ! -f "/etc/lsb-release" ]
#then
#    ciPrintMsg "Gateway doit etre ubuntu "
#    exit 1
#fi

ASSUME_ALWAYS_YES=yes pkg update
ASSUME_ALWAYS_YES=yes pkg upgrade

#cf. https://www.tecmint.com/pkg-command-examples-to-manage-packages-in-freebsd/
function ciPkgInstall()
{
    echo "*********************************************************"
    echo "* pkg install $1"
    ASSUME_ALWAYS_YES=yes pkg install "$1"
    #ciCheckExitCode "$?"
}

#ciPkgInstall hwinfo
ciPkgInstall less
ciPkgInstall xauth
#ciPkgInstall iputils-ping
#ciPkgInstall dnsutils
#ciPkgInstall zerofree
ciPkgInstall vim
#ciPkgInstall iputils-arping
#ciPkgInstall ldap-utils
#ciPkgInstall telnet
#ciPkgInstall python-all
#ciPkgInstall python-twisted
ciPkgInstall openssl
#ciPkgInstall lighttpd --> nginx
#ciPkgInstall smbclient
#ciPkgInstall ethtool
ciPkgInstall tcpdump
ciPkgInstall ntp
ciPkgInstall dnsmasq
#ciPkgInstall python-dev
ciPkgInstall nginx
ciPkgInstall openjdk21
ciPkgInstall autossh
ciPkgInstall sshpass
ciPkgInstall exim4-base
ciPkgInstall exim4-config
ciPkgInstall exim4-daemon-light
ciPkgInstall chrony
ciPkgInstall mailutils

sshAccesRoot
#installPip
#ciPkgInstall install-tools-docker.sh
#installRobotFramework : attention confilt python-openssl ! 
tagImage
