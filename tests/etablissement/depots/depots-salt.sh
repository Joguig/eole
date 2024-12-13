#!/bin/bash
echo "* Dépots Salt..."

CreoleSet additional_repository_name --default

ciRunPython CreoleSet_Multi.py <<EOF
set additional_repository_name 0 salt
set additional_repository_key_type 0 "URL de la clé"
set additional_repository_key_url 0 "https://packages.broadcom.com/apt/ubuntu/18.04/amd64/latest/SALTSTACK-GPG-KEY.pub"
set additional_repository_source 0 "deb http://packages.broadcom.com/apt/ubuntu/18.04/amd64/latest bionic main"
EOF
ciCheckExitCode $? "creolset"

CreoleGet --list |grep additio

ciQueryAuto
echo "==> $?"

ciMajAutoSansTest
echo "==> $?"

apt-key list | grep saltstack
echo "==> $?"

