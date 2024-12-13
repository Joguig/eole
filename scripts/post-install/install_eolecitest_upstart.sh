#!/bin/bash -x
#
echo "Install EoleCiTests Upstart Services"

echo "Nettoyage"
rm -f /etc/init/EoleCiTestsContext.conf
rm -f /etc/init/EoleCiTestsDaemon.conf

cp /mnt/eole-ci-tests/scripts/post-install/EoleCiTestsContext.conf /etc/init/EoleCiTestsContext.conf
cp /mnt/eole-ci-tests/scripts/post-install/EoleCiTestsDaemon.conf /etc/init/EoleCiTestsDaemon.conf
chmod 644 /etc/init/EoleCiTestsContext.conf
chmod 644 /etc/init/EoleCiTestsDaemon.conf
initctl reload-configuration
initctl check-config

rm -f /var/log/upstart/EoleCiTestsContext.log
initctl start EoleCiTestsContext
cat /var/log/upstart/EoleCiTestsContext.log 

rm -f /etc/init.d/eole-ci-tests
rm -f /root/eole-ci-tests-daemon-runner.sh
rm -f /root/eole-ci-tests_start.sh
