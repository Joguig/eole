#!/bin/bash
# shellcheck disable=SC2034,SC2148,SC2009

# shellcheck disable=SC1091
source /dev/stdin </mnt/eole-ci-tests/scripts/imagesNonEole/functions.sh

#ciPrintMsgMachine "* pcdebian"
#if [ ! -f "/etc/lsb-release" ]
#then
#    ciPrintMsg "pc-debian doit etre ubuntu "
#    exit 1
#fi

export DEBIAN_FRONTEND=noninteractive
export APT_OPTS=""



waitAptStopped
bootEn1024x768
doUpgrade
installPaquetsCommunDebianUbuntu

apt-get install "$APT_OPTS" -y xorg

apt-get install "$APT_OPTS" -y tasksel

tasksel install "$APT_OPTS" -y desktop-environment

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

ciPrintMsgMachine "* Configuration Pc-Debian"

mkdir -p /home/pcadmin/.config
chown -R pcadmin:pcadmin /home/pcadmin/.config

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
gsettings get org.gnome.desktop.background picture-uri
# gsettings set org.gnome.desktop.background picture-uri 'file:///home/pcadmin/background.xm


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

echo "Inject hostname pcdebian"
hostnamectl set-hostname "pcdebian"
[[ "$VM_DEBUG" -gt "1" ]] && hostnamectl --static status
        
cat > /etc/gdm3/greeter.dconf-defaults << EOF

# Theming options
# ===============

#  - Change the GTK+ theme
[org/gnome/desktop/interface]
# gtk-theme='Adwaita'
#  - Use another background

[org/gnome/desktop/background]
# picture-uri='file:///usr/share/themes/Adwaita/backgrounds/stripes.jpg'
# picture-options='zoom'
#  - Or no background at all
[org/gnome/desktop/background]
# picture-options='none'
# primary-color='#000000'

# Login manager options
# =====================
[org/gnome/login-screen]
logo='/usr/share/images/vendor-logos/logo-text-version-64.png'

# - Disable user list
# disable-user-list=true
# - Disable restart buttons
# disable-restart-buttons=true
# - Show a login welcome message
banner-message-enable=true
banner-message-text='Bienvenu EOLE'

# Automatic suspend
# =================
[org/gnome/settings-daemon/plugins/power]
# - Time inactive in seconds before suspending with AC power
#   1200=20 minutes, 0=never
# sleep-inactive-ac-timeout=1200
# - What to do after sleep-inactive-ac-timeout
#   'blank', 'suspend', 'shutdown', 'hibernate', 'interactive' or 'nothing'
# sleep-inactive-ac-type='suspend'
# - As above but when on battery
# sleep-inactive-battery-timeout=1200
# sleep-inactive-battery-type='suspend'
EOF

dconf update

        
# refait ...
removeServicesGenant
tagImage
