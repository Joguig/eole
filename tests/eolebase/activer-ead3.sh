#!/bin/bash
if [ "$(CreoleGet activer_ead3)" != oui ]
then
    echo "* Maj Auto"
    ciMajAuto
    ciCheckExitCode "$?"
    
    echo "* Install EAD3"
    ciAptEole eole-ead3
    ciCheckExitCode "$?"
    
    echo "* Activer EAD3"
    CreoleSet activer_ead3 oui
    ciCheckExitCode "$?"
    
    echo "* reconfigure"
    ciMonitor reconfigure
    ciCheckExitCode "$?"
else
	echo "* EAD déjà actif"
fi
exit 0