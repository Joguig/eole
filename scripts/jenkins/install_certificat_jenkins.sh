#!/bin/bash -x

JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
JENKINS_HOME=/var/lib/jenkins

CUSTOM_KEYSTORE=$JENKINS_HOME/.keystore/
od <$CUSTOM_KEYSTORE/cacerts.passwd
mkdir -p $CUSTOM_KEYSTORE
cp $JAVA_HOME/jre/lib/security/cacerts $CUSTOM_KEYSTORE

HOST_TO_IMPORT=repo.maven.apache.org
keytool -printcert -rfc -sslServer ${HOST_TO_IMPORT}:443 >$CUSTOM_KEYSTORE/${HOST_TO_IMPORT}.crt
$JAVA_HOME/bin/keytool -keystore $JENKINS_HOME/.keystore/cacerts -noprompt -import -alias ${HOST_TO_IMPORT} -file $CUSTOM_KEYSTORE/${HOST_TO_IMPORT}.crt -trustcacerts -storepass changeit  
#$JAVA_HOME/bin/keytool -v -keystore $JENKINS_HOME/.keystore/cacerts -list -storepass changeit

if grep -q trustStorePassword /etc/default/jenkins
then
    sudo sed -i 's!^JAVA_ARGS=.*!JAVA_ARGS="-Djava.awt.headless=true -Xmx1536m -Xms128m -Djava.net.preferIPv4Stack=true -Djenkins.CLI.disabled=true -Djavax.net.ssl.trustStore=$JENKINS_HOME/.keystore/cacerts -Djavax.net.ssl.trustStorePassword=changeit"!' /etc/default/jenkins
    cat /etc/default/jenkins 
fi