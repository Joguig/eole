#!/bin/bash

ciMonitor scp root@eolebase.ac-test.fr:/etc/ssl/certs/stunnel_server.crt /etc/stunnel/eole/

/usr/share/eole/posttemplate/30-eolesso-cluster

ls -l /etc/stunnel/eole

systemctl restart stunnel4

ciPrintMsgMachine "Vérification du port 9380"
netstat -ntlp | grep 9380
