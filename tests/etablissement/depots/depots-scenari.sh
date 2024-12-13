#!/bin/bash

echo "* Dépots Scenari..."

CreoleSet additional_repository_name --default

ciRunPython CreoleSet_Multi.py <<EOF
set additional_repository_name 0 "Scenari"
set additional_repository_key_type 0 "URL de la clé"
set additional_repository_key_url 0 "https://download.scenari.org/deb/scenari.asc"
set additional_repository_source 0 "deb https://download.scenari.org/deb bionic main"
EOF
ciCheckExitCode $? "creolset"

CreoleGet --list |grep additio

ciQueryAuto
echo "==> $?"

apt-key list | grep -C4 scenari
echo "==> $?"
