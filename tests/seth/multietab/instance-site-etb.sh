#!/bin/bash

ETB="$1"
SITE="000000${ETB}"

cp -vf samba4.sh /usr/lib/eole/samba4.sh

samba-tool domain info -U 'Administrator%Eole12345!' 192.168.0.5

cat >/etc/resolv.conf <<EOF 
search domseth.ac-test.fr
nameserver 192.168.0.5
EOF
ciAfficheContenuFichier /etc/resolv.conf

cat >/etc/resolv.conf <<EOF 
[libdefaults]
default_realm = DOMSETH.AC-TEST.FR
dns_lookup_realm = true
dns_lookup_kdc = false
EOF
ciAfficheContenuFichier /etc/krb5.conf

cat >/etc/samba/smb.conf <<EOF 
[global]
  realm = DOMSETH.AC-TEST.FR
  workgroup = ETB1
  netbios name = DCPEDAGO1
  disable netbios = yes
  smb ports = 445
  restrict anonymous = 2
  usershare max shares = 0
  map acl inherit = Yes
  winbind separator = /
  server role = active directory domain controller
  server services = -dns
  tls enabled = yes
  tls keyfile = /var/lib/samba/private/tls/private/addc.key
  tls certfile = /var/lib/samba/private/tls/certs/addc.crt
  tls cafile =
  log level = 0
  vfs objects = dfs_samba4 acl_xattr
  winbind max clients = 400
  winbind request timeout = 30
  winbind refresh tickets = Yes

[netlogon]
  comment = Network Logon Service
  path = /home/sysvol/DOMSETH.AC-TEST.FR/scripts
  read only = No
  guest ok = yes
  vfs objects = dfs_samba4 acl_xattr

[sysvol]
  comment = Sysvol Service
  path = /home/sysvol
  read only = No
  guest ok = yes
  vfs objects = dfs_samba4 acl_xattr

[homes]
  path = "/home/adhomes/%u"
  root preexec = /usr/share/eole/sbin/create_adhome.sh "%u" "/home/adhomes"
  comment = Home Directories
  browseable = no
  read only = no

[profiles]
  comment = Profiles
  path = "/home/adprofiles"
  read only = No
EOF

ciAfficheContenuFichier /etc/samba/smb.conf

echo "* ETB=$ETB SITE=$SITE"
#ciConfigurationEole instance "siteetb$ETB"
#bash -x /usr/share/eole/postservice/25-manage-samba instance

# shellcheck disable=SC1091
. /etc/eole/samba4-vars.conf
bash -x /usr/share/eole/samba/samba_configure instance


ciAfficheContenuFichier /etc/resolv.conf
ciAfficheContenuFichier /etc/krb5.conf
ciAfficheContenuFichier /etc/samba/smb.conf

