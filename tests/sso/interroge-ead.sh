#!/bin/bash

if [ -f "/root/.ssh/known_hosts" ]; then
    ssh-keygen -f "/root/.ssh/known_hosts" -R "eolebase.ac-test.fr"
    ssh-keygen -f "/root/.ssh/known_hosts" -R "scribe.ac-test.fr"
fi

VM_VERSIONMAJEUR=A ciInjectCaMachineSsh eolebase.ac-test.fr
VM_VERSIONMAJEUR=A ciInjectCaMachineSsh scribe.ac-test.fr


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

#echo "* python3 /mnt/eole-ci-tests/tests/ead/open_session_ead.py" 
#python3 /mnt/eole-ci-tests/tests/ead/open_session_ead.py
#echo "* ------------------------------------------"

echo "* python3 /mnt/eole-ci-tests/tests/ead/open_session_ead1.py" 
ciRunPython /mnt/eole-ci-tests/tests/ead/open_session_ead1.py "https://scribe.ac-test.fr:4200" "scribe" "$1"
echo "* ------------------------------------------"

echo "* curl -v -k https://scribe.ac-test.fr:4200/" 
curl -v -k https://scribe.ac-test.fr:4200/
echo "* ------------------------------------------"
