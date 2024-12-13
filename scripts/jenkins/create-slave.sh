#!/bin/bash
SLAVE="${1:-jenkins2}"
echo $SLAVE
useradd $SLAVE -d /home/$SLAVE -m -s /bin/bash
printf "eole\neole" | passwd $SLAVE

if [ -f /home/$SLAVE/.ssh/id_rsa ]
then
    echo "cle existante"
else
	su - $SLAVE <<EOF
ssh-keygen -b 2048 -t rsa -f /home/$SLAVE/.ssh/id_rsa -q -N ""
EOF
fi
ls -l /home/$SLAVE/.ssh/id_rsa*

if [ ! -d /home/$SLAVE/.one ]
then
   mkdir /home/$SLAVE/.one
   cp /var/lib/jenkins/userContent/one/one_auth.gw-$SLAVE /home/$SLAVE/.one/one_auth
   chown -R $SLAVE:$SLAVE /home/$SLAVE/.one
fi
ls -l /home/$SLAVE/.one

mkdir -p /mnt/eole-ci-tests/security/jenkins_keys
sudo cp -v /home/$SLAVE/.ssh/id_rsa.pub /mnt/eole-ci-tests/security/jenkins_keys/$SLAVE.pub
