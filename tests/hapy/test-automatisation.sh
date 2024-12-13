#!/bin/bash

MY_ABSOLUTEPATH=$(realpath "$0")
MY_PARENT_PATH=$(dirname "$MY_ABSOLUTEPATH")

CONFIGURATION=autodeploy
export CONFIGURATION

echo "* Vérifie install paquet eole-hapy-deployment "
ciAptEole eole-hapy-deployment
ciCheckExitCode $? "$0 : install eole-hapy-deployment"

"$MY_PARENT_PATH/inject-automatisation.sh"
ciCheckExitCode $? "$0 : injection"

ciGetConfigurationFromZephir
ciCheckExitCode $? "$0 : ciGetConfigurationFromZephir"

# obligatoire car enregistrement zephir repositionnne les sources list !
ciMajAutoSansTest
ciCheckExitCode $? "$0 : ciMajAutoSansTest"

echo "* CreoleSet activer_deploiement_automatique oui"
CreoleSet activer_deploiement_automatique oui

echo "* CreoleSet zephir_ca_file = zephir.ac-test.fr-ca.crt"
CreoleSet zephir_ca_file "/usr/local/share/ca-certificates/zephir.ac-test.fr-ca.crt"

echo "* Affichage variable"
echo "* activer_deploiement_automatique : $(CreoleGet activer_deploiement_automatique)"
#
#echo "* zephir_numero_etab : $(CreoleGet zephir_numero_etab)"   zephir_numero_etab pas dispo avec mode 'liste'
echo "* zephir_ca : $(CreoleGet zephir_ca)"
echo "* zephir_ca_file : $(CreoleGet zephir_ca_file)"
echo "* dp_mode : $(CreoleGet dp_mode)"  # site", "liste manuelle", "mixte

echo "* Get Id Zephir etb1.amon ${VM_VERSIONMAJEUR} default"
ID_AMON=$(VM_MACHINE=etb1.amon CONFIGURATION=default ciGetIdZephir)
echo "* id amon = $ID_AMON"

echo "* Get Id Zephir etb1.scribe ${VM_VERSIONMAJEUR} default"
ID_SCRIBE=$(VM_MACHINE=etb1.scribe CONFIGURATION=default ciGetIdZephir)
echo "* id scribe = $ID_SCRIBE"

echo "* Positionne mode=liste manuelle + les 2 ID dans le bon ordre"
ciRunPython CreoleSet_Multi.py <<EOF
set dp_mode "liste manuelle"
set dp_server_id_list 0 "$ID_AMON"
set dp_server_id_list 1 "$ID_SCRIBE"
EOF
ciCheckExitCode $? "creolset"

echo "* prépare espace Disk pour 2 VM"
ciExtendsLvmWithDisk100G "var+lib+one" "90G"
df -h

/bin/rm "$HOME/A" 2>/dev/null
touch "$HOME/A"

echo "* test acces http://eole.orion.education.fr/maj/blacklists"
ciTestHttp http://eole.orion.education.fr/maj/blacklists

echo "* refait instance pour le déploiement"
VM_TIMEOUT=4000 ciMonitor instance

# ne pas arreter ici, pour avoir les logs !!
#ciCheckExitCode "$?" "instance"

echo "* diagnose"
ciDiagnose

echo "* ls -l /var/log/hapy-deploy"
ls -l /var/log/hapy-deploy

echo "* export /usr/share/eole/hapy-deploy/.hapy-deploy.status"
if [ -f /usr/share/eole/hapy-deploy/.hapy-deploy.status ]
then
    ciAfficheContenuFichier /usr/share/eole/hapy-deploy/.hapy-deploy.status
    cp -vf /usr/share/eole/hapy-deploy/.hapy-deploy.status "/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/hapy-deploy.status.txt"
    echo "EOLE_CI_PATH hapy-deploy.status.txt"
else
    echo "ERREUR: /usr/share/eole/hapy-deploy/.hapy-deploy.status manque"
fi

echo "* export /var/log/hapy-deploy*.log"
find /var/log -name 'hapy-deploy*.log' |while read -r F
do
   NOM="$(basename "$F")"
   cp -vf "$F" "/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/"
   echo "EOLE_CI_PATH $NOM"
done

echo "* Affichage Situation ONE"

echo "* -----------------------------------------------------------"
echo "* onevm list"
onevm list 

echo "* -----------------------------------------------------------"
echo "* oneimage list"
oneimage list

echo "* -----------------------------------------------------------"
echo "* onetemplate  list"
onetemplate list


echo ""
echo "Affichage Templates"
echo "* -----------------------------------------------------------"
echo "* onetemplate show 3"
onetemplate show 3 >"/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/onetemplate_show_3.log"
echo "EOLE_CI_PATH onetemplate_show_3.log"

echo "* -----------------------------------------------------------"
echo "* onetemplate show 2"
onetemplate show 2 >"/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/onetemplate_show_2.log"
echo "EOLE_CI_PATH onetemplate_show_2.log"

echo "Affichage VMs"
bash export-status-vm.sh "amon.etb1.lan"

bash export-status-vm.sh "scribe.dompedago.etb1.lan"

RepRpt="/tmp/GenRpt"
rm -fr "$RepRpt" 2> /dev/null
mkdir "$RepRpt"
pushd "$RepRpt" || exit 1
for f in /usr/share/eole/hapy-deploy/ \
         /var/lib/one/vms/ \
         /var/log/libvirt/qemu/ \
         /var/log/one/ \
         /var/log/nginx/ \
         /var/log/rsyslog/local/libvirtd/ \
         /var/log/rsyslog/local/ruby/ \
         /var/log/rsyslog/local/ovs-ctl/ \
         /var/log/rsyslog/local/onevm-all/ \
         /var/log/rsyslog/local/postservice.opennebula.network/ \
         /var/log/rsyslog/local/ovs-vsctl/ \
         /var/log/hapy-deploy/ \
         /var/log/openvswitch/
do
    if [ -f "$f" ] 
    then
        /bin/cp -r "$f" "$RepRpt/"
    fi
    if [ -d "$f" ] 
    then
        /bin/cp -rf "$f" "$RepRpt/"
    fi
done

TARGZ="${VM_MODULE}-${VM_ID}.tar.gz"
echo "Création de l'archive ${TARGZ}"
tar -czf "/tmp/${TARGZ}" -C "$RepRpt" .
echo "cp -vf /tmp/${TARGZ} /mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/"
cp -f "/tmp/${TARGZ}" "/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/"
echo "EOLE_CI_PATH ${TARGZ}"
popd || exit 1
