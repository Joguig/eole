#!/bin/bash

BACULA_RESULT="0"

ciGetBackup
ciCheckExitCode $?

/usr/share/eole/sbin/baculaconfig.py -s manual
/usr/share/eole/sbin/baculaconfig.py -d | grep ^Support

DIR_NAME=$(basename /mnt/sauvegardes/*catalog* | awk -F '-catalog' '{print $1}')

echo "******* EXTRACTION CONFIG EOL ***********"
if [ -f /var/log/rsyslog/local/bacula-dir/bacula-dir.err.log ]
then
    echo >/var/log/rsyslog/local/bacula-dir/bacula-dir.err.log
    chown syslog:adm /var/log/rsyslog/local/bacula-dir/bacula-dir.err.log
fi

/usr/share/eole/sbin/bacularestore.py --catalog "$DIR_NAME"
sleep 10
echo "******* zephir-restore.eol ***********"
cat /root/zephir-restore.eol
echo "******* zephir-restore.eol ***********"

mv /root/zephir-restore.eol /etc/eole/config.eol
ls -l /var/lib/bacula/

echo "******* Check Proxy ***********"
ciSetHttpProxy

echo "******* INSTANCE ***********"
ciInstance
ciCheckExitCode $?

echo "******* RESTAURATION COMPLETE ***********"
/usr/share/eole/sbin/bacularestore.py --all

echo "Pause de 30 secondes avant tail !"
sleep 30

tail -f /var/log/bacula/restore.txt &
PID_TAIL=$!

echo "Pause de 100 secondes, attente fin sauvegarde"
sleep 100

echo "******* COMPTE RENDU ***********"
if [ ! -f /var/log/bacula/restore.txt ]
then
    echo "Warning: LE FICHIER '/var/log/bacula/restore.txt' MANQUE"
    #BACULA_RESULT="1"
fi

ls -l /var/log/rsyslog/local/bacula-dir/
if [ ! -f /var/log/rsyslog/local/bacula-dir/bacula-dir.err.log ]
then
    echo "Warning: LE FICHIER '/var/log/rsyslog/local/bacula-dir/bacula-dir.err.log' MANQUE"
    #BACULA_RESULT="1"
else
    echo "Vérification présence 'Restore OK' ?"
    NB=$(grep -c "Restore OK" /var/log/rsyslog/local/bacula-dir/bacula-dir.err.log)
    echo "Nb = $NB"
    if [ "$NB" -ge 4 ]
    then 
        echo "Ok" 
    else
        echo "Nok"
        BACULA_RESULT="1"
    fi
fi

echo "test fichier /home/a/toto1.txt"
ls -l /home/a/toto1.txt

echo "test ldapsearch admin ?"
ldapsearch -x uid=admin loginShell | grep ^loginShell

echo "test quota ?"
python -c "from fichier.quota import get_quota;print get_quota('admin')"

echo "test la table testtable dans la base testsquash ?"
ls "$(CreoleGet container_path_mysql)/var/lib/mysql/testsquash"
$(CreoleRun "echo 'show tables;' | mysql --defaults-file=/etc/mysql/debian.cnf testsquash" mysql) | grep -q testtable
if [ $? -ne 0 ]; then
    echo "nok"
    BACULA_RESULT="1"
else
    echo "Ok"
fi

echo "Vérification présence 'Access denied' ?"
if grep "Access denied" /var/log/rsyslog/local/bacula-dir/bacula-dir.err.log 
then
    echo "nok"
    BACULA_RESULT="1"
else
    echo "Ok"
fi

echo "Nettoyage process ?"
[ -n "$PID_TAIL" ] && kill -9 "$PID_TAIL"

echo "Exit : $BACULA_RESULT"
exit $BACULA_RESULT
