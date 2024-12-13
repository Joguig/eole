#!/bin/bash
# shellcheck disable=SC2034,SC2148

# code executer sur l'image à publier

# shellcheck disable=1091
source /root/getVMContext.sh

ciPrintMsg "Build Market Apps module='$VM_MODULE' versionmajeur='$VM_VERSIONMAJEUR'"

apt-get install -f -y

ciPrintMsg "* maj_auto_stable"
ciMonitor maj_auto_stable
ciCheckExitCode $? "$0 : maj_auto"

ciPrintMsg "* apt-eole install expect (on en a besoin pour l'inscriptino zephir et unattented!)"
apt-get install -y expect
ciCheckExitCode $? "$0 : install expect"

ciPrintMsg "* apt install -y eole-modele-vm (pour le script unattented"
apt-get install -y eole-modele-vm
ciCheckExitCode $? "$0 : install eole-modele-vm"

ciPrintMsg "* apt install -y one-context"
apt-cache policy one-context
apt-get install -y one-context
ciCheckExitCode $? "$0 : install one-context"



#ciPrintMsg "* apt install -y cloud-utils qemu-guest-agent (depedance opennebula-context)"
#apt install -y cloud-utils qemu-guest-agent virt-what open-vm-tools
#ciCheckExitCode $? "$0 : install cloud-utils qemu-guest-agent"
#

#declare -a URL_TO_VERSION
#IFS='"/' read -r -a URL_TO_VERSION <<< "$(wget -q https://github.com/OpenNebula/addon-context-linux/releases/latest -O - | grep '/one-context_.*.deb')"
# 0 a href=
# 1 ''
# 2 OpenNebula
# 3 addon-context-linux
# 4 releases
# 5 download
#OpenNebulaContextVersion="${URL_TO_VERSION[6]}"
#OpenNebulaContextFichier="${URL_TO_VERSION[7]}"
#OpenNebulaContextVersion="v6.4.0"
#OpenNebulaContextFichier="one-context_6.4.0-1.deb"
# 8 rel=
# 9 nofollow 
#echo "OpenNebulaContextVersion=$OpenNebulaContextVersion"
#echo "OpenNebulaContextFichier=$OpenNebulaContextFichier"
#rm -f "/tmp/${OpenNebulaContextFichier}"
#wget -O "/tmp/${OpenNebulaContextFichier}" "https://github.com/OpenNebula/addon-context-linux/releases/download/${OpenNebulaContextVersion}/${OpenNebulaContextFichier}"
#ciCheckExitCode $? "$0 : download opennebula-context"
#apt-get install -y "/tmp/${OpenNebulaContextFichier}"
#ciCheckExitCode $? "$0 : install opennebula-context"

ciPrintMsg "* apt install -y eole-genconfig-noclient"
apt install -y eole-genconfig-noclient
ciCheckExitCode $? "$0 : install eole-genconfig-noclient"

if command -v firefox
then
    ciPrintMsg "* apt remove -y firefox firefox-locale-en"
    apt remove -y firefox firefox-locale-en
fi

if command -v chromium
then
    ciPrintMsg "* apt remove -y chromium-browser chromium-codecs-ffmpeg-extra"
    apt remove -y chromium-browser chromium-codecs-ffmpeg-extra
fi

ciPrintMsg "* uname -a"
uname -a

ciPrintMsg "* apt-get -y --purge autoremove"
apt-get -y --purge autoremove 2>&1 | grep -v '/var/log/Xorg'

ciPrintMsg "* désactive systemd-resolved.service"

#systemctl disable systemd-resolved.service
#systemctl stop systemd-resolved.service

# check if resolv.conf is pointing to resolvconf
#ls -la /etc/resolv.conf
# lrwxrwxrwx 1 root root 27 May  7 16:15 /etc/resolv.conf -> /run/resolvconf/resolv.conf
# if not, delete /etc/resolv.conf and symlink it like this: 
#rm /etc/resolv.conf
#ln -s /run/resolvconf/resolv.conf /etc/resolv.conf

# this will remove the resolved stub resolver entry from resolv.conf
#resolvconf -d systemd-resolved

# fix dhclient scripts
#chmod -x /etc/dhcp/dhclient-enter-hooks.d/resolved
#chmod +x /etc/dhcp/dhclient-enter-hooks.d/resolvconf

# on my machine just chmod -x wasn't enough, I had to move the resolved script somewhere else
#mv /etc/dhcp/dhclient-enter-hooks.d/resolved ~

# ifdown/ifup your interface to regenerate resolv.conf (or systemctl restart ifup@eth0)
#ifdown ens4
#ifup ens4

# check /etc/resolv.conf has the right settings

exit 0
