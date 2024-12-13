#!/bin/bash -x
. /etc/default/jenkins
#echo "PREFIX=$PREFIX"
#echo "HTTP_PORT=$HTTP_PORT"
#echo "JAVA_ARGS=$JAVA_ARGS"
#echo "JAVA_HOME=$JAVA_HOME"

#!/bin/bash
TOKEN='jenkins-user-token'
USER=''
SERVER="http://your.server.address"

#jenkins job parameters
PARAMF=$1
SECONDPARAM=$2

# retrieve the crumb that we need to pass in the header
CRUMBS=$(curl -s -X GET -u $USER:$TOKEN ${SERVER}/crumbIssuer/api/json  | jq -c '. | .crumb ')
curl --user $USER:$TOKEN  -H "Jenkins-Crumb:${CRUMBS}" -X POST  "${SERVER}/view/MyView/job/JobName/buildWithParameters?TOKEN=${TOKEN}&PARAMETERONE=${PARAMF}&PARAMETERTWO=${SECONDPARAM}"


JENKINS_HOST="jenkins.eole.lan"
#JENKINS_URL=http://${JENKINS_HOST}:${HTTP_PORT}/jenkins
JENKINS_URL=http://jenkins.eole.lan:22222

# get the SSL certificate
#KEYSTOREFILE=myKeystore
#KEYSTOREPASS=changeme
#openssl s_client -connect ${JENKINS_HOST}:${HTTP_PORT} </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ${JENKINS_HOST}.cer
# create a keystore and import certificate
#keytool -import -noprompt -trustcacerts -alias ${JENKINS_HOST} -file ${JENKINS_HOST}.cer -keystore ${KEYSTOREFILE} -storepass ${KEYSTOREPASS}
# verify that the certificate is listed
#keytool -list -v -keystore ${KEYSTOREFILE} -storepass ${KEYSTOREPASS}

# get jenkins-cli
if [ ! -f "$JENKINS_HOME"/jenkins-cli.jar ]
then
    wget --no-check-certificate ${JENKINS_URL}/jnlpJars/jenkins-cli.jar -O "$JENKINS_HOME"/jenkins-cli.jar
fi
# test access
#alias jcli="java -Djavax.net.ssl.trustStore=${KEYSTOREFILE} -Djavax.net.ssl.trustStorePassword=${KEYSTOREPASS} -jar jenkins-cli.jar -s ${JENKINS_URL,,}"
# ... or set this in your ~/.bashrc
#export JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStore=${KEYSTOREFILE} -Djavax.net.ssl.trustStorePassword=${KEYSTOREPASS}"
"${JAVA_HOME}/bin/java" -jar "$JENKINS_HOME"/jenkins-cli.jar -s "${JENKINS_URL}" "$@" 
