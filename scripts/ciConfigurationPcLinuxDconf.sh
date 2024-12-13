function ciConfigurationPcLinuxDconf()
{
    if command -v snap
    then
        snap list
        snap remove ubuntu-mate-welcome
        snap remove software-boutique
    fi
    apt-get remove -y kerneloops
    systemctl stop nslcd
    
    # a voir !
    systemctl stop avahi-daemon
    systemctl disable avahi-daemon

    echo "user-db:user" >/home/pcadmin/db_profile
    if [ ! -f /home/pcadmin/old_settings ]
    then
        ciPrintMsg "ciConfigurationPcLinux : export dconf original"
        su pcadmin -c 'dconf dump / >/home/pcadmin/old_settings'
    else
        ciPrintMsg "ciConfigurationPcLinux : export dconf original existe déjà"
    fi

    ciPrintMsg "ciConfigurationPcLinux : application dconf"
    cat >/tmp/suppress-logout-restart-shutdown <<EOF
[apps/indicator-session]
suppress-logout-restart-shutdown=true
EOF
    su pcadmin -c 'DCONF_PROFILE=/run/user/1000/dconf dconf load / </tmp/suppress-logout-restart-shutdown'

    ciPrintMsg "ciConfigurationPcLinux : shutdown on poweroff event !"
    cat >/tmp/power-manager <<EOF
[org/mate/power-manager]
button-power='shutdown'
sleep-display-ac=0
EOF
    su pcadmin -c 'DCONF_PROFILE=/run/user/1000/dconf dconf load / </tmp/power-manager'

    ciPrintMsg "ciConfigurationPcLinux : session logout timeout 10s"
    cat >/tmp/mate-logout <<EOF
[org/mate/desktop/session]
logout-timeout=10
EOF
    su pcadmin -c 'DCONF_PROFILE=/run/user/1000/dconf dconf load / </tmp/mate-logout'

    ciPrintMsg "ciConfigurationPcLinux : linuxmint button power -> shutdown"
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
    
    # dans les tests, il ne faut pas poser de question, et aller vite
    #ciRunInUserSession gsettings set org.mate.power-manager button-power shutdown
    #ciRunInUserSession gsettings set org.mate.session logout-timeout 10
}
export -f ciConfigurationPcLinuxDconf

ciConfigurationPcLinuxDconf