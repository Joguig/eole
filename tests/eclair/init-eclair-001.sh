#!/bin/bash
SCRIBE="${1:-scribe.etb1.lan}"
echo "Début $0 : $SCRIBE"

ciSetHttpProxy

if [ "$VM_MACHINE" = "etb1.eclairdmz" ]
then
    ciInjectCaMachineSsh scribe.etb1.lan gaspacho-server
    ciCheckExitCode $?
else
    if [ "$VM_MACHINE" = "etb3.eclair" ]
    then
        ciInjectCaMachineVirtfs etb3.amonecole gaspacho-server
        ciCheckExitCode $?
    else
        echo "* context inconnu dans $0"
        exit 1
    fi
fi

echo "* install gaspacho-agent"
apt-eole install gaspacho-agent

echo "* ls -l /home avant instance"
ls -l /home

# attention : monitor eclair_001 ==> oui
ciInstanceDefault
ciCheckExitCode $?

tree /var/lib/tftpboot/ltsp/

if [ "$VM_VERSIONMAJEUR" \< "2.6.1" ]
then
    REPERTOIRE=amd64
    LTS=lts.conf
else
    REPERTOIRE=default
    LTS=lts27.conf
fi

if [ ! -f "/var/lib/tftpboot/ltsp/${REPERTOIRE}/lts.conf" ]
then
    echo "* /var/lib/tftpboot/ltsp/${REPERTOIRE}/lts.conf manquant !"
    ciCheckExitCode 1
fi

echo "* cp ${LTS} /var/lib/tftpboot/ltsp/${REPERTOIRE}/lts.conf"
/bin/cp -f ${LTS} "/var/lib/tftpboot/ltsp/${REPERTOIRE}/lts.conf"

echo "* cat /var/lib/tftpboot/ltsp/${REPERTOIRE}/lts.conf"
cat "/var/lib/tftpboot/ltsp/${REPERTOIRE}/lts.conf"

echo "* ls -l /home apres instance"
ls -l /home

echo "* mount"
mount

echo "pause 30 secondes"
sleep 30

echo "ps fax"
ps fax

echo "netstat -ntlp"
netstat -ntlpu

echo "iptables-save"
iptables-save

echo "Fin $0"
