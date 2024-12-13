#!/bin/bash

# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh NO_DISPLAY

if ciVersionMajeurApres "2.7.1"
then
    OPT_KERBEROS=""
else
    OPT_KERBEROS=("-k 1")
fi
echo "OPT_KERBEROS=${OPT_KERBEROS[*]}"

echo "******* Def JAVA_OPTS ***********"
#export JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStore=/etc/lsc/cacerts -Djavax.net.ssl.trustStorePassword=changeit"

echo "******* get CA seth/samba ***********"
VM_OUTPUT=$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER
export VM_OUTPUT
/bin/cp -f "$VM_OUTPUT/seth1_ca.pem" /root/ca.pem
ciCheckExitCode "$?"

echo "******* apt-eole install eole-ad ***********"
apt-eole install eole-ad
ciCheckExitCode $?

ciSignalHack "bascule en DEV !"
ciMonitor maj_auto_dev
ciCheckExitCode $?

#Services
#    Activer l'intégration à un domaine Active Directory : oui
#    ad_activer_ad oui
#Active directory
#    ad_server dc1
#    ad_domain domseth.ac-test.fr
#    ad_address 192.168.0.5
#    ad_rescue (vide)
#    ad_user Administrator
#    ad_container CN=Users

if ! grep ad_address /etc/eole/config.eol
then
    sed -i -e 's#}$#,"ad_address":{"owner":"gen_config","val":"192.168.0.5"},"ad_ldaps":{"owner":"gen_config","val":"oui"},"ad_server":{"owner":"gen_config","val":"dc1"},"ad_domain":{"owner":"gen_config","val":"domseth.ac-test.fr"},"ad_user":{"owner":"gen_config","val":"Administrator"}}#' /etc/eole/config.eol
fi
CreoleGet ad_address
CreoleGet ad_server
CreoleGet ad_ldaps
CreoleGet ad_user

echo "******* create cacert ***********"

"/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/keytool" -delete -trustcacerts -keystore /etc/ssl/certs/java/cacerts -storepass changeit -noprompt -alias eole-ad -file /root/ca.pem
#ignore exit si pas présent

"/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/keytool" -import -trustcacerts -keystore /etc/ssl/certs/java/cacerts -storepass changeit -noprompt -alias eole-ad -file /root/ca.pem
ciCheckExitCode "$?"

sed -i -e 's#<logger name="org.lsc" level="INFO">#<logger name="org.lsc" level="DEBUG">#' /etc/lsc/logback.xml
 
echo "******* ciInstance ***********"
ciInstance
ciCheckExitCode $?

echo "******* config lxc.xml ***********"
cat /etc/lsc/lsc.xml
#sed -i -e "s#ldap://seth1.etb1.lan#ldaps://seth1.etb1.lan:636#" /etc/lsc/lsc.xml
#grep url /etc/lsc/lsc.xml

#echo "******* modification prof1 ***********"
#ciAccountProfile prof1 prof1

#echo "******* synchronisation comptes ***********"
#lsc -f /etc/lsc -s all -t1
#echo $?

#ldbsearch -H /var/lib/samba/private/sam.ldb -S '(objectclass=user)' cn | grep ^cn:
#ldbsearch -H ldap://seth1.etb1.lan -S '(objectclass=user)' cn
#kinit Administrator@ETB1.LAN
printf "Eole12345!\n" | ldapsearch -H ldap://seth1.etb1.lan -x -UAdministrator "${OPT_KERBEROS[*]}"
smbldap-userlist -u
