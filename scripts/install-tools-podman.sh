#!/bin/bash

if ! command -v wget >/dev/null 2>/dev/null
then
    apt-get install -y wget
fi
if ! command -v curl >/dev/null 2>/dev/null
then
    apt-get install -y curl
fi
if ! command -v gpg >/dev/null 2>/dev/null
then
    apt-get install -y gnupg2
fi

# ref. : https://www.atlantic.net/dedicated-server-hosting/how-to-install-and-use-podman-on-ubuntu-20-04/
# shellcheck disable=SC1091
source /etc/os-release

if ! command -v podman >/dev/null 2>/dev/null
then
    echo "* --------------------------------------------------"
    echo "* préparation PODMAN"
    apt-get install -y apt-transport-https ca-certificates gnupg-agent software-properties-common
    
    wget -nv "https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key" -O- | apt-key add -

    echo "* --------------------------------------------------"
    echo "* repo PODMAN"
    add-apt-repository "deb [arch=amd64] http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /"
    apt-get update -qq -y 
    
    echo "* --------------------------------------------------"
    echo "* install PODMAN"
    apt-get -qq --yes install podman
    
    #systemctl unmask docker
    #systemctl enable docker
fi

echo "* --------------------------------------------------"
echo "* podman --version"
podman --version

echo "* --------------------------------------------------"
echo "* configure registry"
if ! grep hub.eole.education /etc/containers/registries.conf
then
    # a la fin !
    cat >>/etc/containers/registries.conf <<EOF
#[registries.insecure]
#registries = [ 'hub.eole.education:5000']
# If you need to block pull access from a registry, uncomment the section below
# and add the registries fully-qualified name.
# Docker only
#[registries.block]
#registries = [ ]
EOF

    cat /etc/containers/registries.conf
fi

if [ ! -d /opt/cni/bin ]
then
    curl -L -o cni-plugins.tgz https://github.com/containernetworking/plugins/releases/download/v0.8.1/cni-plugins-linux-amd64-v0.8.1.tgz
    mkdir -p /opt/cni/bin
    tar -C /opt/cni/bin -xzf cni-plugins.tgz
fi

#if [ ! -d /etc/systemd/system/docker.service.d ]
#then
#    mkdir -p /etc/systemd/system/docker.service.d
#   cat >/etc/systemd/system/docker.service.d/override.conf <<EOF
#[Service]
# efface l'ancienne valeur!
#ExecStart=
#ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375 --dns 192.168.0.1 --dns 192.168.232.2
#EOF
#  systemctl daemon-reload
#   systemctl restart docker
#fi
#
#echo "* --------------------------------------------------"
#echo "* journalctl -xe -u docker --no-pager --boot"
#journalctl -xe -u docker --no-pager --boot

echo "* --------------------------------------------------"
echo "* cat /etc/containers/registries.conf.d/000-shortnames.conf "
cat /etc/containers/registries.conf.d/000-shortnames.conf

echo "* --------------------------------------------------"
echo "* Test 'hello-world'"
podman run -it hello-world

