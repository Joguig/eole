#!/bin/bash
# shellcheck disable=SC2034,SC2148,SC2009

# shellcheck disable=SC1091
source /root/getVMContext.sh NO_DISPLAY

# shellcheck disable=SC1091
source /dev/stdin </mnt/eole-ci-tests/scripts/imagesNonEole/functions.sh

/bin/bash /mnt/eole-ci-tests/scripts/service/CheckUpdate.sh

echo "FRESHINSTALL_IMAGE=$FRESHINSTALL_IMAGE"
echo "DAILY_IMAGE=$DAILY_IMAGE"
IMAGE_FINALE=${1:-$DAILY_IMAGE}
IMAGE_SOURCE=${2:-$FRESHINSTALL_IMAGE}
echo "IMAGE_SOURCE=$IMAGE_SOURCE"
echo "IMAGE_FINALE=$IMAGE_FINALE"
export DEBIAN_FRONTEND=noninteractive

ciPrintMsgMachine "* installRobot"
if [ ! -f "/etc/lsb-release" ]
then
    ciPrintMsg "robot.fi doit etre ubuntu "
    exit 1
fi

export APT_OPTS=""
bootEn1024x768
doUpgrade
apt-get install "$APT_OPTS" -y less
apt-get install "$APT_OPTS" -y xauth
apt-get install "$APT_OPTS" -y iputils-ping
apt-get install "$APT_OPTS" -y dnsutils
apt-get install "$APT_OPTS" -y zerofree
apt-get install "$APT_OPTS" -y vim
apt-get install "$APT_OPTS" -y iputils-arping 
apt-get install "$APT_OPTS" -y ldap-utils
apt-get install "$APT_OPTS" -y telnet 
apt-get install "$APT_OPTS" -y python-all python-imaging python-twisted python-dev 
apt-get install "$APT_OPTS" -y debconf-i18n debconf-utils
apt-get install "$APT_OPTS" -y openssh-server
apt-get install "$APT_OPTS" -y openssl
apt-get install "$APT_OPTS" -y lighttpd
apt-get install "$APT_OPTS" -y xvfb
apt-get install "$APT_OPTS" -y firefox firefox-locale-fr

removeServiceResolvConf
removeServicesGenant
sshAccesRoot
installPip
installRobotFramework
tagImage
