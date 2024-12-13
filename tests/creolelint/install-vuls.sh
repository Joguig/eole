#!/bin/bash

VULS_USER='vuls'
FROM_DATE='2017'

apt-get update
apt-get upgrade -y

echo "* Utilisation d'une debian Stretch ( golang >=1.7.1)"
apt-get install -y sqlite git gcc golang make libc6-dev

echo "* Création d'un utilisateur système vuls"
adduser --system --shell /bin/bash ${VULS_USER}

echo "* Export des variables d'environement"
if ! grep GOROOT /etc/profile > /dev/null ;
then
    cat >> /etc/profile << EOF
export GOROOT=/usr/lib/go
export GOPATH=\$HOME/go
export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin
EOF
fi

echo "* Création du répertoire pour les logs"
mkdir /var/log/vuls
chown -R ${VULS_USER}: /var/log/vuls

echo "* Installation de go-cve-dictionary"
cat > /tmp/install_go-cve-dictionary.sh << EOF
mkdir -p \$GOPATH/src/github.com/kotakanbe
cd \$GOPATH/src/github.com/kotakanbe
git clone https://github.com/kotakanbe/go-cve-dictionary.git
cd go-cve-dictionary
make install
EOF
chmod +x /tmp/install_go-cve-dictionary.sh
su - ${VULS_USER} -c /tmp/install_go-cve-dictionary.sh
rm /tmp/install_go-cve-dictionary.sh

echo "* Récupérer la base des CVE depuis : $FROM_DATE"
for i in $(seq "$FROM_DATE" "$(date +"%Y")" );
do 
    su - ${VULS_USER} -c "go-cve-dictionary fetchnvd -years $i"
done

echo "* Installation de vuls"
cat > /tmp/install_vuls.sh << EOF
mkdir -p \$GOPATH/src/github.com/future-architect
cd \$GOPATH/src/github.com/future-architect
git clone https://github.com/future-architect/vuls.git
cd vuls
make install
EOF

chmod +x /tmp/install_vuls.sh
su - ${VULS_USER} -c /tmp/install_vuls.sh
rm /tmp/install_vuls.sh
