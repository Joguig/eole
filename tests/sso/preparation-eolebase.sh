#!/bin/bash

ciAptEole eole-sso-cluster-server

ciMonitor reconfigure

CreoleGet --list | grep redis_
CreoleGet --list | grep eolesso_

#activer_redis="oui"
#redisMaxClients="10000"
#redisMaxMemory="512"
#redisMemoryPolicy="noeviction"
#redisMode="Local"
#redisPort="6379"
#redisSSL="non"
#redisSSLVersion="TLSv1"
#redisTCPKeepAlive="60"
#redis_server_cert="/etc/ssl/certs/stunnel_server.crt"
#redis_server_key="/etc/ssl/private/stunnel_server.key"
#eolesso_cluster_server="oui"
#eolesso_redis_host="localhost"
#eolesso_redis_port="9380"
#eolesso_stunnel_host="192.168.0.24"
#eolesso_stunnel_port="9380"

ls -al /etc/ssl/certs/stunnel_server.crt

ciPrintMsgMachine "Vérification du port 9380"
netstat -ntlp | grep 9380

ciPrintMsgMachine "Vérification règle d'autorisation"
iptables-save | grep 9380

ciSauvegardeCaMachine
