#!/bin/bash

echo "* Force synchro dc2 pour actualiser la GPO"
echo >/var/log/samba/JobSynchro.log

# je ne veux pas du log d'erreur ici ! donc 2>/dev/null
bash -x /usr/share/eole/sbin/JobSynchroSysvol 1>/dev/null 2>/dev/null

if samba-tool ntacl sysvolcheck 1>/dev/null 2>/dev/null
then
    echo "* samba-tool ntacl sysvolcheck : ERREUR"
    cp /var/log/samba/JobSynchro.log "/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/JobSynchro.log"
    echo "EOLE_CI_PATH JobSynchro.log"
    
    echo "* ls -lR /home/sysvol/domseth.ac-test.fr/Policies/"
    ls -lR /home/sysvol/domseth.ac-test.fr/Policies/ >/tmp/avant

    echo "ATTENTION: samba-tool ntacl sysvolreset"
    samba-tool ntacl sysvolreset
    
    ls -lR /home/sysvol/domseth.ac-test.fr/Policies/ >/tmp/apres
    
    echo "* diff (ls -lR /home/sysvol/domseth.ac-test.fr/Policies/)"
    diff /tmp/avant /tmp/apres
else
    echo "* samba-tool ntacl sysvolcheck : Ok"
fi

echo "* samba_dnsupdate from DC1"
samba_dnsupdate --verbose --use-samba-tool --rpc-server-ip=192.168.0.5

# cf. https://wiki.samba.org/index.php/Manually_Replicating_Directory_Partitions
echo "* samba-tool drs replicate DC2 DC1"
samba-tool drs replicate DC2 DC1 DC=domseth,DC=ac-test,DC=fr
samba-tool drs replicate DC2 DC1 DC=ForestDnsZones,DC=domseth,DC=ac-test,DC=fr
samba-tool drs replicate DC2 DC1 CN=Configuration,DC=domseth,DC=ac-test,DC=fr
samba-tool drs replicate DC2 DC1 DC=DomainDnsZones,DC=domseth,DC=ac-test,DC=fr
samba-tool drs replicate DC2 DC1 CN=Schema,CN=Configuration,DC=domseth,DC=ac-test,DC=fr

echo "* samba-tool drs showrepl"
samba-tool drs showrepl

echo "* samba_kcc export topology"
mkdir -p /tmp/dot
pushd /tmp/dot >/dev/null || exit 1
samba_kcc --dot-file-dir=/tmp/dot
mkdir -p "/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/kcc/"
for F in *.dot
do
    F1="${F#*=}"
    cp "$F" "/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/kcc/$F1"
    echo "EOLE_CI_PATH kcc/$F1"
done
popd >/dev/null || exit 1