#!/bin/bash

if ! command -v wget >/dev/null 2>/dev/null
then
	apt-get install -y wget
fi
if ! command -v git >/dev/null 2>/dev/null
then
	apt-get install -y git
fi
if ! command -v make >/dev/null 2>/dev/null
then
	apt-get install -y make
fi
if ! command -v pip >/dev/null 2>/dev/null
then
	apt-get install -y python-pip
fi
#pip install --upgrade pip
pip install wheel

if [ ! -d /usr/lib/python2.7/dist-packages/yaml ]
then
	apt install -y python-yaml
fi

if [ ! -f /usr/lib/python2.7/dist-packages/pip/utils/setuptools_build.py ]
then
	pip install setuptools
fi

pip install --upgrade pyOpenSSL

if ! command -v docker >/dev/null 2>/dev/null
then
	wget -qO- https://get.docker.com/ | sh
	#usermod -aG docker arun
	systemctl start docker
fi

if ! command -v docker-compose >/dev/null 2>/dev/null
then
	pip install docker-compose
fi

if [ ! -d /etc/systemd/system/docker.service.d ]
then
	mkdir -p /etc/systemd/system/docker.service.d
    cat >/etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375 --dns 192.168.0.1 --dns 192.168.232.2
EOF
   systemctl daemon-reload
fi
apt-get install -y bridge-utils

if [ ! -f /root/check-config.sh ]
then
    curl https://raw.githubusercontent.com/docker/docker/master/contrib/check-config.sh >/root/check-config.sh
fi
bash /root/check-config.sh

