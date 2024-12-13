#!/bin/bash

# shellcheck disable=SC1091,SC1090
. /root/getVMContext.sh NO_DISPLAY

ciClearJournalLogs 1>/dev/null 2>&1

ciSetHttpAndHttpsProxy
export no_proxy=salt

echo "* ping salt"
ciGetNamesInterfaces
ciPingHost salt "$VM_INTERFACE0_NAME"

echo "* getent hosts salt"
getent hosts salt

ciRenamePcLinux

echo "* check depot à travers proxy/e2guardian/clamd http://test-eole.ac-dijon.fr/outils"
ciTestHttp http://test-eole.ac-dijon.fr/outils

ciAfficheContenuFichier /etc/os-release
ciAfficheContenuFichier /etc/lsb-release

lsb_release -a
DISTRIB="$(lsb_release -sc)"
echo "DISTRIB=$DISTRIB"
case "$DISTRIB" in 
    focal|vanessa)
        if dpkg -l | grep -q ubuntu-mate-desktop
        then
            echo "pas de hack pour MATE"
        else
            ciSignalHack "* veyon.service.d/override.conf XDG_SESSION_TYPE=x11  (focal)"
            mkdir -p /etc/systemd/system/veyon.service.d
            cat >/etc/systemd/system/veyon.service.d/override.conf <<EOF
[Service]
Environment="XDG_SESSION_TYPE=x11"
Environment="QT_DEBUG_PLUGINS=1"
EOF
        fi
        ;;

    *)
        ;;
esac

echo "* wget http://salt/joineole/installMinion.sh"
wget -O /tmp/installMinion.sh http://salt/joineole/installMinion.sh

echo "* sh /tmp/installMinion.sh"
sh /tmp/installMinion.sh

echo "* active log_level"
mkdir -p /etc/salt/minion.d
/bin/echo "log_level: debug" > /etc/salt/minion.d/log_level.conf

echo "* systemctl restart salt-minion"
systemctl restart salt-minion

