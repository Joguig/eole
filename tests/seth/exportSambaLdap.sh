#!/bin/bash

for f in /var/lib/samba/private/sam.ldb /var/lib/samba/private/sam.ldb.d/*
do
    nom=$(basename "$f")
    nom="${nom,,}"

	if [ -f "/tmp/$nom.1" ]
	then
		/bin/mv "/tmp/$nom.1" "/tmp/$nom.2"
	fi
	
	if [ -f "/tmp/$nom.0" ]
	then
		/bin/mv "/tmp/$nom.0" "/tmp/$nom.1"
	fi
	/bin/rm "/tmp/$nom.0" 2>/dev/null
    ldbsearch -H "$f" "*" -o ldif-wrap=no | python3 "/mnt/eole-ci-tests/scripts/ldbsearchUnWrap.py" >"/tmp/$nom.0" 
    echo "$nom" 
    diff "/tmp/$nom.0" "/tmp/$nom.1" 
done
