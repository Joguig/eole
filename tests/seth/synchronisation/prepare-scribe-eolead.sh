#!/bin/bash

CONFIGURATION="$1"
echo "CONFIGURATION=$CONFIGURATION"
MODE="$2"

# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh NO_DISPLAY

echo "******* Def JAVA_OPTS ***********"
#export JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStore=/etc/lsc/cacerts -Djavax.net.ssl.trustStorePassword=changeit"

echo "******* get CA seth/samba ***********"
VM_OUTPUT=$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER
export VM_OUTPUT
/bin/cp -f "$VM_OUTPUT/seth1_ca.pem" /root/ca.pem
ciCheckExitCode "$?"

echo "******* ciCopieConfigEol eolead ***********"
ciCopieConfigEol

ciMajAutoSansTest
echo "******* apt-eole install eole-ad ***********"
apt-eole install eole-ad
ciCheckExitCode $?

echo "******* create cacert ***********"
if [ "$MODE" = "restaurationSh" ];then
    ciSignalHack "Test Eole-AD : pas de restauration du certificat Seth avant instance"
else
    # attention JDK , pas JRE !
    keytool -import -trustcacerts -keystore /etc/ssl/certs/java/cacerts -storepass changeit -noprompt -alias eole-ad -file /root/ca.pem
    ciCheckExitCode "$?"
fi

echo "******* ciInstance ***********"
ciInstance
ciCheckExitCode $?

if [ "$MODE" = "sauvegardeSh" ];then
    /usr/share/eole/backend/creation-groupe.py -g "3eme" -t "Niveau"
    /usr/share/eole/backend/creation-groupe.py -g "3a" -t "Classe" -n "3eme"
    /usr/share/eole/backend/creation-eleve.py -u "3a.01" -c "3a" -m "Eole12345!" -p "Eleve" -f "3a" -d "01/01/1970" -o 111 -x 1
elif [ "$MODE" != "restaurationSh" ];then
    login='enseignant1'
    home="/home/${login:0:1}/$login"
    if [ ! -d "$home" ];then
        # image sans import
        echo "* Création de l'utilisateur $login"
        /usr/share/eole/backend/creation-prof.py -u"$login" -m"Eole12345!" -p"Prénom" -f"$login"
        ciCheckExitCode "$?"
    fi
fi

#Général
#    Nom du domaine Samba (ex: mondomaine) : etb1
#    smb_netbios_name etb1
#Services
#    Activer l'intégration à un domaine Active Directory : oui
#    ad_activer_ad oui

#Active directory
#    ad_server seth1
#    ad_domain etb1.lan
#    ad_address 10.1.3.6
#    ad_rescue (vide)
#    ad_user Administrator
#    ad_container CN=Users


#echo "******* config lxc.xml ***********"
#cat /etc/lsc/lsc.xml
#sed -i -e "s#ldap://seth1.etb1.lan#ldaps://seth1.etb1.lan:636#" /etc/lsc/lsc.xml
#grep url /etc/lsc/lsc.xml

#echo "******* modification prof1 ***********"
#ciAccountProfile prof1 prof1

#echo "******* synchronisation comptes ***********"
#lsc -f /etc/lsc -s all -t1
#echo $?

echo "* Affichage des utilisateurs"
getent passwd
