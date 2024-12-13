#!/bin/bash

cd /home/pcadmin/Bureau/ewt-tests || exit 1
chmod -R 777 /home/pcadmin/Bureau/ewt-tests
chown -R pcadmin /home/pcadmin/Bureau/ewt-tests
ls -l

echo "* Run test"
ELECTRON_ENABLE_LOGGING=true DEBUG="nightmare*,electron*" DISPLAY=:1 npm run --silent test:common -- -R tap
RESULT="$?"

echo "* Fin ==> $RESULT"
exit "$RESULT"
