#!/bin/bash
export VM_HOME_EOLE_CI_TEST=/mnt/eole-ci-tests
export VM_TIMEOUT=1920
export LANG=fr_FR.UTF-8
export HOME=/root
export TERM=linux
[ -f /etc/profile.d/eolerc.sh ] && . /etc/profile.d/eolerc.sh
export VM_HOME_TEST=/mnt/eole-ci-tests/tests/instances
export PATH=$PATH:/mnt/eole-ci-tests/tests/instances
export PYTHONPATH=$PYTHONPATH:/mnt/eole-ci-tests/tests/instances
export PATH=$PATH:/mnt/eole-ci-tests/scripts
export PYTHONPATH=$PYTHONPATH:/mnt/eole-ci-tests/scripts
source /root/getVMContext.sh NO_DISPLAY NO_UPDATE
cd /mnt/eole-ci-tests/tests/instances
(
ciInstanceDefault 
) 2>&1
exit $?

