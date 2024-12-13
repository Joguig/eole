#!/bin/bash

echo "* Dépots Firefox..."

CreoleSet additional_repository_name --default

ciRunPython CreoleSet_Multi.py <<EOF
set additional_repository_name 0 Firefox
set additional_repository_source 0 "deb http://ppa.launchpad.net/mozillateam/firefox-next/ubuntu bionic main"
set additional_repository_key_type 0 "serveur de clés"
set additional_repository_key_signserver 0 keyserver.ubuntu.com
set additional_repository_key_fingerprint 0 0AB215679C571D1C8325275B9BDB3D89CE49EC21
EOF
ciCheckExitCode $? "creolset"

CreoleGet --list |grep additio

ciQueryAuto
echo "==> $?"

ciMajAutoSansTest
echo "==> $?"


apt-key list
echo "==> $?"


