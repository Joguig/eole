#!/bin/bash

echo "* CreoleSet ups_daemon oui"
CreoleSet nut_ups_daemon oui

echo "* CreoleGet nut_monitor_host"
CreoleGet nut_monitor_host

echo "* battery.charge: 55 !"
echo "battery.charge: 55" > "/etc/nut/$(CreoleGet nut_ups_port)"

echo "* ls /etc/nut/$(CreoleGet nut_ups_port)"
ls "/etc/nut/$(CreoleGet nut_ups_port)"

echo "* reconfigure"
ciMonitor reconfigure

echo "* /usr/share/eole/diagnose/80-nut"
/usr/share/eole/diagnose/80-nut

echo "* iptables-save | grep 3493"
iptables-save | grep 3493

echo "* grep upsd /etc/hosts.allow"
grep upsd /etc/hosts.allow

exit 0