#!/bin/bash 

ciExtendsLvmRoot

set -x 

if [ -f /etc/apt/sources.list.d/runner_gitlab-runner.list ]
then
    /bin/rm -f /etc/apt/sources.list.d/runner_gitlab-runner.list
fi

apt-get update
apt-get upgrade -y

if ! command -v lxc
then
    apt-get install -y lxc lxc-utils
fi

if ! command -v lxd
then
    if [ -f /etc/apparmor.d/usr.lib.snapd.snap-confine.real ]
    then
        /bin/rm -f /etc/apparmor.d/usr.lib.snapd.snap-confine.real
    fi
    apt-get install -y lxd
fi
#if ! command -v snapd 
#then
#    apt-get install -y snapd
#fi

#if [ ! -d /lxc-ci ]
#then
#    cd /root || exit 1
#    git clone https://github.com/lxc/lxc-ci.git
#    mv lxc-ci/ /
#fi
#cd /lxc-ci/ || exit 1

cat >/tmp/lxd-init.yaml <<EOF
config: {}
networks:
- config:
    ipv4.address: auto
    ipv6.address: auto
  description: ""
  name: lxdbr0
  type: ""
storage_pools:
- config:
    size: 5GB
  description: ""
  name: default
  driver: zfs
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      network: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
cluster: null
EOF

lxd init --preseed < /tmp/lxd-init.yaml

if [ ! -f /usr/bin/distrobuilder ]
then
    cd /root ||exit 1
    apt install -y golang-go debootstrap rsync gpg squashfs-tools git
    git clone https://github.com/lxc/distrobuilder
    cd distrobuilder ||exit 1
    make
    "$HOME/go/bin/distrobuilder"
    cp "$HOME/go/bin/distrobuilder" /usr/bin
    chmod +x /usr/bin/distrobuilder
    cd /root ||exit 1
    /bin/rm -rf /root/distrobuilder
fi

if [ ! -f /etc/dnsmasq.d/lxc ]
then
    /bin/rm /etc/dnsmasq.d/lxc
fi