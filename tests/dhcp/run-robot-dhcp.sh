#!/bin/bash
echo "$0 : Début"

echo "* clone-wall-e.sh"
cd /root || exit 1
if [ ! -d wall-e ]
then
    git clone https://dev-eole.ac-dijon.fr/git/wall-e.git
    cd /root/wall-e || exit 1
else
    cd /root/wall-e || exit 1
    git pull
fi

export ROBOT_SYSLOG_FILE=/tmp/syslog.txt
export ROBOT_SYSLOG_LEVEL=TRACE

robot --variable xvfb:True --outputdir /var/www/html/dhcp ead3/actions/dhcp
exit $?
