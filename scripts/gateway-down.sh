#!/bin/bash
# Commande configurer 'route'
if [ "$(id -u)" != "0" ]; then
   echo "Ce script doit être lancée en 'root'" 1>&2
   exit 1
fi
ip route del 192.168.0.0/24
ip route del 192.168.227.0/24
/sbin/route
#