#!/bin/bash

if ! command -v wget >/dev/null 2>/dev/null
then
    apt-get install -y wget
fi
if ! command -v curl >/dev/null 2>/dev/null
then
    apt-get install -y curl
fi
if ! command -v attr >/dev/null 2>/dev/null
then
    apt-get install -y attr
fi
if ! command -v getfacl >/dev/null 2>/dev/null
then
    apt-get install -y acl
fi

# ref. : https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

if ! command -v docker >/dev/null 2>/dev/null
then
    apt-get update
	echo "* --------------------------------------------------"
	echo "* Supression DOCKER"
    apt-get remove -y docker docker-engine docker-ce docker-ce-cli containerd containerd.io runc
    apt-get autoremove -y
    rm -rf /var/lib/docker

	echo "* --------------------------------------------------"
	echo "* préparation DOCKER"
    apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
   	apt-key fingerprint 0EBFCD88

	echo "* --------------------------------------------------"
	echo "* repo DOCKER"
   	add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
   	apt-get update
   	apt-cache madison docker-ce
    
    echo "* --------------------------------------------------"
	echo "* install DOCKER"
	apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose
    systemctl unmask docker
    systemctl enable docker
fi

echo "* --------------------------------------------------"
echo "* docker --version"
docker --version

if [ ! -d /etc/systemd/system/docker.service.d ]
then
    mkdir -p /etc/systemd/system/docker.service.d
    cat >/etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
# efface l'ancienne valeur!
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375 --dns 192.168.0.1 --dns 192.168.232.2
EOF
   systemctl daemon-reload
   systemctl restart docker
fi

echo "* --------------------------------------------------"
echo "* check-config.sh"
curl https://raw.githubusercontent.com/docker/docker/master/contrib/check-config.sh >/root/check-config.sh
if [ -f /root/check-config.sh ]
then
	bash /root/check-config.sh
fi

echo "* --------------------------------------------------"
echo "* journalctl -xe -u docker --no-pager --boot"
journalctl -xe -u docker --no-pager --boot

echo "* --------------------------------------------------"
echo "* Test 'hello-world'"
docker run -it hello-world

echo "* --------------------------------------------------"
echo "* install docker plugin viewu/sshfs"
if [ ! -d /var/lib/docker/plugins ]
then
    mkdir -p /var/lib/docker/plugins
fi
docker plugin install --grant-all-permissions vieux/sshfs
docker volume create -d vieux/sshfs -o sshcmd=root@localhost:/mnt/eole-ci-tests -o password=eole mnt-eole-ci-tests
docker run -it -v mnt-eole-ci-tests:/mnt/eole-ci-tests ubuntu sh -c 'ls -l /mnt/eole-ci-tests'

echo "* --------------------------------------------------"
