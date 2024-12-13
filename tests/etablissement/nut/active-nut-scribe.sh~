#!/bin/bash

echo "* 80-nut avant"
/usr/share/eole/diagnose/80-nut

echo "* CreoleSet..."
ciRunPython CreoleSet_Multi.py <<EOF
set activer_nut oui
set nut_ups_daemon non
set nut_monitor_foreign_name 0 dummy
set nut_monitor_foreign_host 0 10.1.3.5
set nut_monitor_foreign_password 0 nut_monitor_password
set nut_monitor_foreign_user 0 amon-ups
EOF

echo "* reconfigure"
ciMonitor reconfigure

echo "* 80-nut apres"
/usr/share/eole/diagnose/80-nut
