#!/bin/bash

source /mnt/eole-ci-tests/scripts/getVMContext.sh

function displayState()
{
    if ldapsearch -x uid=$1 >/dev/null
    then
        echo "ldap $1 => OK"
    else
        echo "ldap $1 => MANQUANT"
    fi
    if ssh addc "ldbsearch -H /var/lib/samba/private/sam.ldb '(sn=$1)' sAMAccountName | grep dn:" >/dev/null
    then
        echo "addc $1 => OK"
    else
        echo "addc $1 => MANQUANT"
    fi
}

#tail -f \ 
#/var/log/lsc/lsc.log
#/var/log/mysql/error.log \
#/var/log/rsyslog/local/imapd/imapd.debug.log \
#/var/log/rsyslog/local/ntpd/ntpd.info.log \
#/var/log/rsyslog/local/clamd/clamd.info.log \
#/var/log/rsyslog/local/creoled/creoled.info.log \
#/var/log/rsyslog/local/dbus-daemon/dbus-daemon.info.log \
#/var/log/rsyslog/local/systemd/systemd.info.log \

if ! dpkg -L eole-scribe-tests
then
    apt-eole install -y eole-scribe-tests
fi

#tail -f /var/lib/lxc/addc/rootfs/var/log/auth.log /var/lib/lxc/addc/rootfs/var/log/syslog /var/lib/lxc/addc/rootfs/var/log/samba/log.samba  


#cat /etc/default/lsc
cp -u /mnt/eole-ci-tests/tests/creolelint/logback.xml /etc/lsc
echo $?

echo "stop eole-lsc.service"
systemctl stop eole-lsc.service

echo "start eole-lsc.service"
systemctl start eole-lsc.service

echo "status eole-lsc.service"
systemctl status  eole-lsc.service
echo $?


echo "* testparm"
echo "\n" | testparm -vp >/tmp/testparm
echo $?
if grep ERROR: /tmp/testparm
then
    echo "* ERROR dans testparm"
    cat /tmp/testparm
    exit 1
fi
if grep WARNING: /tmp/testparm
then
    echo "* WARNING dans testparm"
    cat /tmp/testparm
fi

displayState admin
displayState prof1

echo "* smbclient"
if ! smbclient -L //127.0.0.1 -Uadmin%Eole12345! -m SMB3 -c ls
then
    echo $?
    echo "* Erreur smbclient, stop"
fi

mkdir -p /tmp/testgg
echo "* test mount"
if ! mount -t cifs //127.0.0.1/commun /tmp/testgg -o vers=3.0,username=admin,password=Eole12345!
then
    echo $?
    echo "* Erreur mount, stop"
fi
echo "* umount"
umount /tmp/testgg

getent passwd

RETOUR_TEST=0

ciPrintMsgMachine "***********************************************************"
ciPrintMsgMachine "eole-scribe-tests"
ciPrintMsgMachine "***********************************************************"
cd /usr/share/scribe || exit 2
py.test -v --log-level=debug tests/test_scribe.py
#py.test -v --log-level=debug tests/test_scribe.py -k test_create_niveau
RETOUR=$?
echo "scribe => $RETOUR"
[[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR
#displayState televe
#
#py.test -v --log-level=debug tests/test_scribe.py -k test_create_classe
#RETOUR=$?
#echo "scribe => $RETOUR"
#[[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR
#displayState televe
#
#py.test -v --log-level=debug tests/test_scribe.py -k test_create_groupe
#RETOUR=$?
#echo "scribe => $RETOUR"
#[[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR
#displayState televe
#
#py.test -v --log-level=debug tests/test_scribe.py -k test_create_eleve
#RETOUR=$?
#echo "scribe => $RETOUR"
#displayState televe
#
#[[ "$RETOUR" == "0" ]] || RETOUR_TEST=$RETOUR
# 
#journalctl -u eole-lsc.service --no-pager
systemctl status eole-lsc.service
echo $?

ciPrintMsgMachine "***********************************************************"
ciPrintMsgMachine "Fin run-creoletest.sh ==> $RETOUR_TEST"
ciPrintMsgMachine "***********************************************************"
exit $RETOUR_TEST 
