#!/bin/bash

(
# shellcheck disable=SC1091
source /root/getVMContext.sh NO_DISPLAY
ciDaemonMain
) >/var/log/EoleCiTestsDaemon.log 2>&1 0</dev/null &
exit 0
