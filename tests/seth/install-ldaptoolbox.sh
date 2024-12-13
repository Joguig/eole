#!/bin/bash -x

ciSetHttpProxy

export DEBIAN_FRONTEND=noninteractive
if ! command -v curl >/dev/null 2>&1
then
    apt-get install -y curl
fi

if ! command -v git >/dev/null 2>&1
then
    apt-get install -y git
fi

if [ ! -f /etc/apt/sources.list.d/ltb-project.list ]
then
    # Import the public repository GPG keys
    curl https://ltb-project.org/lib/RPM-GPG-KEY-LTB-project | sudo apt-key add -

    # Register the Microsoft Ubuntu repository
    (
        echo "deb     https://ltb-project.org/debian/wheezy wheezy main"
        echo "deb-src https://ltb-project.org/debian/wheezy wheezy main"
    ) | sudo tee /etc/apt/sources.list.d/ltb-project.list
        
    # Update apt-get
    sudo apt-get update
fi

if ! command -v powershell >/dev/null 2>&1
then
    # Install openldap-ltb
    sudo apt-get install openldap-ltb
fi

