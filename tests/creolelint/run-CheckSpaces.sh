#!/bin/bash

echo "/"
du -h --max-depth=1 --exclude /proc --exclude /sys --exclude /dev --exclude /run --exclude /mnt/eole-ci-tests --exclude /tmp --exclude /mnt/cdrom / >/tmp/avant

echo "/var/cache"
du -h --max-depth=1 /var/cache

echo "/var/lib"
du -h --max-depth=1 /var/lib

cd /usr/src || exit 1
ls -l
export DEBIAN_FRONTEND=noninteractive
apt-get remove -y "$(ls linux-headers-* )"
cd /
apt-get autoremove -y
apt-get clean -y
apt-get purge -y

echo "rm cache"
/bin/rm -f /var/cache/apt/archives/*
/bin/rm -f /var/lib/apt/lists/*

echo "du /var/cache"
du -h --max-depth=1 /var/cache

echo "du /var/lib"
du -h --max-depth=1 /var/lib

echo "/ apres"
du -h --max-depth=1 --exclude /proc --exclude /sys --exclude /dev --exclude /run --exclude /mnt/eole-ci-tests --exclude /tmp --exclude /mnt/cdrom / >/tmp/apres

sort -n </tmp/apres

diff /tmp/avant /tmp/apres
