#!/bin/bash

# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh NO_DISPLAY

if [ -f /usr/lib/eole/ihm.sh ]
then
    # shellcheck disable=SC1091,SC1090
    . /usr/lib/eole/ihm.sh
fi
if [ -f /usr/lib/eole/utils.sh ]
then
    # shellcheck disable=SC1091,SC1090
    . /usr/lib/eole/utils.sh
fi

if [ -f /etc/eole/release ]
then
    # shellcheck disable=SC1091,SC1090
    . /etc/eole/release
fi

#echo "Récupération des informations ..."
RepRpt="/tmp/GenRpt"
rm -fr $RepRpt 2> /dev/null
mkdir $RepRpt
mkdir $RepRpt/log
mkdir $RepRpt/eole
mkdir $RepRpt/system

# les fichiers texte
CONFIGEOL='/etc/eole/config.eol'
if [ -f $CONFIGEOL ]; then
    /bin/cp -f $CONFIGEOL $RepRpt/eole
else
    #echo "ATTENTION: le module n'est pas instancié"
    touch $RepRpt/eole/pas_de_config.eol
fi
pstree >> $RepRpt/system/pstree.txt 2>&1
lshw  >> $RepRpt/system/lshw.txt 2>&1
lsusb  >> $RepRpt/system/lsusb.txt 2>&1
lspci  >> $RepRpt/system/lspci.txt 2>&1
iptables -nvL > $RepRpt/system/iptables.txt 2>&1
iptables -nvL -t nat >> $RepRpt/system/iptables.txt 2>&1
grep -v "^#" /root/.bash_history > $RepRpt/system/history.txt
dpkg-query -W > $RepRpt/system/packages.txt 2>&1
dmesg > $RepRpt/log/dmesg.log 2>&1

for f in /etc/network/interfaces \
         /etc/resolv.conf \
         /etc/systemd/resolved.conf \
         /etc/netplan/01-netcfg.yaml \
         /etc/systemd/network/* \
         /var/log/apt/term.log \
         /var/log/creoled.log \
         /var/log/eole-ci-tests.log \
         /var/log/EoleCiTestsContext.log \
         /var/log/EoleCiTestsDaemon.log \
         /var/log/isolation.log \
         /var/log/ltsp_build_client.log \
         /var/log/ltsp_build_client-thin_amd64.log \
         /var/log/reconfigure.log \
         /var/log/rsyslog/local/creoled/creoled.info.log \
         /var/log/rsyslog/local/rsyslog \
         /var/log/rsyslog/local/su \
         /var/log/rsyslog/local/sudo \
         /var/log/rsyslog/local/kernel \
         /var/log/rsyslog/local/cron \
         /var/log/rsyslog/local/auth \
         /var/log/rsyslog/local/chpasswd \
         /var/log/rsyslog/local/exim \
         /var/log/samba/create_addc.log \
         /var/log/upgrade-auto.log \
         /tmp/Upgrade-Auto*
do
    if [ -L "${1}" ]
    then
        if [ -f "${1}" ]
        then
            cat "${1}" >"$DESTINATION/${1}"
        else
            echo "gen_rpt_test.sh: $1 est un dossier lien symbolique"
        fi
    else
        if [ -f "$f" ] 
        then
            /bin/cp -r "$f" $RepRpt/log/
        fi
        if [ -d "$f" ] 
        then
            /bin/cp -rf "$f" $RepRpt/log/
        fi
    fi
    
done

LIST_CONTENEUR="$(lxc-ls 2>/dev/null)"
for conteneur in $LIST_CONTENEUR
do
	mkdir "$RepRpt/log/${conteneur}/"
	
    f="/var/log/lxc/${conteneur}.log"
    if [ -f "$f" ] 
    then
        /bin/cp -rf "$f" $RepRpt/log/
    fi
    for f in /etc/network/interfaces /var/log/apt/term.log /var/log/ltsp_build_client-fat_amd64.log
    do
	    fInLxc="/var/lib/lxc/${conteneur}/rootfs${f}"
        if [ -f "${fInLxc}" ] 
        then
            /bin/cp -rf "${fInLxc}" "$RepRpt/log/${conteneur}/"
        fi
    done
done

/bin/cp -r /usr/share/eole/creole/dicos $RepRpt/eole/dicos
/bin/cp -r /usr/share/eole/creole/patch $RepRpt/eole/patch
/bin/cp -r /usr/share/zephir/monitor/stats $RepRpt/stats/

# spécifique Scribe
if [ -f /var/www/ead/extraction/tmp/rapport.txt ];then
   /bin/cp /var/www/ead/extraction/tmp/rapport.txt $RepRpt/log/extraction.log
fi
if [ -f /var/log/controle-vnc/main.log ];then
   /bin/cp /var/log/controle-vnc/main.log $RepRpt/log/controle-vnc.log
fi

# spécifique Scribe/Horus/Eclair
if [ -d /var/lib/eole/reports ];then
   /bin/cp -r /var/lib/eole/reports $RepRpt/log/sauvegarde/
fi

# spécifique Amon
if [ -f '/usr/share/eole/test-rvp' ];then
    /usr/sbin/ipsec status &> $RepRpt/ipsec.status 2>&1
fi

# Rapport debsums
if [ -x '/usr/share/eole/debsums/show-reports.py' ]; then
    /usr/share/eole/debsums/show-reports.py > ${RepRpt}/log/rapport-debsums.log 2>&1
fi

#echo "Log infra de test"
if command -v systemd-analyze >/dev/null 2>&1
then
    (LANG=C systemd-analyze critical-chain --fuzz 1h  | grep -ve '-\.\.\.' )>"$RepRpt/system/systemd-critical-chain.log"
    systemd-analyze blame >"$RepRpt/system/systemd-blame.log"
    journalctl --no-pager -xe >"$RepRpt/system/systemd-journalctl-xe.log"
    
    systemd-analyze dot >"$RepRpt/system/systemd-analyze.dot" 2>/dev/null
    if command -v dot >/dev/null 2>&1
    then
        dot -Tsvg "$RepRpt/system/systemd-analyze.dot" >"$RepRpt/system/systemd-analyze-dot.svg" 2>/dev/null
    fi
    systemd-analyze plot >"$RepRpt/system/systemd-analyze-plot.svg" 2>"$RepRpt/system/systemd-analyze-plot.log"
    (LANG=C systemd-analyze critical-chain --fuzz 1h  | grep -ve '-\.\.\.' )>"$RepRpt/system/systemd-critical-chain.log"
fi

if command -v initctl2dot >/dev/null 2>&1
then
    /bin/cp -r /var/log/upstart/EoleCiTestsContext.log "$RepRpt/log/EoleCiTestsContextUpstart.log"
    /bin/cp -r /var/log/upstart/EoleCiTestsDaemon.log "$RepRpt/log/EoleCiTestsDaemonUpstart.log"
    initctl2dot -o - >"$RepRpt/system/initctl2dot-upstart.dot"
fi

/usr/bin/diagnose -LT >> $RepRpt/diagnose.txt 2>&1

#echo "Création de l'archive locale"
tar -C /tmp -czf "${VM_MODULE}-${VM_ID}.tar.gz" GenRpt
