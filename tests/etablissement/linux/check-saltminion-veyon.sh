#!/bin/bash

echo "* systemctl status salt-minion.service"
systemctl --no-pager status salt-minion.service

echo "* journalctl --no-pager -u salt-minion --since -15m"
journalctl --no-pager -u salt-minion --since -15m

echo "* veyon ?"
# shellcheck disable=SC2009
ps fax |grep veyon

echo "* systemctl status veyon.service "
systemctl --no-pager status veyon.service
ciCheckExitCode $? "VEYON n'est pas installé !'"

echo "* journalctl --no-pager -u veyon.service --since -15m"
journalctl --no-pager -u veyon.service --since -15m

exit 0
