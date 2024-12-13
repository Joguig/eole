#!/bin/bash

ciCopieConfigEol
ciCheckExitCode $?

sed -i -e 's/4.7/4.9/' /usr/share/eole/creole/distrib/seth-samba.list
ciCheckExitCode $?

ciAfficheContenuFichier "/usr/share/eole/creole/distrib/seth-samba.list"
ciAfficheContenuFichier "/etc/apt/sources.list"

ciMajAutoSansTest
ciCheckExitCode $?

echo "ad_server_role=$(CreoleGet ad_server_role)"

if [[ "$(CreoleGet ad_server_role)" == "controleur de domaine" ]]
then
    echo "ad_internal_dns_backend=$(CreoleGet ad_internal_dns_backend)"
    
    echo "* CreoleSet ad_internal_dns_backend non"
	CreoleSet ad_internal_dns_backend non
fi

ciInstance
ciCheckExitCode $?
