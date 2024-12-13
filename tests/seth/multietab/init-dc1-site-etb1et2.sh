#!/bin/bash

if [ -f "/etc/eole/samba4-vars.conf" ]
then
    #shellcheck disable=SC1091
    . "/etc/eole/samba4-vars.conf"
else
    # Template is disabled => samba is disabled
    exit 0
fi

# shellcheck disable=SC1091
. /usr/lib/eole/ihm.sh

# shellcheck disable=SC1091
. /usr/lib/eole/samba4.sh

BASEDN="DC=${AD_REALM//./,DC=}"
echo "BASEDN: $BASEDN"
echo "CONFIGURATION: $1"

samba-tool domain passwordsettings set --complexity=off
samba-tool domain passwordsettings set --min-pwd-length=4

echo "* Create or Update Sites List (Seth >= 2.6.2)"
AD_HOST_IP_NETMASK="$(CreoleGet adresse_netmask_eth0)"
AD_HOST_IP_NETWORK="$(CreoleGet adresse_network_eth0)"
echo "*AD_HOST_IP_NETMASK=$AD_HOST_IP_NETMASK"
cdr=$(mask2cdr "${AD_HOST_IP_NETMASK}" )
echo "* cdr=$cdr"
cidr="${AD_HOST_IP_NETWORK}/${cdr}"
echo "* cidr=$cidr"

samba_update_site "Default-First-Site-Name" "$cidr"
samba_update_site "00000001" "10.1.0.0/16"
samba_update_site "00000002" "10.2.0.0/16"

echo "* Update DNS"
samba_dnsupdate --verbose --all-names

