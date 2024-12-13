#!/bin/bash 
CHEMIN_MOUNT=$1
if [[ -z "$1" ]] || [[ -z "$2" ]]
then
    echo "Usage:  sshfs.sh <point_montage> <user@host:/path>"
    exit 1
fi
CHEMIN_SSH=$2
echo $(id)
[ ! -f /usr/bin/sshfs ] && sudo apt-get install sshfs
if [ ! -d $CHEMIN_MOUNT ]
then
    echo "$CHEMIN_MOUNT n'existe pas "
    echo "faire:"
    echo "sudo mkdir $CHEMIN_MOUNT"
    echo "sudo chmod 777 $CHEMIN_MOUNT"
    exit 1
fi
#fusermount -u $CHEMIN_MOUNT
if [ -d $CHEMIN_MOUNT ]
then
   sshfs $CHEMIN_SSH $CHEMIN_MOUNT -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -o cache=yes -o cache_timeout=5 -o cache_stat_timeout=5 -o cache_dir_timeout=5 -o cache_link_timeout=5 -o nonempty -o uid=1000,gid=1000 -o allow_other -o large_read -o kernel_cache -o compression=no -o IdentityFile=$HOME/.ssh/id_rsa
   echo "sshfs => $?"
   ls -l $CHEMIN_MOUNT
else
   echo "$CHEMIN_MOUNT déjà monté"
fi
