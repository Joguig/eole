#!/bin/bash
echo "Début $0"

echo "* install eole-ltsp-server"
apt-eole install eole-ltsp-server
ciCheckExitCode $?

echo "* Adaptation des variables"
cat >/tmp/configure.py <<EOF
# -*- coding: utf-8 -*-
from creole.loader import creole_loader, config_save_values
c = creole_loader(rw=True)
c.creole.nfs.adresses_network_clients_nfs.adresses_network_clients_nfs = ["10.1.2.0"]
c.creole.nfs.adresses_network_clients_nfs.adresses_netmask_clients_nfs = ["255.255.255.0"]
c.creole.services.activer_bareos_dir = 'non'
c.creole.services.activer_nut = 'non'
c.creole.services.activer_cups = 'non'
c.creole.services.activer_proftpd = 'non'
#c.creole.services.activer_ejabberd = 'non'
config_save_values(c, 'creole')
EOF
python3 /tmp/configure.py
rm -f /tmp/configure.py

CreoleSet ltsp_eole_minimal  non
CreoleSet ltsp_primtux       non
CreoleSet ltsp_livecd_ubuntu oui

if ciVersionMajeurAvant "2.9.0"
then
    CreoleSet activer_ejabberd non
fi

echo "* reconfigure"
ciMonitor reconfigure
ciCheckExitCode $?
