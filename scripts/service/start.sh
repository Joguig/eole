#!/bin/bash

echo "Start.sh début... " >/var/log/eole-ci-tests.log
date >>/var/log/eole-ci-tests.log

if command -v systemctl >/dev/null 2>/dev/null
then
	# UPDATE SERVICES ET stop !
	/bin/bash /mnt/eole-ci-tests/scripts/post-install/install_eolecitest_systemd.sh >>/var/log/eole-ci-tests.log
	exit 0
else
	/bin/bash /mnt/eole-ci-tests/scripts/service/CheckUpdate.sh >>/var/log/eole-ci-tests.log
	/bin/bash /root/eole-ci-tests-daemon-runner.sh INIT >>/var/log/eole-ci-tests.log 2>&1 0</dev/null &
	echo "$!" >>/var/run/eole-ci-tests.pid
	exit 0
fi
