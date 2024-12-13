#!/bin/bash

ciExportCurrentStatus

DATE_JOURNAL="$(cat /root/DATE_JOURNAL)"

echo "***********************************************************"
echo "* proxy: journalctl --no-pager -u squid.service"
# shellcheck disable=SC2029
journalctl --no-pager --since "$DATE_JOURNAL" -u squid.service >"/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/squid.log"
echo "EOLE_CI_PATH squid.log"

echo "* proxy: /var/log/rsyslog/local/squid/squidn.notice.log"
# shellcheck disable=SC2029
cat /var/log/rsyslog/local/squid/squidn.notice.log >"/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/squidn.log"
echo "EOLE_CI_PATH squidn.log"

echo "***********************************************************"
echo "* proxy: journalctl --no-pager -u eole-guardian@0.service"
# shellcheck disable=SC2029
journalctl --no-pager --since "$DATE_JOURNAL" -u eole-guardian@0.service >"/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/e2guardian.log" 
echo "EOLE_CI_PATH e2guardian.log"
echo "***********************************************************"

echo "***********************************************************"
echo "* proxy: squidclient mgr:info"
squidclient mgr:info

echo "***********************************************************"
echo "* Attente de 5 mins pour les logs dstats"

sleep 300

echo "***********************************************************"
echo "* export /var/log/e2guardian/dstats0.log"
if [ "$(wc -l /var/log/e2guardian/dstats0.log)" = "1 /var/log/e2guardian/dstats0.log" ]; then
    echo "Error : /var/log/e2guardian/dstats0.log ne devrait pas etre vide"
else
    cp /var/log/e2guardian/dstats0.log "/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/"
fi
