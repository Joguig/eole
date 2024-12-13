#!/bin/bash

# shellcheck disable=SC1091,SC1090
. /root/getVMContext.sh NO_DISPLAY
if [ "$VM_ETABLISSEMENT" == etb3 ]
then
	BASEDN="etb3.lan"
else
	if [ "$VM_ETABLISSEMENT" == etb1 ]
	then
		BASEDN="dompedago.etb1.lan"
	else
		echo "$0: cas non géré"
		exit 0
	fi
fi

dig -t SRV "_ldap._tcp.dc.$BASEDN"
CDU="$?"
if [ "$CDU" -ne 0 ]
then
    ciSignalAlerte "Résolution _ldap._tcp.$BASEDN ... NOK"
else
    echo "* résolution _ldap._tcp.$BASEDN ... OK"
fi

dig -t SRV "_ldap._tcp.dc._msdcs.$BASEDN"
CDU="$?"
if [ "$CDU" -ne 0 ]
then
    ciSignalAlerte "Résolution _ldap._tcp.dc._msdcs.$BASEDN NOK"
else
    echo "* résolution _ldap._tcp.dc._msdcs.$BASEDN OK"
fi

echo "* realm list"
realm list 
echo $?

if realm list | grep -q 'configured: kerberos-member'
then
    echo "PC joint au domaine : OK"
else
    echo "ERREUR: Le PC n'est pas joint au domaine"
fi

if [ "$VM_OWNER" == "ggrandgerard" ]
then
	# déconseillé avec SSSD !
	apt-get remove nscd -y
	
    cat >/etc/nsswitch.conf <<EOF
# /etc/nsswitch.conf
#
passwd:         files systemd sss
group:          files systemd sss
shadow:         files sss
gshadow:        files

hosts:          files mdns4_minimal [NOTFOUND=return] dns
networks:       files

protocols:      db files
services:       db files sss
ethers:         db files
rpc:            db files

netgroup:       nis sss
automount:      sss
EOF

    cat >/etc/sssd/sssd.conf <<EOF
[sssd]
domains = $BASEDN
config_file_version = 2

[domain/$BASEDN]
ad_enabled_domains = $BASEDN
ad_domain = $BASEDN
access_provider = ad
cache_credentials = True
default_shell = /bin/bash
#fallback_homedir = /home/%d/%u
id_provider = ad
krb5_realm = ${BASEDN^^}
krb5_store_password_if_offline = True
ldap_id_mapping = True
realmd_tags = manages-system joined-with-adcli 
use_fully_qualified_names = False
EOF

	systemctl restart sssd
	
    cat >/etc/request-key.d/cifs.spnego.conf <<EOF
create  cifs.spnego    * * /usr/sbin/cifs.upcall -t %k
EOF


    cat >/etc/security/pam_mount.conf.xml <<EOF
<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE pam_mount SYSTEM "pam_mount.conf.xml.dtd">
<pam_mount>
    <debug enable="1" />

    <!-- Volume definitions -->
    <volume fstype="cifs"
            server="scribe.$BASEDN"
            path="%(USER)"
            mountpoint="/home/%(USER)"
            options="cifsacl,cruid=%(USERUID),dir_mode=0700,domain=$BASEDN,file_mode=0600,sec=krb5,uid=%(USERUID),username=%(USER)"
            >
        <sgrp>domain users</sgrp>
    </volume>


    <!-- pam_mount parameters: General tunables -->

    <!--
        <luserconf name=".pam_mount.conf.xml" />
    -->

    <!-- Note that commenting out mntoptions will give you the defaults.
         You will need to explicitly initialize it with the empty string
         to reset the defaults to nothing. -->
    <mntoptions allow="nosuid,nodev,loop,encryption,fsck,nonempty,allow_root,allow_other" />
    <!--
        <mntoptions deny="suid,dev" />
        <mntoptions allow="*" />
        <mntoptions deny="*" />
    -->
    <mntoptions require="nosuid,nodev" />

    <!-- requires ofl from hxtools to be present -->
    <logout wait="0" hup="no" term="no" kill="no" />


    <!-- pam_mount parameters: Volume-related -->
    <mkmountpoint enable="1" remove="1" />

</pam_mount>
EOF


#----------------------
cat /etc/pam.d/lightdm-autologin
#auth    requisite       pam_nologin.so
#auth    required        pam_permit.so
#@include common-account
#session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so close
#session required        pam_limits.so
#@include common-session
#session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so open
#session required        pam_env.so readenv=1
#session required        pam_env.so readenv=1 user_readenv=1 envfile=/etc/default/locale
#@include common-password
#----------------------

#----------------------
cat /etc/pam.d/common-password
password	requisite			pam_pwquality.so retry=3
password	[success=2 default=ignore]	pam_unix.so obscure use_authtok try_first_pass sha512 minlen=4
password	sufficient			pam_sss.so use_authtok
password	requisite			pam_deny.so
password	required			pam_permit.so
password	optional	pam_mount.so disable_interactive
password	optional	pam_gnome_keyring.so 
#----------------------

#----------------------
cat /etc/pam.d/samba
#@include common-auth
#@include common-account
#@include common-session-noninteractive

