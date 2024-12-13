#!/bin/bash

# /root/EoleCiFunctions.sh est actualisé avant le lancement de ce script !

if command -v systemctl >/dev/null 2>/dev/null
then
	if [ "$1" != "SYSTEMD" ]
	then
		# UPDATE SERVICES ET stop !
		bash /mnt/eole-ci-tests/scripts/post-install/install_eolecitest_systemd.sh
		exit 0
	fi
fi

# shellcheck disable=SC1091
source /root/getVMContext.sh
ciContextualizeMe
ciDaemonMain
exit 0


