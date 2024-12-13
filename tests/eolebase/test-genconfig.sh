#!/bin/bash

cd /home/pcadmin/Bureau/eole-genconfig-tests || exit 1
chmod -R 777 /home/pcadmin/Bureau/eole-genconfig-tests
chown -R pcadmin /home/pcadmin/Bureau/eole-genconfig-tests
ls -l

echo "* Run test"
xvfb-run --server-args="-screen 0 1024x768x24" mocha --timeout 60000 --recursive --exit
RESULT="$?"
if [ "$RESULT" -ne "0" ]
then
    echo "* re test avec log car Exit=$RESULT"
    ELECTRON_ENABLE_LOGGING=true DEBUG="nightmare*,electron*" xvfb-run --server-args="-screen 0 1024x768x24" mocha --timeout 60000 --recursive --exit
fi

echo "* Fin ==> $RESULT"
exit "$RESULT"
