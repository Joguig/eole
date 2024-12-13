#!/usr/local/bin/bash

(

/usr/local/bin/bash /root/mount.eole-ci-tests
/usr/local/bin/bash /mnt/eole-ci-tests/scripts/service/CheckUpdate.sh

# shellcheck disable=SC1091
source /root/EoleCiFunctions.sh
ciGetContext
ciDisplayContext
ciDaemonMain
) >/var/log/EoleCiTestsDaemon.log 2>&1 0</dev/null &
exit 0
