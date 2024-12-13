#!/bin/bash
# shellcheck disable=SC2034,SC2148,SC2009

# shellcheck disable=SC1091
source /dev/stdin </mnt/eole-ci-tests/scripts/imagesNonEole/functions.sh

ciPrintMsgMachine "* pcubuntu"
if [ ! -f "/etc/lsb-release" ]
then
    ciPrintMsg "pc-ubuntu doit etre ubuntu "
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
export APT_OPTS="-y"


#if [[ -d /etc/lightdm/lightdm.conf.d/ ]]
#then
#    if [[ -f /etc/lightdm/lightdm.conf.d/01_my.conf ]]
#    then
#       rm  /etc/lightdm/lightdm.conf.d/01_my.conf
#    else
#       echo "* pas de fichier /etc/lightdm/lightdm.conf.d/01_my.conf"
#    fi
#    
#    if [[ ! -f /etc/lightdm/lightdm.conf.d/99_my.conf ]]
#    then
#        find /etc/lightdm/lightdm.conf.d/ | while read -r F 
#        do
#            ciAfficheContenuFichier "$F" |grep -v "^#" |grep -v "^[[:space:]]*$"
#        done
#
#        cat > /etc/lightdm/lightdm.conf.d/99_my.conf << EOF
#[Seat:*]
#greeter-hide-users=false
#greeter-show-manual-login=true
#greeter-show-remote-login=true
#allow-guest=false
#type=local
#
#[LightDM]
#backup-logs=true
#EOF
#
#        systemctl restart lightdm
#        echo "* lightdm --show-config"
#        lightdm --show-config
#
#        echo "* lightdm --test-mode --debug"
#        lightdm --test-mode --debug
#
#    else
#        echo "* /etc/lightdm/lightdm.conf.d/99_my.conf existe"
#    fi
#else
#    echo "* pas de répertoire /etc/lightdm/lightdm.conf.d !"
#fi

waitAptStopped
bootEn1024x768
doUpgrade
installPaquetsCommunDebianUbuntu
apt-get install "$APT_OPTS" -y --no-install-recommends synaptic

installPaquetsCommunDebianUbuntuX
apt-get install "$APT_OPTS" -y firefox firefox-locale-fr thunderbird thunderbird-locale-fr

apt-get install "$APT_OPTS" -y tree

apt-get install "$APT_OPTS" -y imagemagick

apt-get install "$APT_OPTS" -y mlocate

removeServicesGenant
bash install-tools-nodejs.sh

sshAccesRoot
forceModule9P
accountPcadmin
gestionShutdownACPI
installPip
installRobotFramework

ciPrintMsgMachine "* Configuration Pc-Linux-MATE"

if ! command -v snap
then
    apt-get install -y snap
fi
snap list

snap remove ubuntu-mate-welcome

mkdir -p /home/pcadmin/.config

ciPrintMsgMachine "* disableUbuntuMATEWelcome"
mkdir -p /home/pcadmin/.config/ubuntu-mate/welcome
echo '{"autostart": false, "hide_non_free": false}' >/home/pcadmin/.config/ubuntu-mate/welcome/preference.json
chown -R pcadmin:pcadmin /home/pcadmin/.config

snap remove software-boutique
apt-get remove -y kerneloops
systemctl stop nslcd 2>/dev/null
systemctl disable nslcd 2>/dev/null

systemctl stop avahi-daemon
systemctl disable avahi-daemon
    
ciPrintMsgMachine "Liste des applications active"
grep NoDisplay /etc/xdg/autostart/*.desktop

ciPrintMsgMachine "Désactive backup"
mkdir -p /home/pcadmin/.config/autostart/
cat >/home/pcadmin/.config/autostart/org.gnome.DejaDup.Monitor.desktop <<EOF
[Desktop Entry]
Name=Backup Monitor
Hidden=true
EOF

ciPrintMsgMachine "Désactive screensaver"
cat >/home/pcadmin/.config/autostart/mate-screensaver.desktop <<EOF
[Desktop Entry]
Name=Screensaver
Hidden=true
#X-MATE-Autostart-enabled=false
EOF

ciPrintMsgMachine "* gsettings get org.gnome.desktop.background"
gsettings get org.gnome.desktop.background
# gsettings set org.gnome.desktop.background picture-uri 'file:///home/pcadmin/background.xm

ciPrintMsgMachine "* updateDconfUserUbuntuMATE"

# see https://developer.gnome.org/glib/stable/gvariant-text.html ==> annotation

# attention : je suis root ici!
echo "user-db:user" >/home/pcadmin/db_profile
if [ ! -f /home/pcadmin/old_settings ]
then
    ciPrintMsgMachine "* export dconf initial dans /home/pcadmin/old_settings"
    DCONF_PROFILE=/home/pcadmin/db_profile dconf dump / >/home/pcadmin/old_settings
    ciAfficheContenuFichier /home/pcadmin/old_settings
fi
    
ciPrintMsgMachine "* Désactive logout restart"
#DCONF_PROFILE=/home/pcadmin/db_profile dconf load / <<EOF
#[apps/indicator-session]
#suppress-logout-restart-shutdown=true
#EOF

ciPrintMsgMachine "* Shutdown on apci poweroff"
#DCONF_PROFILE=/home/pcadmin/db_profile dconf load / <<EOF
#[org/mate/power-manager]
#button-power='shutdown'
#sleep-display-ac=0
#EOF

ciPrintMsgMachine "* timeout logoff"
#DCONF_PROFILE=/home/pcadmin/db_profile dconf load / <<EOF
#[org/mate/desktop/session]
#logout-timeout=10
#EOF

ciPrintMsgMachine "* screensaver blank"
#DCONF_PROFILE=/home/pcadmin/db_profile dconf load / <<EOF
#[org/mate/screensaver]
#idle-activation-enabled=false
#themes=@as []
#mode='blank-only'
#lock-enabled=false
#EOF
echo $?

#gsettings set org.gnome.login-screen disable-user-list false

/bin/rm -f /home/pcadmin/db_profile

#/org/mate/screensaver/mode
#  'single'
#
#/org/mate/screensaver/themes
#  ['screensavers-personal-slideshow']
#
#/org/mate/screensaver/mode
#  'blank-only'
#
#/org/mate/screensaver/themes
#  @as []
#
#/org/mate/power-manager/button-lid-ac
#  'suspend'
#
#/org/mate/power-manager/button-power
#  'interactive'
#/org/mate/power-manager/button-suspend
#  'suspend'
#
#/org/mate/power-manager/sleep-display-ac
#  0
#
#/org/mate/power-manager/button-power
#  'shutdown'

echo "Inject hostname pcubuntu"
hostnamectl set-hostname "pcubuntu"
[[ "$VM_DEBUG" -gt "1" ]] && hostnamectl --static status
        
# refait ...
removeServicesGenant
tagImage
