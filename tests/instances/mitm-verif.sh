#!/bin/bash

#!/bin/bash

echo "** État du proxy"
if service squid status; then
    echo "Service squid OK"
else
    ciSignalAlerte "Service squid KO"
fi
echo -n "Empreinte de la CA : "
openssl x509 -sha256 -fingerprint -noout -in /etc/eole/squid_CA.crt
ciCheckExitCode "$?"
