#!/bin/bash

ciPrintMsgMachine "ciCheckDebsums: Analyse Eole debsums"

if ciVersionMajeurAvant "2.6.0"
then
    ciSignalWarning "Test debsums disabled"
    exit 0
fi

# ignore shellcheck !!
echo '/usr/bin/shellcheck' >/etc/eole/debsums-ignore.d/shellcheck.conf
# ignore dpkg (#36199)
echo '/usr/sbin/start-stop-daemon' >/etc/eole/debsums-ignore.d/dpkg.conf

bash /etc/cron.daily/eole-debsums
RESULT="$?"
if [ "$RESULT" -eq 0 ]
then
     echo "/etc/cron.daily/eole-debsums : OK"
else
     echo "/etc/cron.daily/eole-debsums : NOK (code $RESULT)"
fi

# wait for /var/lib/lxc/reseau/rootfs/var/log/eole-debsums/report.log ;)
sleep 10

echo "* show-reports"
/usr/share/eole/debsums/show-reports.py 2>&1 | tee /tmp/eole-debsums.log

echo "* check reports..."
for reportlog in /var/log/eole-debsums/report.log /var/lib/lxc/*/rootfs/var/log/eole-debsums/report.log
do
    echo "Check $reportlog"
    if [ -s "$reportlog" ]
    then
        /bin/cp /tmp/eole-debsums.log "$VM_DIR/eole-debsums.log"
        ciPrintMsgMachine "ciCheckDebsums : ERREUR "
        ciSignalAlerte "analyse eole debsums ==> $VM_DIR/eole-debsums.log"
        exit 1
    fi
done
ciPrintMsgMachine "ciCheckDebsums : OK"

