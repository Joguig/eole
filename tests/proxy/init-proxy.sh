#!/bin/bash

echo "Bascule adresse_ip_dns -> ADDC"
CreoleSet adresse_ip_dns 192.168.0.30

ciMonitor reconfigure

bash enregistrement-amon-si-besoin.sh "${VM_VERSIONMAJEUR}"

ciSauvegardeCaMachine

ciDiagnose 
    
ciAptEole squidclient

if [ ! -d /root/.ssh ]
then
    mkdir -p /root/.ssh
fi
if [ ! -f /root/.ssh/id_rsa ]
then
    echo "* Generation de la clef SSH pour les echanges entre DC"
    if ! ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""
    then
        return 1
    fi
fi
    
echo "***********************************************************"
echo "* openssl version"
openssl version

echo "***********************************************************"
echo "* e2guardian -v"
e2guardian -v 

echo "***********************************************************"
echo "* squid -v"
squid -v

echo "***********************************************************"
echo "* cat /etc/guardian/guardian0/guardian.conf (ce n'est pas le e2guardian par défault !)"
grep -v "#" </etc/guardian/guardian0/guardian.conf |sort |uniq

echo "***********************************************************"
echo "* cat /etc/squid/squid.conf"
sort </etc/squid/squid.conf

echo "***********************************************************"
echo "* cat /etc/squid/common-squid1.conf"
sort </etc/squid/common-squid1.conf

echo "***********************************************************"
echo "* cat /etc/squid/01inc-squid.conf"
sort </etc/squid/01inc-squid.conf

echo "***********************************************************"
echo "* cat /etc/squid/common-squid2.conf"
sort </etc/squid/common-squid2.conf

echo "***********************************************************"
echo "* squidclient mgr:info"
squidclient mgr:info

echo "***********************************************************"
echo "* restart squid "
systemctl stop squid.service
ciClearJournalLogs
systemctl restart squid.service

date +'%Y-%m-%d %H:%M' >/root/DATE_JOURNAL
