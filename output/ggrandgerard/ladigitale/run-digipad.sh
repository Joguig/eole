#!/bin/bash

BASE=/root/ladigitale
WORK=/root

apt install nfs-common -y

mkdir -p $WORK/etherpad-lite
mkdir -p $WORK/etherpad-lite/etherpad
mkdir -p $WORK/mysql_data
mkdir -p $WORK/nfs-storage
mkdir -p $WORK/redis-data
chmod 777 $WORK/redis-data
cd $WORK || exit 1 
cat "$WORK/etherpad-lite/etherpad/settings.json"
#cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 36 | head -n 1 >$WORK/etherpad-lite/etherpad/APIKEY.txt

