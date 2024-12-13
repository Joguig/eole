#!/bin/bash

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

exit 0