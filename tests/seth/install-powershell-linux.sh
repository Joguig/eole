#!/bin/bash -x

#POWERSHELL_HOME=$BASE/powershell
#POWERSHELL_VERSION=6.0.0
#POWERSHELL_UBUNTU_VERSION=powershell_${POWERSHELL_VERSION}-1ubuntu1.16.04.1_amd64

#wget https://github.com/Microsoft/omi/releases/download/v1.1.0-0/omi-1.1.0.ssl_100.x64.deb

ciSetHttpProxy

if ! command -v curl >/dev/null 2>&1
then
    apt-get install -y curl
fi

if ! command -v git >/dev/null 2>&1
then
    apt-get install -y git
fi

if [ ! -f /etc/apt/sources.list.d/microsoft.list ]
then
    # Import the public repository GPG keys
    curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

    # Register the Microsoft Ubuntu repository
    
    if [ "$(lsb_release -is)" == "LinuxMint" ]
    then
       URL="https://packages.microsoft.com/config/ubuntu/18.04/prod.list"
    else
       URL="https://packages.microsoft.com/config/ubuntu/$(lsb_release -r -s)/prod.list"
    fi
    echo "URL=$URL" 
    curl "$URL" | sudo tee /etc/apt/sources.list.d/microsoft.list
    # Update apt-get
    sudo apt-get update
fi


if ! command -v pwsh >/dev/null 2>&1
then
    # Install PowerShell
    sudo apt-get install -y powershell
fi

# Start PowerShell
pwsh -V

pwsh "${0/.sh/.ps1}"


#if [ ! -d /opt/omi/bin ]
#then
#    dpkg -i "$POWERSHELL_HOME/omi-1.1.0.ssl_100.x64.deb"
#fi
#if [ ! -d /opt/microsoft/dsc/ ]
#then
#    dpkg -i "$POWERSHELL_HOME/dsc-1.1.1-294.ssl_100.x64.deb"
#fi
#if [ ! -f /opt/omi/lib/libpsrpomiprov.so ]
#then
#    dpkg -i "$POWERSHELL_HOME/psrp-1.0.0-0.universal.x64.deb"
#fi
PATH=/opt/microsoft/dsc/bin:/opt/microsoft/powershell/6.0.0:/opt/omi/bin:$PATH

