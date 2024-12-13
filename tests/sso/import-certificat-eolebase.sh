#!/bin/bash

ciMonitor scp root@scribe.ac-test.fr:/etc/ssl/certs/stunnel_client.crt /etc/stunnel/eole/

#2.8 SSL: no alternative certificate subject name matches target host name 'scribe.ac-test.fr'
ciMonitor scp root@scribe.ac-test.fr:/etc/ssl/certs/ca_local.crt /etc/stunnel/eole/

/usr/share/eole/posttemplate/30-eolesso-cluster

ls -l /etc/stunnel/eole/