#----------------------
cat /etc/pam.d/lightdm
#auth    requisite       pam_nologin.so
#auth    sufficient      pam_succeed_if.so user ingroup nopasswdlogin
#@include common-auth
#auth    optional        pam_gnome_keyring.so
#auth    optional        pam_kwallet.so
#auth    optional        pam_kwallet5.so
#@include common-account
#session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so close
#session required        pam_limits.so
#@include common-session
#session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so open
#session optional        pam_gnome_keyring.so auto_start
#session optional        pam_kwallet.so auto_start
#session optional        pam_kwallet5.so auto_start
#session required        pam_env.so readenv=1
#session required        pam_env.so readenv=1 user_readenv=1 envfile=/etc/default/locale
#@include common-password

#----------------------
cat /etc/pam.d/common-account
account	[success=1 new_authtok_reqd=done default=ignore]	pam_unix.so 
account	requisite			pam_deny.so
account	required			pam_permit.so
account	sufficient			pam_localuser.so 
account	[default=bad success=ok user_unknown=ignore]	pam_sss.so 

#----------------------
cat /etc/pam.d/login
#auth       optional   pam_faildelay.so  delay=3000000
#auth       requisite  pam_nologin.so
#session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so close
#session    required     pam_loginuid.so
#session    optional   pam_motd.so motd=/run/motd.dynamic
#session    optional   pam_motd.so noupdate
#session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so open
#session       required   pam_env.so readenv=1
#session       required   pam_env.so readenv=1 envfile=/etc/default/locale
#@include common-auth
#auth       optional   pam_group.so
#session    required   pam_limits.so
#session    optional   pam_lastlog.so
#session    optional   pam_mail.so standard
#session    optional   pam_keyinit.so force revoke
#@include common-account
#@include common-session
#@include common-password
#----------------------
#----------------------
cat /etc/pam.d/mate-screensaver
#@include common-auth
#auth optional pam_gnome_keyring.so
#----------------------
#----------------------
cat /etc/pam.d/newusers
#@include common-password
#----------------------
#----------------------
cat /etc/pam.d/sssd-shadowutils
#auth        [success=done ignore=ignore default=die] pam_unix.so nullok try_first_pass
#auth        required      pam_deny.so
account     required      pam_unix.so
account     required      pam_permit.so
#----------------------
#----------------------
cat /etc/pam.d/lightdm-greeter
#auth    required        pam_permit.so
#auth    optional        pam_gnome_keyring.so
#auth    optional        pam_kwallet.so
#auth    optional        pam_kwallet5.so
#@include common-account
#session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so close
#session required        pam_limits.so
#@include common-session
#session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so open
#session optional        pam_gnome_keyring.so auto_start
#session optional        pam_kwallet.so auto_start
#session optional        pam_kwallet5.so auto_start
#session required        pam_env.so readenv=1
#session required        pam_env.so readenv=1 user_readenv=1 envfile=/etc/default/locale
#----------------------
#----------------------
cat /etc/pam.d/common-session
#session	[default=1]			pam_permit.so
#session	requisite			pam_deny.so
#session	required			pam_permit.so
#session optional			pam_umask.so
#session	required	pam_unix.so 
#session	optional			pam_sss.so 
#session	optional	pam_mount.so 
#session	optional	pam_systemd.so 
#----------------------
#----------------------
#@include common-password
#----------------------
#----------------------
cat /etc/pam.d/common-auth
#auth	[success=2 default=ignore]	pam_unix.so nullok_secure
#auth	[success=1 default=ignore]	pam_sss.so use_first_pass
#auth	requisite			pam_deny.so
#auth	required			pam_permit.so
#auth	optional	pam_mount.so 
#auth	optional			pam_cap.so 
#----------------------


    ls -l /etc/pam.d/
    find /etc/pam.d/ |while read -r f
    do 
       echo "#----------------------"
       echo "cat $f"
       grep -v "^#" "$f" |grep -v "^$" 
       echo "#----------------------"
    done 
else
    ciAfficheContenuFichier /etc/nsswitch.conf
    ciAfficheContenuFichier /etc/realmd.conf
    ciAfficheContenuFichier /etc/sssd/sssd.conf
    ciAfficheContenuFichier /etc/security/pam_mount.conf.xml
    rgrep sss /etc/pam.d/ 
fi

if command -v lightdm 1>/dev/null 2>&1
then
    echo "* lightdm --show-config"
    lightdm --show-config

    echo "* lightdm --test-mode --debug"
    lightdm --test-mode --debug
fi

RESULTAT="0"
id "admin@${BASEDN}"
CDU="$?"
if [ "$CDU" -ne 0 ]
then
    echo "* erreur test 'id admin' : $CDU"
    RESULTAT="1"
fi

id "prof1@${BASEDN}"
CDU="$?"
if [ "$CDU" -ne 0 ]
then
    echo "* erreur test 'id prof1' : $CDU"
    RESULTAT="1"
fi

id "c31e1@${BASEDN}"
CDU="$?"
if [ "$CDU" -ne 0 ]
then
    echo "* erreur test 'id c31e1' : $CDU"
    RESULTAT="1"
fi

echo "RESULTAT=$RESULTAT"
exit "$RESULTAT"
