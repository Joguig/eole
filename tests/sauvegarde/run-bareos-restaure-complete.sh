#!/bin/bash

BAREOS_RESULT="0"

# obligatoire pour positionner le proxy!
ciMajAutoSansTest
ciCheckExitCode $?

ciAptEole eole-bareos
ciCheckExitCode $?

ciGetBackup
ciCheckExitCode $?

if ciVersionMajeurAvant "2.7.0"
then
    /usr/share/eole/sbin/bareosconfig.py -s manual
else
    /usr/share/eole/sbin/bareosconfig.py -s manual --no-reload
fi
/usr/share/eole/sbin/bareosconfig.py -d | grep ^Support

DIR_NAME=$(basename /mnt/sauvegardes/*catalog* | awk -F '-catalog' '{print $1}')

echo "******* EXTRACTION CONFIG EOL ***********"
if ciVersionMajeurAvant "2.6.0"
then
    ciSignalHack "Calculs Creole impossibles, je transforme les 'Err...' creole en 'War...' "
    /usr/share/eole/sbin/bareosrestore.py --catalog "$DIR_NAME" 2>&1 | sed "s/Erreur/Warning/g"
else
    /usr/share/eole/sbin/bareosrestore.py --configeol "$DIR_NAME"
fi
ciCheckExitCode $?

sleep 10
echo "******* zephir-restore.eol ***********"
cat /root/zephir-restore.eol

echo "******* copie zephir-restore.eol ***********"
mv /root/zephir-restore.eol /etc/eole/config.eol

echo "******* Check Proxy ***********"
ciSetHttpProxy

echo "******* INSTANCE ***********"
ciInstance
ciCheckExitCode $?

if ciVersionMajeurAvant "2.6.0"
then
    echo "******* PAS DE RESTAURATION DU CATALOGUE en version avant 2.6.0 ***********"
else
    echo "******* RESTAURATION DU CATALOGUE ***********"
    /usr/share/eole/sbin/bareosrestore.py --catalog
    ciCheckExitCode $?
fi
ls -l /var/lib/bareos/

echo "******* RESTAURATION COMPLETE ***********"
/usr/share/eole/sbin/bareosrestore.py --all
#ciCheckExitCode $? pas de test !

if [[ "$VM_MODULE" == "amonecole" ]]
then
    ciWaitBareos 1200
else
    ciWaitBareos
fi
ciCheckExitCode "$?" "Timeout log bareos"

echo "******* list jobs ***********"
echo "list jobs" | bconsole -c /etc/bareos/bconsole.conf >/tmp/list_jobs.txt
cat /tmp/list_jobs.txt

echo "******* COMPTE RENDU ***********"
if ciVersionMajeurAvant "2.6.0"
then
    BAREOS_DIR_LOG=bareos-dir.err.log
else
    BAREOS_DIR_LOG=bareos-dir.info.log
fi
if [ ! -f /var/log/bareos/restore.txt ]
then
    ciSignalWarning "* LE FICHIER '/var/log/bareos/restore.txt' MANQUE"
    #BAREOS_RESULT="1"
fi

if [[ "$VM_MODULE" == "scribe" ]] || [[ "$VM_MODULE" == "amonecole" ]] || [[ "$VM_MODULE" == "horus" ]] || [[ "$VM_MODULE" == "amonhorus" ]]
then
    if [ -f /home/backup/toto1.txt ]
    then
        echo "* OK: fichier /home/backup/toto1.txt présent"
        ls -l /home/backup/toto1.txt
    else
        ciSignalWarning "* NOK: fichier /home/backup/toto1.txt absent"
    fi

    if [ -f /home/a/toto1.txt ]
    then
        echo "* OK: fichier /home/a/toto1.txt présent"
        ls -l /home/a/toto1.txt
    else
        ciSignalWarning "* NOK: fichier /home/a/toto1.txt absent"
    fi

#    #32982
#    echo "test ldapsearch admin ?"
#    ldapsearch -x uid=admin loginShell | grep ^loginShell

    cat >/tmp/test_quota.py <<EOF
# -*- coding: utf-8 -*-
from fichier.quota import get_quota
q=get_quota('c31e1');
print('Quota attendu 50\nQuota trouvé  {}'.format(q));
try:
    assert q == 50
except:
    print('Erreur : La restauration des quotas ne fonctionne pas : {} au lieu de 50'.format(q))
EOF
    if ciVersionMajeurAPartirDe "2.8."
    then
        echo "test quota pour c31e1 python3 ?"
        python3 /tmp/test_quota.py
    else
        echo "test quota pour c31e1 python2 ?"
        python /tmp/test_quota.py
    fi

    echo "test la table testtable dans la base testsquash ?"
    ls "$(CreoleGet container_path_mysql)/var/lib/mysql/testsquash"
    if CreoleRun "echo 'show tables;' | mysql --defaults-file=/etc/mysql/debian.cnf testsquash" mysql | grep -q testtable
    then
        echo "OK : 'testtable' est retaurée"
    else
        ciSignalWarning "* NOK : 'testtable' non trouvée,  RESULT=1"
        BAREOS_RESULT="1"
    fi

    if ciVersionMajeurAPartirDe "2.7."
    then
        # shellcheck disable=SC1091
        . /var/lib/lxc/addc/rootfs/etc/eole/samba4-vars.conf
        if [ -f "/var/lib/lxc/addc/rootfs/home/sysvol/${AD_REALM}/scripts/groups/test.txt" ]
        then
            echo "* OK test.txt est dans SYSVOL"
        else
            ciSignalWarning "* NOK test.txt n''est pas dans SYSVOL,  RESULT=1"
            BAREOS_RESULT="1"
        fi
    else
        echo "* PAS d'injection de test.txt, car pas de SYSVOL sur les versions avant 2.7 !"
    fi

    if [ ! -d /var/lib/lxc/addc ]
    then
        if ciVersionMajeurAvant "2.6.1"
        then
            NB_ATTENDU=6
        else
            NB_ATTENDU=5
        fi
    elif [ ! -d /var/lib/lxc/reseau/ ]
    then
        # ScribeAD
        if [ "$VM_VERSIONMAJEUR" != "2.8.1" ]
        then
            # 2.9 : - ejabberd
            NB_ATTENDU=6
        else
            # 2.8.1 : + postgresql
            NB_ATTENDU=7
        fi
        echo "test du compte machine AD"
        lxc-attach -n addc samba-tool computer show BareosComputer
    else
        # AmonEcole
        if ciVersionMajeurAvant "2.9.0"
        then
            NB_ATTENDU=6
        else
            # 2.9 : - ejabberd
            NB_ATTENDU=5
        fi
        echo "test du compte machine AD"
        lxc-attach -n addc samba-tool computer show BareosComputer
    fi
else
    # Autre module
    if ciVersionMajeurAvant "2.8.1"
    then
        NB_ATTENDU=1
    else
        #Restore_postgresql ajouté en 2.8.1
        NB_ATTENDU=2
    fi
fi

if [[ "$VM_MODULE" == "seth" ]]
then
    # shellcheck disable=SC1091
    . /etc/eole/samba4-vars.conf
    if [ -f "/home/sysvol/${AD_REALM}/scripts/groups/test.txt" ]
    then
        echo "* OK test.txt est dans SYSVOL"
    else
        ciSignalWarning "* NOK test.txt n'est pas dans SYSVOL,  RESULT=1"
        BAREOS_RESULT="1"
    fi
fi

if [[ "$VM_MODULE" == "amon" ]] || [[ "$VM_MODULE" == "amonecole" ]]
then
    if ciVersionMajeurAPartirDe "2.8."
    then
        bash "$VM_DIR_EOLE_CI_TEST/tests/migration/check-domaines_noauth_user.sh" || BAREOS_RESULT="1"
    fi
fi

ls -l /var/log/rsyslog/local/bareos-dir/
if [ ! -f /var/log/rsyslog/local/bareos-dir/${BAREOS_DIR_LOG} ]
then
    ciSignalWarning "* LE FICHIER '/var/log/rsyslog/local/bareos-dir/${BAREOS_DIR_LOG}' MANQUE"
    #BAREOS_RESULT="1"
else
    echo "Vérification présence 'Restore OK' dans ${BAREOS_DIR_LOG} ?"
    grep "Restore OK" "/var/log/rsyslog/local/bareos-dir/${BAREOS_DIR_LOG}"
    NB=$(grep -c " Restore_" /tmp/list_jobs.txt)
    echo "Nb = $NB, NB_ATTENDU=$NB_ATTENDU"
    if [ "$NB" == "$NB_ATTENDU" ]
    then
        echo "Ok"
    else
        ciSignalWarning "NOK RESULT=1"
        BAREOS_RESULT="1"
    fi
fi

echo "Vérification présence 'Access denied' ?"
if grep "Access denied" "/var/log/rsyslog/local/bareos-dir/${BAREOS_DIR_LOG}"
then
    ciSignalWarning "NOK RESULT=1"
    BAREOS_RESULT="1"
else
    echo "OK"
fi

if [ "$BAREOS_RESULT" == "0" ]
then
    echo "******* RECONFIGURE ***********"
    ciMonitor reconfigure
    ciCheckExitCode $?
else
    echo "Erreur détectée ==> pas de reconfigure"
fi

echo "Exit : $BAREOS_RESULT"
exit $BAREOS_RESULT
