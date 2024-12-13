#!/bin/bash
# shellcheck disable=SC2034,SC2148,SC2009

# shellcheck disable=SC1091
source /dev/stdin </mnt/eole-ci-tests/scripts/imagesNonEole/functions.sh

ciPrintMsgMachine "* pc-linuxmint.sh"
if [ ! -f "/etc/lsb-release" ]
then
    ciPrintMsg "pc-linuxmint doit etre ubuntu "
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
export APT_OPTS="-y"

if [[ -d /etc/lightdm/lightdm.conf.d/ ]]
then
    find /etc/lightdm/lightdm.conf.d/ | while read -r F 
    do
        ciAfficheContenuFichier "$F" |grep -v "^#" |grep -v "^[[:space:]]*$"
    done

    if [[ -f /etc/lightdm/lightdm.conf.d/01_my.conf ]]
    then
       rm  /etc/lightdm/lightdm.conf.d/01_my.conf
    fi

    if [[ ! -f /etc/lightdm/lightdm.conf.d/99_my.conf ]]
    then
       cat > /etc/lightdm/lightdm.conf.d/99_my.conf << EOF
[Seat:*]
greeter-hide-users=false
greeter-show-manual-login=true
greeter-show-remote-login=true
allow-guest=false
type=local

[LightDM]
backup-logs=true
EOF

       systemctl restart lightdm
       echo "* lightdm --show-config"
       lightdm --show-config

       echo "* lightdm --test-mode --debug"
       lightdm --test-mode --debug

    else
       echo "* pas de fichier /etc/lightdm/lightdm.conf.d/01_my.conf"
       ls -l /etv/lightdm/lightdm.conf.d/ 2>/dev/null
    fi
else
    echo "* pas de répertoire /etc/lightdm/lightdm.conf.d !"
fi

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

ciPrintMsgMachine "* Configuration Pc-Linux-MINT"

apt-get remove -y kerneloops
systemctl stop nslcd 2>/dev/null
systemctl disable nslcd 2>/dev/null

systemctl stop avahi-daemon
systemctl disable avahi-daemon

mkdir -p /home/pcadmin/.config

ciPrintMsgMachine "* disable LinuxMint Welcome"
mkdir -p /home/pcadmin/.linuxmint/mintwelcome
touch /home/pcadmin/.linuxmint/mintwelcome/norun.flag 

mkdir -p /home/pcadmin/.config/nemo
cat >/home/pcadmin/.config/nemo/desktop-metadata <<EOF
[desktop-monitor-0]
nemo-icon-view-keep-aligned=true
nemo-icon-view-auto-layout=true
nemo-icon-view-layout-timestamp=1607618532
desktop-grid-adjust=50;75;

[computer]
nemo-icon-position-timestamp=1607618612
nemo-icon-position=32,26
monitor=0
icon-scale=1

[home]
nemo-icon-position-timestamp=1607618612
nemo-icon-position=34,101
monitor=0
icon-scale=1
EOF

mkdir -p /home/pcadmin/.cinnamon/configs/calendar@cinnamon.org
cat >/home/pcadmin/.cinnamon/configs/calendar@cinnamon.org/12.json <<EOF
{
    "section1": {
        "type": "section",
        "description": "Display"
    },
    "show-week-numbers": {
        "type": "switch",
        "default": false,
        "description": "Show week numbers in calendar",
        "tooltip": "Check this to show week numbers in the calendar.",
        "value": true
    },
    "use-custom-format": {
        "type": "switch",
        "default": false,
        "description": "Use a custom date format",
        "tooltip": "Check this to define a custom format for the date in the calendar applet.",
        "value": true
    },
    "custom-format": {
        "type": "entry",
        "default": "%A, %B %e, %H:%M",
        "description": "Date format",
        "indent": true,
        "dependency": "use-custom-format",
        "tooltip": "Set your custom format here.",
        "value": "%A, %B %e, %H:%M"
    },
    "format-button": {
        "type": "button",
        "description": "Show information on date format syntax",
        "indent": true,
        "dependency": "use-custom-format",
        "callback": "on_custom_format_button_pressed",
        "tooltip": "Click this button to know more about the syntax for date formats."
    },
    "section2": {
        "type": "section",
        "description": "Keyboard shortcuts"
    },
    "keyOpen": {
        "type": "keybinding",
        "description": "Show calendar",
        "default": "<Super>c",
        "tooltip": "Set keybinding(s) to show the calendar.",
        "value": "<Super>c"
    },
    "__md5__": "630b424730fcba4718d867a7442c6b3b"
}
EOF

chown -R pcadmin:pcadmin /home/pcadmin/.config
    
ciPrintMsgMachine "Liste des applications GNOME AutoRestart"
grep X-GNOME-AutoRestart /etc/xdg/autostart/*.desktop

ciPrintMsgMachine "Liste des applications Cinnamon"
grep OnlyShowIn=X-Cinnamon /etc/xdg/autostart/*.desktop

ciPrintMsgMachine "Désactive backup"
mkdir -p /home/pcadmin/.config/autostart/

# gsettings set org.gnome.desktop.background picture-uri 'file:///home/pcadmin/background.xm

ciPrintMsgMachine "* updateDconfUserUbuntuMATE"

# see https://developer.gnome.org/glib/stable/gvariant-text.html ==> annotation

# attention : je suis root ici!
echo "user-db:user" >/home/pcadmin/db_profile
if [ ! -f /home/pcadmin/old_settings ]
then
    ciPrintMsgMachine "* export dconf initial dans /home/pcadmin/old_settings"
    DCONF_PROFILE=/home/pcadmin/db_profile dconf dump / >/home/pcadmin/old_settings
fi
    
    
ciPrintMsg "* Désactive logout restart"
cat >/tmp/suppress-logout-restart-shutdown <<EOF
[apps/indicator-session]
suppress-logout-restart-shutdown=true
EOF
su pcadmin -c 'DCONF_PROFILE=/run/user/1000/dconf dconf load / </tmp/suppress-logout-restart-shutdown'

ciPrintMsg "linuxmint button power -> shutdown"
cat >/tmp/mint-logout <<EOF
[org/cinnamon/settings-daemon/plugins/power]
button-power='shutdown'
EOF
su pcadmin -c 'DCONF_PROFILE=/run/user/1000/dconf dconf load / </tmp/mint-logout'
    
cat >/etc/acpi/events/power <<EOF
event=button/power
action=/etc/acpi/powerbtn.sh "%e" 
EOF

cp /usr/share/doc/acpid/examples/powerbtn.sh /etc/acpi/powerbtn.sh
chmod a+x /etc/acpi/powerbtn.sh

su pcadmin -c 'DCONF_PROFILE=/run/user/1000/dconf dconf update'


/bin/rm -f /home/pcadmin/db_profile

echo "Inject hostname pclinuxmint"
hostnamectl set-hostname "pclinuxmint"
[[ "$VM_DEBUG" -gt "1" ]] && hostnamectl --static status

# refait ...
removeServicesGenant
tagImage
