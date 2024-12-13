#!/bin/bash

tail -f \
    /var/log/lsc/lsc.log \
    /var/log/mysql/error.log \
    /var/log/rsyslog/local/imapd/imapd.debug.log \
    /var/log/rsyslog/local/ntpd/ntpd.info.log \
    /var/log/rsyslog/local/clamd/clamd.info.log \
    /var/log/rsyslog/local/creoled/creoled.info.log \
    /var/log/rsyslog/local/dbus-daemon/dbus-daemon.info.log \
    /var/log/rsyslog/local/systemd/systemd.info.log \
    /var/lib/lxc/addc/rootfs/var/log/auth.log \
    /var/lib/lxc/addc/rootfs/var/log/syslog \
    /var/lib/lxc/addc/rootfs/var/log/samba/log.samba  
