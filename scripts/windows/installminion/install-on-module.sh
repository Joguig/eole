#!/bin/bash -x

echo " copie"
cd /usr/share/eole/flask/genconfig/static || exit 1
[ ! -f Salt-Minion-2018.3.1-Py3-x86-Setup.exe       ] && wget https://repo.saltstack.com/windows/Salt-Minion-2018.3.1-Py3-x86-Setup.exe
[ ! -f Salt-Minion-2018.3.1-Py3-x86-Setup.exe.md5   ] && wget https://repo.saltstack.com/windows/Salt-Minion-2018.3.1-Py3-x86-Setup.exe.md5
[ ! -f Salt-Minion-2018.3.1-Py3-AMD64-Setup.exe     ] && wget https://repo.saltstack.com/windows/Salt-Minion-2018.3.1-Py3-AMD64-Setup.exe
[ ! -f Salt-Minion-2018.3.1-Py3-AMD64-Setup.exe.md5 ] && wget https://repo.saltstack.com/windows/Salt-Minion-2018.3.1-Py3-AMD64-Setup.exe.md5
cp -uf /mnt/eole-ci-tests/scripts/windows/installminion/* .
ls -l 
