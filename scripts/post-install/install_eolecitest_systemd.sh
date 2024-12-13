#!/bin/bash -x
#
echo "Install EoleCiTests SystemD Services"

echo "Nettoyage"
if [ -f /etc/systemd/system/EoleCiTestsContext.service ]
then
	systemctl stop EoleCiTestsContext.service
    rm -f /etc/systemd/system/EoleCiTestsContext.service	
fi
if [ -f /etc/systemd/system/EoleCiTestsDaemon.service ]
then
    systemctl stop EoleCiTestsDaemon.service
    rm -f /etc/systemd/system/EoleCiTestsDaemon.service
fi

cp /mnt/eole-ci-tests/scripts/post-install/EoleCiTestsContext.service /etc/systemd/system/EoleCiTestsContext.service
cp /mnt/eole-ci-tests/scripts/post-install/EoleCiTestsDaemon.service /etc/systemd/system/EoleCiTestsDaemon.service
chmod 644 /etc/systemd/system/EoleCiTestsContext.service
chmod 644 /etc/systemd/system/EoleCiTestsDaemon.service
systemctl daemon-reload

echo "inject service systemd : EoleCiTestsContext"
systemctl enable EoleCiTestsContext.service
systemctl enable EoleCiTestsDaemon.service

systemctl start EoleCiTestsContext.service
echo $?
sleep 1
systemctl is-active EoleCiTestsContext.service

systemctl start EoleCiTestsDaemon.service
echo $?
sleep 1
systemctl is-active EoleCiTestsDaemon.service

journalctl --no-pager -xe -u EoleCiTestsContext.service
journalctl --no-pager -xe -u EoleCiTestsDaemon.service

if [ -f /etc/init.d/eole-ci-tests ] 
then
	echo "Deinstall Service 'eole-ci-tests' depuis /mnt/eole-ci-tests "
	systemctl disable eole-ci-tests
	systemctl mask eole-ci-tests
	rm -f /etc/init.d/eole-ci-tests
fi
exit 0
