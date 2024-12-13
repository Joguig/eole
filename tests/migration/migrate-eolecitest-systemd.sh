#!/bin/bash -x
#
echo "Migration EoleCiTests SystemD Services"

echo "Nettoyage"
if [ -f /etc/init.d/eole-ci-tests ] 
then
    echo "Deinstall Service 'eole-ci-tests' depuis /mnt/eole-ci-tests "
    systemctl disable eole-ci-tests
    systemctl mask eole-ci-tests
fi
rm -f /etc/init.d/eole-ci-tests
rm -f /etc/systemd/system/EoleCiTestsContext.service    
rm -f /etc/systemd/system/EoleCiTestsDaemon.service
rm -f /etc/init/EoleCiTestsContext.conf
rm -f /etc/init/EoleCiTestsDaemon.conf
rm -f /root/eole-ci-tests-daemon-runner.sh
rm -f /root/eole-ci-tests_start.sh

cp /mnt/eole-ci-tests/scripts/post-install/EoleCiTestsContext.service /etc/systemd/system/EoleCiTestsContext.service
cp /mnt/eole-ci-tests/scripts/post-install/EoleCiTestsDaemon.service /etc/systemd/system/EoleCiTestsDaemon.service
chmod 644 /etc/systemd/system/EoleCiTestsContext.service
chmod 644 /etc/systemd/system/EoleCiTestsDaemon.service
systemctl daemon-reload

echo "inject service systemd : EoleCiTestsContext"
systemctl enable EoleCiTestsContext.service
systemctl enable EoleCiTestsDaemon.service

echo "EoleCiTests : OK en attente reboot !"
exit 0
