#!/bin/bash

echo "* apt-eole install eole-bareos"
ciInstallBareos
ciCheckExitCode $?

echo "* CreoleSet activer_samba_backup oui"
CreoleSet activer_samba_backup oui
ciCheckExitCode $?

echo "* reconfigure"
ciMonitor reconfigure
ciCheckExitCode $?

echo "* /usr/share/eole/schedule/scripts/samba_backup cron"
/usr/share/eole/schedule/scripts/samba_backup cron
ciCheckExitCode "$?" "samba_backup"

exit 0
