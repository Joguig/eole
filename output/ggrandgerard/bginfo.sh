#!/bin/bash
# Author : Vikram Khatri vikram@zinox.com
#
# Purpose: Add BGInfo like information on Linux Desktop
mkdir -p /root/bin

SCHOME=/root/bin/backup
mkdir -p $SCHOME
BGFILE=$SCHOME/sys.info
BG=$SCHOME/bg.png
#ORIGWALL=/usr/share/backgrounds/poc/PerformanaceManagementTools.png
ORIGWALL=/usr/share/backgrounds/ubuntu-mate-common/Green-Wall-Logo-Text.png
NEWWALL=$SCHOME/PerformanaceManagementTools.png
WALL=/usr/share/backgrounds/ubuntu-mate-common/

> $BGFILE

   A_UPTIME="                      Uptime : "
 A_HOSTNAME="                   Host Name : "
 A_USERNAME="                   User Name : "
   A_NUMCPU="                  Num of CPU : "
 A_CPUMODEL="                   CPU Model : "
 A_MEMTOTAL="                Total Memory : "
A_OSVERSION="                  OS Version : "
A_IPADDRESS="                  IP Address : "
A_DNSSERVER="                  DNS Server : "
  A_GATEWAY="                     Gateway : "
 A_FREEDISK="             Disk Free Space : "

B_UPTIME=`procinfo | grep uptime | awk '{print $2}'`
B_HOSTNAME=`hostname`
B_USERNAME=`whoami`
B_NUMCPU=`cat /proc/cpuinfo | grep processor | wc -l`
B_CPUMODEL=`cat /proc/cpuinfo | grep "model name" | awk -F":" '{print $2}' | head -1 | sed -e 's/^ *//'`
B_MEMTOTAL=`cat /proc/meminfo | grep MemTotal | sed -e 's/^ *//' | awk -F":" '{print $2}'`
B_OSVERSION=`uname -srm`
B_IPADDRESS=`/sbin/ifconfig | grep "inet addr" | grep -v 127.0.0.1 | awk '{print $2}' | awk -F":" '{print $2}'` 
B_DNSSERVER=`grep ^nameserver /etc/resolv.conf | awk '{print $2}'` 
B_GATEWAY=`netstat -rn | grep UG | awk '{print $2}'` 
B_FREEDISK=`df -k | grep ^/dev | awk '{print $1" "$4" KB Available"}'`

echo "$A_UPTIME" $B_UPTIME >> $BGFILE
echo "$A_HOSTNAME" $B_HOSTNAME >> $BGFILE
echo "$A_USERNAME" $B_USERNAME >> $BGFILE
echo "$A_OSVERSION" $B_OSVERSION >> $BGFILE
echo "$A_IPADDRESS" $B_IPADDRESS >> $BGFILE
echo "$A_NUMCPU" $B_NUMCPU >> $BGFILE
echo "$A_DNSSERVER" $B_DNSSERVER >> $BGFILE
echo "$A_CPUMODEL" $B_CPUMODEL >> $BGFILE
echo "$A_MEMTOTAL" $B_MEMTOTAL >> $BGFILE
echo "$A_GATEWAY" $B_GATEWAY >> $BGFILE
echo " " >> $BGFILE

sudo sed -i '/PDF/s/none/read|write/' /etc/ImageMagick-6/policy.xml

convert -font Courier-Bold -pointsize 30 -background none -fill white texte:@$GBFILE "$BG"

composite -gravity south $BG $ORIGWALL $NEWWALL
cp -v $NEWWALL $ORIGWALL
