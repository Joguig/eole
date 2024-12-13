#!/bin/bash

# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh NO_DISPLAY

echo "******* Def JAVA_OPTS ***********"
#export JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStore=/etc/lsc/cacerts -Djavax.net.ssl.trustStorePassword=changeit"

echo "******* get CA seth/samba ***********"
VM_OUTPUT=$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER
export VM_OUTPUT
/bin/cp -f "$VM_OUTPUT/seth1_ca.pem" /root/ca.pem
ciCheckExitCode "$?"

echo "******* create cacert ***********"

"/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/keytool" -delete -trustcacerts -keystore /etc/ssl/certs/java/cacerts -storepass changeit -noprompt -alias eole-ad -file /root/ca.pem
#ignore exit si pas présent

"/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/keytool" -import -trustcacerts -keystore /etc/ssl/certs/java/cacerts -storepass changeit -noprompt -alias eole-ad -file /root/ca.pem
ciCheckExitCode "$?"

sed -i -e 's#<logger name="org.lsc" level="INFO">#<logger name="org.lsc" level="DEBUG">#' /etc/lsc/logback.xml

echo "******* ciInstance ***********"
ciConfigurationEole instance eolead
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
printf "Eole12345!\n" | ldapsearch -H ldap://seth1.etb1.lan -x -UAdministrator 
smbldap-userlist -u
