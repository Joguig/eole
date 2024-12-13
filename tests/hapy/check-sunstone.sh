#!/bin/bash

[ -f geckodriver.log ] && /bin/rm -f geckodriver.log

PATH=/snap/bin:/usr/share/eole:/usr/share/eole/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/mnt/eole-ci-tests/scripts
export PATH
echo "PATH=$PATH"

export TMPDIR=$HOME/tmp
mkdir -p "$TMPDIR"
mkdir -p /run/user/0

echo "TMPDIR=$TMPDIR"

echo "* ciEnv" 
ciEnv

echo "* snap info firefox" 
snap info firefox

echo "* /snap/bin/firefox.geckodriver -V"
/snap/bin/firefox.geckodriver -V

echo "* python3 /mnt/eole-ci-tests/tests/hapy/open_session_sunstone.py" 
ciRunPython /mnt/eole-ci-tests/tests/hapy/open_session_sunstone.py
echo "* ------------------------------------------"
