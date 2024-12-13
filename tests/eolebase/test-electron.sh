#!/bin/bash

cd /home/pcadmin/Bureau/ || exit 1

git clone https://github.com/electron/electron-quick-start
cd electron-quick-start
npm install
ELECTRON_ENABLE_LOGGING=true DEBUG=nightmare*,electron* npm start

#ELECTRON_ENABLE_LOGGING=true DEBUG=nightmare*,electron* DISPLAY=:1 npm test
RESULT="$?"
echo "* Fin ==> $RESULT"
exit "$RESULT"
