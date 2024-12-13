#!/bin/bash

MACHINE="$1"
if [ -z "$MACHINE" ]
then
    echo "MACHINE inconnu !"
    exit 1
fi

echo "* rm -rf /etc/dnsmasq.d/$MACHINE.conf "
/bin/rm -rf "/etc/dnsmasq.d/$MACHINE.conf"

echo "* Stop dnsmasq.service"
systemctl stop dnsmasq.service

echo "* Test dnsmasq.service"
if ! dnsmasq --test
then
    echo "* ERREUR dnsmasq"
fi

echo "* Start dnsmasq.service"
systemctl start dnsmasq.service

echo "* Vérification de la GW"
dig @192.168.0.1 +short "hestia.eole.lan"