#!/bin/bash
# Commande configurer 'route'
if [ "$(id -u)" != "0" ];
then
   echo "Ce script doit être lancé en 'root'" 1>&2
   exit 1
fi
if [ -z "$1" ]
then
   gateway=$(awk '/192.168.230.[0-9]+.*gateway.ac-test.fr/ {print $1}' /etc/hosts)
   if [ -z "$gateway" ]
   then
       echo "ERREUR : pas de gateway dans votre /etc/hosts"
       exit 1
   fi
else
   gateway=$1
fi
echo la gateway est "$gateway"
ip route del default via 192.168.0.254
ip route del 192.168.0.0/24 2>/dev/null
ip route del 192.168.227.0/24 2>/dev/null
ip route add default via 192.168.0.254
ip route add 192.168.0.0/24 via "$gateway"
ip route add 192.168.227.0/24 via "$gateway"
ip route

systemd-resolve --flush-caches

if grep -q "127.0.0.53" /etc/resolv.conf
then
    # cas systemd-resvolved
    systemd-resolve  --set-dns "$gateway" --interface eno1
fi
ping -c 2 eole3.ac-test.fr
dig @192.168.0.1 eole3.ac-test.fr

dig @"$gateway" eole3.ac-test.fr
