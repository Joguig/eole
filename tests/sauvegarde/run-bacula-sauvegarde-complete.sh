#!/bin/bash

BACULA_RESULT="0"

CreoleGet activer_bacula_dir
CreoleGet activer_bacula_sd

echo >/home/a/toto1.txt

echo >/var/log/rsyslog/local/bacula-dir/bacula-dir.err.log
chown syslog:adm /var/log/rsyslog/local/bacula-dir/bacula-dir.err.log

/usr/share/eole/sbin/baculaconfig.py -s manual
SUPPORT=$(/usr/share/eole/sbin/baculaconfig.py -d | grep ^Support)
if [ "$SUPPORT" != "Support : {u'support_type': u'manual'}" ] 
then
    echo "Support mal configuré, exit=1"
    exit 1
fi 
/usr/share/eole/sbin/baculaconfig.py -n --level=Full

echo "Pause de 10 secondes"
sleep 10

echo "tail -f /var/log/rsyslog/local/bacula-dir/bacula-dir.err.log dans un processus independant"
tail -f /var/log/rsyslog/local/bacula-dir/bacula-dir.err.log &
PID_TAIL=$!

echo "Pause de 100 secondes"
sleep 100


echo "Test"
NB=$(grep -c "Backup OK" /var/log/rsyslog/local/bacula-dir/bacula-dir.err.log)
echo "nb = $NB"
if [ "$NB" -ne 3 ] 
then 
    echo "ERREUR pas le bon nombre de ligne 'Backup'"
    BACULA_RESULT="1"
else
    ciPutBackup
    BACULA_RESULT=$?
fi

[ -n "$PID_TAIL" ] && kill -9 $PID_TAIL

exit $BACULA_RESULT