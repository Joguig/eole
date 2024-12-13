#!/bin/bash
# shellcheck disable=SC2034,SC2148,SC2009

# shellcheck disable=SC1091
source /root/getVMContext.sh

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
    
ciPrintMsgMachine "* Gateway "
if [ ! -f "/etc/lsb-release" ]
then
    ciPrintMsg "Gateway doit etre ubuntu "
    exit 1
fi

# shellcheck disable=SC1091
source /etc/lsb-release

waitAptStopped
#ciPatchFailsafeConf
#export APT_OPTS="--allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages -y "
export APT_OPTS=""
bootEn1024x768
doUpgrade
installPaquetsCommunDebianUbuntu
doAptGet install "$APT_OPTS" -y less
doAptGet install "$APT_OPTS" -y xauth
doAptGet install "$APT_OPTS" -y dnsutils
doAptGet install "$APT_OPTS" -y vim
doAptGet install "$APT_OPTS" -y net-tools
doAptGet install "$APT_OPTS" -y ethtool
doAptGet install "$APT_OPTS" -y tcpdump
#doAptGet install "$APT_OPTS" -y ntp
doAptGet install "$APT_OPTS" -y chrony
doAptGet install "$APT_OPTS" -y dnsmasq
doAptGet install "$APT_OPTS" -y python-dev
doAptGet install "$APT_OPTS" -y telnet
doAptGet install "$APT_OPTS" -y iputils-ping
doAptGet install "$APT_OPTS" -y nginx-light
doAptGet install "$APT_OPTS" -y openssl
# bug packaging debian !
#(doAptGet install "$APT_OPTS" -y openjdk-11-jdk-headless --no-install-recommends) 2>&1 | grep -v '/etc/ssl/certs/java/cacerts'
(doAptGet install "$APT_OPTS" -y openjdk-17-jdk-headless --no-install-recommends) 2>&1 | grep -v '/etc/ssl/certs/java/cacerts'
(doAptGet install "$APT_OPTS" -y openjdk-21-jdk-headless --no-install-recommends) 2>&1 | grep -v '/etc/ssl/certs/java/cacerts'
doAptGet install "$APT_OPTS" -y autossh
doAptGet install "$APT_OPTS" -y sshpass
doAptGet install "$APT_OPTS" -y graphviz
doAptGet install "$APT_OPTS" -y vncsnapshot --no-install-recommends
doAptGet install "$APT_OPTS" -y exim4-base exim4-config exim4-daemon-light --no-install-recommends
doAptGet install "$APT_OPTS" -y fetchmail --no-install-recommends
doAptGet install "$APT_OPTS" -y mailutils
doAptGet install "$APT_OPTS" -y python3-apt

#doAptGet remove "$APT_OPTS" -y nslcd
echo "******************************************"
echo " Install OpenNebula Tools CLI"
wget -q -O- https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
echo "deb https://deb.nodesource.com/node_12.x focal main" >/etc/apt/sources.list.d/nodesource.list
wget -q -O- https://downloads.opennebula.io/repo/repo.key | apt-key add -
echo "deb https://downloads.opennebula.io/repo/6.2/Ubuntu/20.04 stable opennebula" >/etc/apt/sources.list.d/opennebula.list
apt-get update
doAptGet remove "$APT_OPTS" -y opennebula-tools

doAptGet remove "$APT_OPTS" -y samba
doAptGet remove "$APT_OPTS" -y snapd
doAptGet purge snapd
doAptGet remove "$APT_OPTS" -y openjdk-11-jdk
doAptGet remove "$APT_OPTS" -y openjdk-8-jdk
doAptGet remove "$APT_OPTS" -y lighttpd

removeServiceResolvConf
removeServicesGenant
sshAccesRoot
installPip
bash install-tools-docker.sh
 #installRobotFramework : attention confilt python-openssl !
 
 
ciPrintConsole "Creation compte pcadmin pour poste client windows"
smbpasswd -an nobody
if ! id pcadmin >/dev/null
then
    useradd pcadmin
fi

# "-d /mnt" permet le montage \\sshfs\pcadmin@<gw>\eole-ci-tests depuis les postes Windows
usermod pcadmin -d /mnt
     
tagImage
