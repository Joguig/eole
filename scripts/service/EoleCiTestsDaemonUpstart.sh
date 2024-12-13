#!/bin/bash

(
# shellcheck disable=SC1091
source /root/getVMContext.sh NO_DISPLAY
ciDaemonMain
) &