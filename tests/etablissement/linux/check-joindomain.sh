#!/bin/bash

function testUser()
{
    local U="$1"

    echo ""
    echo ""
    echo "*********************************************************************"
    echo "Test : $U"
    echo ""
    
    if [ -d "/home/${AD_REALM}" ]
    then
        ls -l "/home/${AD_REALM}"
    else
        echo "/home/${AD_REALM} manque!" 
    fi
    
    echo "* id :"
    id "$U@${AD_REALM}"
    CDU="$?"
    if [ "$CDU" -ne 0 ]
    then
        echo "* Erreur test 'id $U' : $CDU"
        RESULTAT="1"
    else
        echo "* Test 'id $U' : OK"
    fi
    
    echo "* getent passwd :"
    getent passwd "$U@${AD_REALM}"
    CDU="$?"
    if [ "$CDU" -ne 0 ]
    then
        echo "* Erreur test 'getent $U' : $CDU"
        RESULTAT="1"
    else
        echo "* Test 'getent $U' : OK"
    fi
    
    echo "* groups :"
    groups "$U@${AD_REALM}"
    CDU="$?"
    if [ "$CDU" -ne 0 ]
    then
        echo "* erreur test 'groups $U' : $CDU"
        RESULTAT="1"
    else
        echo "* Test 'groups $U' : OK"
    fi
    
    echo "* kinit :"
    kdestroy -A 2>/dev/null
    echo "Eole12345!" >/root/pwd
    KRB5_TRACE=/dev/stdout kinit  --password-file=/root/pwd "$U@${AD_REALM^^}" 2>/dev/null
    CDU="$?"
    if [ "$CDU" -eq 2 ]
    then
        kinit "$U@${AD_REALM^^}" < <(cat /root/pwd)
        CDU="$?"
    fi
    if [ "$CDU" -ne 0 ]
    then
        echo "* Erreur test 'kinit $U' : $CDU"
        RESULTAT="1"
    else
        echo "* Test 'kinit $U' : OK"
    fi
    
    klist 
    
    #echo "* net ads enctypes list ${U} "
    #net ads enctypes list "${U}" -k
    
    #echo "* ksu - '$U@${AD_REALM}' -c 'pwd;exit' <<  "Eole12345!" "
    #ksu -l "$U@${AD_REALM}" -c "pwd;exit"
    #CDU="$?"
    #if [ "$CDU" -ne 0 ]
    #then
    #   echo "* erreur test 'ksu $U' : $CDU"
    #   RESULTAT="1"
    #fi
    
    echo "* ldapsearch GSSAPI "
    ldapsearch -H "ldap://${AD_REALM}" -Y GSSAPI -b "CN=Users,$BASEDN" "cn=$U" dn
    CDU="$?"
    if [ "$CDU" -ne 0 ]
    then
	    echo "* Test 'ldapsearch $U' : KO"
        #RESULTAT="1"
    else
        echo "* Test 'ldapsearch $U' : OK"
    fi
    
    kdestroy 2>/dev/null
}

# shellcheck disable=SC1091,SC1090
. /root/getVMContext.sh NO_DISPLAY
if [ "$VM_ETABLISSEMENT" == etb3 ]
then
	AD_REALM="etb3.lan"
	BASEDN="DC=etb3,DC=lan"
else
	if [ "$VM_ETABLISSEMENT" == etb1 ]
	then
		AD_REALM="dompedago.etb1.lan"
		BASEDN="DC=dompedago,DC=etb1,DC=lan"
	else
		echo "$0: cas non géré"
		exit 0
	fi
fi

echo "HACK: je forec le apply en local au cas ou"
salt-call -l debug state.highstate apply
echo "-----------------"
echo "-----------------"
echo " Test acces"
echo "-----------------"

dig -t SRV "_ldap._tcp.dc.$AD_REALM"
CDU="$?"
if [ "$CDU" -ne 0 ]
then
    ciSignalAlerte "Résolution _ldap._tcp.$AD_REALM ... NOK"
else
    echo "* résolution _ldap._tcp.$AD_REALM ... OK"
fi

dig -t SRV "_ldap._tcp.dc._msdcs.$AD_REALM"
CDU="$?"
if [ "$CDU" -ne 0 ]
then
    ciSignalAlerte "Résolution _ldap._tcp.dc._msdcs.$AD_REALM NOK"
else
    echo "* résolution _ldap._tcp.dc._msdcs.$AD_REALM OK"
fi

if [ -f /var/log/salt/minion ] 
then
    echo "/var/log/salt/minion présent"
    cp /var/log/salt/minion "/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/minion.log"
    echo "EOLE_CI_PATH minion.log"
else
    ciSignalWarning  "/var/log/salt/minion absent"
fi

echo "* realm list"
realm list 
echo $?

if realm list | grep -q 'configured: kerberos-member'
then
    echo "PC joint au domaine : OK"
else
    echo "ERREUR: Le PC n'est pas joint au domaine"
    exit 1
fi

RESULTAT="0"

testUser admin
testUser prof1
testUser c31e1

if [ "$RESULTAT" == "1" ]
then
    ciAfficheContenuFichier /etc/nsswitch.conf
    ciAfficheContenuFichier /etc/realmd.conf
    ciAfficheContenuFichier /etc/krb5.conf
    ciAfficheContenuFichier /etc/sssd/sssd.conf
    ciAfficheContenuFichier /etc/ssh/sshd_config
    ciAfficheContenuFichier /etc/security/pam_mount.conf.xml
    rgrep sss /etc/pam.d/ 

    if command -v lightdm 1>/dev/null 2>&1
    then
        mkdir -p /etc/systemd/system/lightdm.service.d
        cat >/etc/systemd/system/lightdm.service.d/fixes.conf <<EOF
[Unit]
Wants=dbus.socket user.slice
After=dbus.socket user.slice

[Service]
# Trying to explicitly declare Type=dbus as original lightdm.service has
# BusName=org.freedesktop.DisplayManager which sets Type=dbus anyway acc. to
# https://www.freedesktop.org/software/systemd/man/systemd.service.html
Type=dbus
RestartSec=10s
ExecStartPre=/bin/sleep 5
EOF

        echo "* lightdm --show-config"
        lightdm --show-config

        #echo "* lightdm --test-mode --debug"
        #lightdm --test-mode --debug
    fi
fi

echo "RESULTAT=$RESULTAT"
exit "$RESULTAT"
