#!/bin/bash

 # je n'ai plus besoin de' l'entrée Salt dans le dnsmasq de la gateway, le poste doit être intégré 
#if [ -f /etc/dnsmasq-hostsdir/salt.conf ]
#then
#   /bin/rm -v /etc/dnsmasq-hostsdir/salt.conf
#fi

#echo "* restaure domseth"
#/bin/rm -rf /etc/dnsmasq.d/domseth.conf
#cat >/etc/dnsmasq.d/domseth.conf <<EOF
#server=/domseth.ac-test.fr/192.168.0.6
#server=/domseth.ac-test.fr/192.168.0.5
#server=/0.168.192.in-addr.arpa/192.168.0.6
#server=/0.168.192.in-addr.arpa/192.168.0.5
#EOF

#echo "* journalctl -xe -u dnsmasq.service"
#journalctl --no-pager -xe -u dnsmasq.service

#echo "* redémarrage dnsmasq"
#systemctl stop dnsmasq.service
#systemctl start dnsmasq.service
 
 