#!/bin/bash
echo "$0 : début vers $1"

if [ -z "$1" ] 
then
    echo "la destination n'est pas définie"
    exit 1
fi

absolute=$(echo "$1" | cut -c 1)
if [ "$absolute" == "/" ]
then
    backup_dir=$1
else
	# shellcheck disable=SC1091,SC1090
    source /root/getVMContext.sh NO_DISPLAY

    CONFIGURATION=$1
    if [ -z "$VM_VERSIONMAJEUR" ]
    then
        backup_dir=/mnt/eole-ci-tests/configuration/$VM_MACHINE/$CONFIGURATION/
    else
        backup_dir=/mnt/eole-ci-tests/configuration/$VM_MACHINE/$CONFIGURATION-$VM_VERSIONMAJEUR/
    fi
fi

echo "Destination : $backup_dir"
[ ! -d "$backup_dir" ] && mkdir "$backup_dir"

echo "- Configuration Eole"
rsync --relative --recursive --links --perms --times /etc/eole/config.eol "$backup_dir"

if ciVersionMajeurEgal "2.3"
then
    cp /etc/eole/config.eol "$backup_dir"/etc/eole/config.ini
else
    cp /etc/eole/config.eol "$backup_dir"/etc/eole/config.non_formate
    python3 /mnt/eole-ci-tests/scripts/formatConfigEol1.py <"/etc/eole/config.eol" >"$backup_dir/etc/eole/config.eol"
fi

echo "- Configuration dicos locaux"
rsync --relative --recursive --links --perms --times /usr/share/eole/creole/dicos/local "$backup_dir"

echo "- Configuration dicos variante"
rsync --relative --recursive --links --perms --times /usr/share/eole/creole/dicos/variante "$backup_dir"

echo "- Configuration creole patch"
rsync --relative --recursive --links --perms --times /usr/share/eole/creole/patch "$backup_dir"
(ls /usr/share/eole/bastion/data/70* 2>/dev/null ) && rsync --relative --recursive --links --perms --times /usr/share/eole/bastion/data/70* "$backup_dir"

echo "- Configuration SSL"
[ ! -d "$backup_dir"/etc/ssl/ ]                            && mkdir "$backup_dir"/etc/ssl/ 
[ ! -d "$backup_dir"/etc/ssl/private/ ]                    && mkdir "$backup_dir"/etc/ssl/private 
[ ! -d "$backup_dir"/etc/ssl/certs/ ]                      && mkdir "$backup_dir"/etc/ssl/certs 
[ ! -d "$backup_dir"/etc/ssl/req/ ]                        && mkdir "$backup_dir"/etc/ssl/req 
[ -f "$backup_dir"/etc/ssl/eole.crl ]                      && cp /etc/ssl/eole.crl           "$backup_dir"/etc/ssl/eole.crl
[ -f "$backup_dir"/etc/ssl/private/ca.key ]                && cp /etc/ssl/private/ca.key     "$backup_dir"/etc/ssl/private/ca.key
[ -f "$backup_dir"/etc/ssl/certs/ca_local.crt ]            && cp /etc/ssl/certs/ca_local.crt "$backup_dir"/etc/ssl/certs/ca_local.crt
[ -f "$backup_dir"/etc/ssl/certs/eole.crt ]                && cp /etc/ssl/certs/eole.crt     "$backup_dir"/etc/ssl/certs/eole.crt
[ -f "$backup_dir"/etc/ssl/certs/eole.key ]                && cp /etc/ssl/certs/eole.key     "$backup_dir"/etc/ssl/certs/eole.key
[ -f "$backup_dir"/etc/ssl/certs/eole.pem ]                && cp /etc/ssl/certs/eole.pem     "$backup_dir"/etc/ssl/certs/eole.pem
[ -f "$backup_dir"/etc/ssl/req/eole.p10 ]                  && cp /etc/ssl/req/eole.p10       "$backup_dir"/etc/ssl/req/eole.p10
[ -f "$backup_dir"/etc/ssl/serial ]                        && cp /etc/ssl/serial             "$backup_dir"/etc/ssl/serial
[ -f "$backup_dir"/etc/ssl/dh ]                            && cp /etc/ssl/dh                 "$backup_dir"/etc/ssl/dh
[ -f "$backup_dir"/etc/ssl/index.txt ]                     && cp /etc/ssl/index.txt          "$backup_dir"/etc/ssl/index.txt
[ -f "$backup_dir"/etc/ssl/index.txt.attr ]                && cp /etc/ssl/index.txt.attr     "$backup_dir"/etc/ssl/index.txt.attr
[ -f "$backup_dir"/etc/ssl/openssl.cnf ]                   && cp /etc/ssl/openssl.cnf        "$backup_dir"/etc/ssl/openssl.cnf
 
echo "Sauvegarde en cours, patientez ..."
pushd "$backup_dir" >/dev/null 2>&1 || exit 1  

if [ -d /var/lib/arv ]
then
    echo "- base ARV + Strongswan"
    rsync --relative --recursive --links --perms --times /etc/ipsec* "$backup_dir"
    rsync --relative --recursive --links --perms --times /var/lib/arv/* "$backup_dir"
    echo '.dump' | sqlite3 /var/lib/arv/db/sphynxdb.sqlite >"$backup_dir/var/lib/arv/db/sphynxdb.sql"

    echo "- Clés de connexion (les clés ssh root sont utilisées dans le cas de la Haute Dispo)"
    rsync --relative --recursive --links --perms --times /root/.ssh/* "$backup_dir"
fi

# retour au répertoire d'origine
popd >/dev/null 2>&1 || exit 1
