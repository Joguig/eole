#!/bin/bash

# je déclare l'entrée Salt dans le dnsmasq de la gateway pour les postes non intégrés 
#echo "* déclare 'salt' dans GW"
#echo "192.168.0.5 salt" >/etc/dnsmasq-hostsdir/salt.conf

# options demandées : 1:netmask, 15:domain-name, 3:router, 6:dns-server,
# options demandées : 44:netbios-ns, 46:netbios-nodetype, 47:netbios-scope,
# options demandées : 31:router-discovery, 33:static-route, 121:classless-static-route,
# options demandées : 249, 43:vendor-encap

# options demandées Windows
# options demandées : 1:netmask, 3:router, 6:dns-server, 15:domain-name,
# options demandées : 31:router-discovery, 33:static-route, 43:vendor-encap,
# options demandées : 44:netbios-ns, 46:netbios-nodetype, 47:netbios-scope,
# options demandées : 119:domain-search, 121:classless-static-route,
# options demandées : 249, 252

# nom de fichier 'bootfile' : pxelinux.0
# serveur suivant : 192.168.0.1
# sent size:  4 option:  1 netmask  255.255.255.0
# sent size:  4 option:  3 router  192.168.0.1
# sent size:  4 option:  6 dns-server  192.168.0.1
# sent size: 10 option: 15 domain-name  ac-test.fr
# sent size:  4 option: 28 broadcast  192.168.0.255
# sent size:  7 option: 43 vendor-encap  02:04:00:00:00:01:ff
# sent size:  4 option: 51 lease-time  2h
# sent size:  1 option: 53 message-type  5
# sent size:  4 option: 54 server-identifier  192.168.0.1
# sent size:  4 option: 58 T1  1h
# sent size:  4 option: 59 T2  1h45m
# sent size:  8 option: 60 vendor-class  4d:53:46:54:20:35:2e:30 = "MSFT 5.0"
# sent size: 23 option: 81 FQDN  03:ff:ff:50:43:2d:37:37:32:39:32:33:2e:61... "PC-772923.ac-test.fr" !!

# DNSMASQ
#Options DHCP connues :
#  1 netmask
#  2 time-offset
#  3 router
#  6 dns-server
#  7 log-server
#  9 lpr-server
# 13 boot-file-size
# 15 domain-name
# 16 swap-server
# 17 root-path
# 18 extension-path
# 19 ip-forward-enable
# 20 non-local-source-routing
# 21 policy-filter
# 22 max-datagram-reassembly
# 23 default-ttl
# 26 mtu
# 27 all-subnets-local
# 31 router-discovery
# 32 router-solicitation
# 33 static-route
# 34 trailer-encapsulation
# 35 arp-timeout
# 36 ethernet-encap
# 37 tcp-ttl
# 38 tcp-keepalive
# 40 nis-domain
# 41 nis-server
# 42 ntp-server
# 44 netbios-ns
# 45 netbios-dd
# 46 netbios-nodetype
# 47 netbios-scope
# 48 x-windows-fs
# 49 x-windows-dm
# 58 T1
# 59 T2
# 60 vendor-class
# 64 nis+-domain
# 65 nis+-server
# 66 tftp-server
# 67 bootfile-name
# 68 mobile-ip-home
# 69 smtp-server
# 70 pop3-server
# 71 nntp-server
# 74 irc-server
# 77 user-class
# 80 rapid-commit
# 93 client-arch
# 94 client-interface-id
# 97 client-machine-id
#119 domain-search
#120 sip-server
#121 classless-static-route
#125 vendor-id-encap
#255 server-ip-address

#echo "* déclare forward domseth.ac-test vers les DC1/DC2"
#/bin/rm -rf /etc/dnsmasq.d/domseth.conf
#cat >/etc/dnsmasq.d/domseth.conf <<EOF
#server=/domseth.ac-test.fr/192.168.0.6
#server=/domseth.ac-test.fr/192.168.0.5
#server=/0.168.192.in-addr.arpa/192.168.0.6
#server=/0.168.192.in-addr.arpa/192.168.0.5
#dhcp-option=net:actest,option:domain-name,domseth.ac-test.fr
#dhcp-option=net:actest,option:dns-server,192.168.0.5
#dhcp-option=net:actest,vendor:MSFT,2,1i
#dhcp-option=net:actest,option:ntp-server,192.168.0.5
#log-queries
#domain-suffix=domseth.ac-test.fr
#local=/domseth.ac-test.fr/
#EOF

#echo "* efface logs gateway"
#ciClearJournalLogs 1>/dev/null 2>&1

#echo "* Reload dnsmasq.service"
#systemctl stop dnsmasq.service
#systemctl start dnsmasq.service

echo "* Verification 'salt.domseth.ac-test.fr' doit être connu du Domaine"
dig @192.168.0.5 +short salt.domseth.ac-test.fr

echo "* Vérification résolution 'salt'"
dig @192.168.0.1 +short salt

echo "* Vérification du Forward de la GW vers les DC "
dig @192.168.0.1 +short domseth.ac-test.fr

