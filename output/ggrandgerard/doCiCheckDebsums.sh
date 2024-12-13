#!/bin/bash
export VM_HOME_EOLE_CI_TEST=/mnt/eole-ci-tests
export VM_TIMEOUT=1000
export LANG=fr_FR.UTF-8
export HOME=/root
export TERM=linux
[ -f /etc/profile.d/eolerc.sh ] && . /etc/profile.d/eolerc.sh
export VM_HOME_TEST=/mnt/eole-ci-tests/tests/creolelint
export PATH=$PATH:/mnt/eole-ci-tests/tests/creolelint
export PYTHONPATH=$PYTHONPATH:/mnt/eole-ci-tests/tests/creolelint
export PYTHONPATH=$PYTHONPATH:/mnt/eole-ci-tests/scripts
export PATH=$PATH:/mnt/eole-ci-tests/scripts
[[ /mnt/eole-ci-tests/scripts/EoleCiFunctions.sh -nt /root/EoleCiFunctions.sh ]] && /bin/cp /mnt/eole-ci-tests/scripts/EoleCiFunctions.sh /root/EoleCiFunctions.sh
source /dev/stdin </root/EoleCiFunctions.sh
ciGetContext

cd /mnt/eole-ci-tests/tests/creolelint
(
set -x;ciCheckDebsums
) 2>&1
exit $?
