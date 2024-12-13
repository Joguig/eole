#!/bin/bash
# shellcheck disable=SC2034,SC2148

# code executer sur l'image à publier
APPLIANCE_VERSION="$1"

# shellcheck disable=1091
source /root/getVMContext.sh

echo "* vérification ping !"
ciGetNamesInterfaces
ciDiagnoseNetwork
ciPingHost 192.168.0.1 "$VM_INTERFACE0_NAME"
ciCheckExitCode $? "RESULT_PING=$RESULT_PING, WARNING ADRESS IN USE, Stop !"

echo "* vérification résolution dns !"
ciTestHttp
ciCheckExitCode $? "$0 : ciTestHttp"

echo "* remove kernel sauf courant !"
bash remove-kernel.sh yes
ciCheckExitCode $? "$0 : remove kernel"

ciPrintMsg "* apt-get -y --purge autoremove"
apt-get -y --purge autoremove
ciCheckExitCode $? "$0 : autoremove"

echo "* clean cache"
/bin/rm -rf /var/cache/apt/* /var/log/apt/history* /var/lib/apt/lists

echo "* fstrim"
fstrim --all

# ATTENTION : ne pas afficher le mdp sur la console (build jenkins publique !)
set +x +o history

echo "* random password eole"
RANDOM_PWD="$(pwgen 14 1 -n 2 -c 2 -y -r \"$/\&\\\")"
echo -e "$RANDOM_PWD\n$RANDOM_PWD" | passwd eole

echo "* random password root"
RANDOM_PWD_ROOT="$(pwgen 14 1 -n 2 -c 2 -y -r \"$/\&\\\")"
echo -e "$RANDOM_PWD_ROOT\n$RANDOM_PWD_ROOT" | passwd root

cat >/etc/issue <<EOF
EOLE ${VM_VERSIONMAJEUR} \l
Appliance : ${APPLIANCE_VERSION} 
Mot de passe par défaut de l'utilisateur root : ${RANDOM_PWD_ROOT}
EOF

echo "* supprime 'minlen=4' de /etc/pam.d/common-password "
sed -i -e 's/minlen=4 //' /etc/pam.d/common-password

function StatDu()
{
    echo "* stat du $1"
    du "$1" -b -P --max-depth=1 --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/mnt 2>/dev/null |sort -n |awk '$1>500000 {print $1,$2;}' 2>/dev/null
}
StatDu / 
StatDu /var/lib 
StatDu /usr/lib 
 
echo "* Nettoyage final"
if [ -f /etc/systemd/system/fstrim.service ]
then
	systemctl stop fstrim.service
    rm -f /etc/systemd/system/fstrim.service	
fi
if [ -f /etc/systemd/system/EoleCiTestsContext.service ]
then
	systemctl stop EoleCiTestsContext.service
    rm -f /etc/systemd/system/EoleCiTestsContext.service	
fi
if [ -f /etc/systemd/system/EoleCiTestsDaemon.service ]
then
    # en cours : si on l'arrete, le process es tué !
    #systemctl stop EoleCiTestsDaemon.service
    rm -f /etc/systemd/system/EoleCiTestsDaemon.service
fi
systemctl daemon-reload

/bin/rm -f /root/mount.eole-ci-tests \
           /root/getVMContext.sh \
           /root/.eole-ci-tests.context \
           /root/.eole-ci-tests.freshinstall \
           /root/EoleCiFunctions.sh \
           /root/.EoleCiTestsDaemon.sh \
           /root/.EoleCiTestsContext.sh \
           /etc/netplan/01-netcfg.yaml

echo "Test contextualisation ONE"
bash /mnt/eole-ci-tests/scripts/one-context.d/vmcontext-gg.sh
echo "context ==> $?"

exit 0
