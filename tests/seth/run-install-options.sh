#!/bin/bash

ciCopieConfigEol
ciCheckExitCode $?

ciAfficheContenuFichier "/usr/share/eole/creole/distrib/seth-samba.list"
ciAfficheContenuFichier "/etc/apt/sources.list"

ciMajAutoSansTest
ciCheckExitCode $?

if [[ "$(CreoleGet ad_server_role)" == "controleur de domaine" ]]
then
    echo "* CreoleSet ad_internal_dns_backend non"
	CreoleSet ad_internal_dns_backend non

    echo "* CreoleSet ad_backend_store mdb"
    CreoleSet ad_backend_store mdb

    echo "* CreoleSet ad_plaintext_secrets oui"
    CreoleSet ad_plaintext_secrets oui

    ciInstance
    ciCheckExitCode $?

else
    (echo "attente 10 minutes";sleep 600)

    if ciVersionMajeurEgal "2.7.1"
    then
        #ciSignalHack "injection samba4.sh en 2.7.1"
        #cp ./samba4-2.7.1.sh /usr/lib/eole/samba4.sh
        # sera ecrasé si un paquet eole-ad-dc vient !
        ciSignalHack "net -s /dev/null groupmap add sid=S-1-5-32-546 unixgroup=nogroup type=builtin"
        net -s /dev/null groupmap add sid=S-1-5-32-546 unixgroup=nogroup type=builtin
        
        sed -i 's/ 2000-999999/ 100000-999999/' /usr/share/eole/creole/distrib/smb-ad.conf
        grep 'idmap config' /usr/share/eole/creole/distrib/smb-ad.conf
        
        ciSignalHack "injection /usr/lib/eole/samba4.sh"
        cp -v ./samba4-2.7.1.sh /usr/lib/eole/samba4.sh
    fi
    ciInstanceDefault
    ciCheckExitCode $?

    if ciVersionMajeurEgal "2.7.1"
    then
        ciSignalHack "grep 'idmap config' /etc/samba/smb.conf"
        grep 'idmap config' /etc/samba/smb.conf
        
        ciSignalHack "net ads info"
        net ads info
        
        ciSignalHack "net groupmap list"
        net groupmap list
    fi

fi

