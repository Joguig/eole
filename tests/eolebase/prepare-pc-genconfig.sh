#!/bin/bash
echo "$0 : Début"

echo "* ip addr"
ip addr

#ciAfficheProcess

#ciDiagnoseNetwork

export DEBIAN_FRONTEND=noninteractive
apt-get update

echo "* bash install-tools-nodejs.sh"
bash install-tools-nodejs.sh

echo "* clone-eole-genconfig-tests.sh"
cd /home/pcadmin/Bureau || exit 1
if [ ! -d eole-genconfig-tests ] 
then
    git clone https://dev-eole.ac-dijon.fr/git/eole-genconfig-tests.git
    cd /home/pcadmin/Bureau/eole-genconfig-tests || exit 1
else
    cd /home/pcadmin/Bureau/eole-genconfig-tests || exit 1
    git pull
fi

echo "* clone-ewt-tests.sh"
cd /home/pcadmin/Bureau || exit 1
if [ ! -d ewt-tests ] 
then
    git clone https://dev-eole.ac-dijon.fr/git/ewt-tests.git
    cd /home/pcadmin/Bureau/ewt-tests || exit 1
else
    cd /home/pcadmin/Bureau/ewt-tests || exit 1
    git pull
fi


cd /home/pcadmin/Bureau/eole-genconfig-tests || exit 1
PATH="/home/pcadmin/Bureau/eole-genconfig-tests/node_modules/.bin/:$PATH"
export PATH 

echo "* install 'nightmare'"
npm install nightmare --save-dev --unsafe-perm=true --allow-root

echo "* install 'electron'"
npm install electron --save-dev --unsafe-perm=true --allow-root
./node_modules/.bin/electron -v --no-sandbox
electron -v --no-sandbox

echo "* install libgconf-2-4 pour electron (obligatoire, sinon electron bug au démarrage !)"
apt-get install -y libgconf-2-4

echo "* Install dépendance eole-genconfig-tests"
cd /home/pcadmin/Bureau/eole-genconfig-tests || exit 1
npm install --save-dev --unsafe-perm=true --allow-root
ciCheckExitCode "$?"

echo "* Vérification JS known vulnerabilities "
npm audit
#ciCheckExitCode "$?"

echo "* Install dépendance ewt-tests"
cd /home/pcadmin/Bureau/ewt-tests || exit 1
npm install --save-dev --unsafe-perm=true --allow-root
ciCheckExitCode "$?"

echo "* Vérification JS known vulnerabilities "
npm audit
#ciCheckExitCode "$?"

echo "* install Xvfb"
apt-get install -y xvfb
ciCheckExitCode "$?"

exit 0
