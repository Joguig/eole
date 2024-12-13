#!/bin/bash

apt-eole install make
apt-eole install git
apt-eole install samba samba-common python-samba samba-dsdb-modules samba-libs samba-vfs-modules ldb-tools winbind acl
apt-eole install krb5-user
apt-eole install smbclient

cd /root
if [ -d eole-ad-dc ]
then
    echo "******** ACTUALISATION GIT eole-ad-dc *****************"
    cd /root/eole-ad-dc
    git pull
else
    echo "******** CLONE GIT eole-ad-dc *****************"
    git clone https://dev-eole.ac-dijon.fr/git/eole-ad-dc.git
fi
cd /root/eole-ad-dc
make install

[ ! -f /root/fstab.sav ] && cp /etc/fstab /root/fstab.sav
sed -e '/eolebase--vg-root/s#errors=remount-ro #errors=remount-ro,barrier=1,acl,user_xattr #' -i /etc/fstab
exit 1