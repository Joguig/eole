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
keytool -delete -trustcacerts -keystore /etc/ssl/certs/java/cacerts -storepass changeit -noprompt -alias eole-ad -file /root/ca.pem 2>/dev/null
# attention JDK , pas JRE !
keytool -import -trustcacerts -keystore /etc/ssl/certs/java/cacerts -storepass changeit -noprompt -alias eole-ad -file /root/ca.pem
ciCheckExitCode "$?"
