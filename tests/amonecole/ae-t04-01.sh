#!/bin/bash

echo "* Change revproxy..."

CreoleSet revprox_redirection_http --default
CreoleSet revprox_domainname --default

ciRunPython CreoleSet_Multi.py <<EOF
set revprox_redirection_http "non"

set revprox_domainname 0 "etb3.ac-test.fr"
set revprox_domain_wildcard 0 "non"
set revprox_http 0 "oui"
set revprox_https 0 "non"
set revprox_rep 0 "/"
set revprox_url 0 "http://10.3.2.49"
EOF

ciCheckExitCode $? "creolset"

ciMonitor reconfigure

CreoleGet --list |grep revproxy
