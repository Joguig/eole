#!/bin/bash
export VM_HOME_EOLE_CI_TEST=/mnt/eole-ci-tests
export VM_TIMEOUT=3600
export LANG=fr_FR.UTF-8
export HOME=/root
export TERM=xterm
[ -f /etc/profile.d/eolerc.sh ] && . /etc/profile.d/eolerc.sh
export VM_HOME_TEST=/mnt/eole-ci-tests/tests/importation
export PATH=$PATH:/mnt/eole-ci-tests/tests/importation
export PYTHONPATH=$PYTHONPATH:/mnt/eole-ci-tests/tests/importation
export PATH=$PATH:/mnt/eole-ci-tests/scripts
export PYTHONPATH=$PYTHONPATH:/mnt/eole-ci-tests/scripts
source /root/getVMContext.sh NO_DISPLAY NO_UPDATE
cd /mnt/eole-ci-tests/tests/importation
(
ciMonitor reconfigure 
) 2>&1
exit $?

