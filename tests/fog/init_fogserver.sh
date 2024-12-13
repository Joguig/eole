#!/bin/bash

mkdir -p /images

echo "FDISK vdb "
( printf "d\nn\np\n1\n1\n\n\nw\n" | fdisk /dev/sdb )
        
echo "FORMATAGE vdb ext4 et creation de sdb1 "
mkfs -t ext4 /dev/sdb1
    
echo "/dev/sdb1 /images ext4 defaults,noatime 0 3" >>/etc/fstab

echo "mount /images"
mount /dev/sdb1 /images
#chown -R oneadmin:oneadmin /images

ls -l /images
