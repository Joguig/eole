#!/bin/bash

testSSLPort() {
  echo "******************************** certificats $1"
  echo "x" | timeout 10 openssl s_client -connect "$1" -showcerts 2>/dev/null >/tmp/showcerts
  cdu=$?
  echo "********************************"
  if [ "$cdu" == "0" ]
  then
    grep "/C=" </tmp/showcerts 
  else
    echo "ERREUR $1"
    exit 1
  fi
}

[ ! -f /usr/bin/timeout ] && apt-get -y install timeout

scp root@192.168.0.1:/root/0211227V-amon.key /etc/ssl/certs/0211227V-amon.key 
if [ "$?" -ne 0 ] 
then
   echo "ERREUR: la cle privée n'est pas sur votre gateway !"
   exit 1
fi
scp root@192.168.0.1:/root/0211227V-amon.pem /etc/ssl/certs/0211227V-amon.crt
chmod 600 /etc/ssl/certs/0211227V-amon.key

CONFIGURATION=leparc METHODE=instance ciConfigurationEole

server=localhost
testSSLPort "$server:443"
testSSLPort "$server:4200"
testSSLPort "$server:8443"

# ls | grep -i infra | while read f ; do openssl x509 -in $f -subject -noout ; done

