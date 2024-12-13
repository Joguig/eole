#!/bin/bash
# shellcheck disable=SC2034,SC2148

export DEBIAN_FRONTEND=noninteractive

ciSignalHack "* inject sympa.db sqllite !"
[ -d /etc/sympa ] || mkdir /etc/sympa
[ -d /etc/sympa/sympa ] || mkdir /etc/sympa/sympa
cat >/etc/sympa/sympa/sympa.conf <<EOF 
domain  eole
listmaster  listmaster@eole
lang    fr
db_type SQLite
db_name /var/lib/sympa/sympa
cookie  \$(/usr/bin/head -n1 /etc/sympa/cookie)
wwsympa_url http://eole/wws
static_content_path /usr/share/sympa/static_content
use_fast_cgi    1
css_path    /var/lib/sympa/css
css_url /css-sympa
pictures_path   /var/lib/sympa/pictures
pictures_url    /pictures-sympa
EOF
[ -d /var/lib/sympa ] || mkdir /var/lib/sympa
touch /var/lib/sympa/sympa
chown sympa:sympa /var/lib/sympa/sympa
           
ciSignalHack "* debconf-set-selections sympa"
debconf-set-selections <<EOF
sympa   sympa/app-password-confirm  password    
sympa   sympa/password-confirm  password    
sympa   wwsympa/webserver_type  select  Other
# Database type to be used by sympa:
sympa   sympa/database-type select  sqlite3
# Delete the database for sympa?
sympa   sympa/purge boolean false
sympa   sympa/language  select  fr
#sympa   sympa/passwords-do-not-match    error   
sympa   sympa/remove-error  select  abort
sympa   wwsympa/wwsympa_url string  http://eole/wws
# SQLite database name for sympa:
sympa   sympa/db/dbname string  sympa
# Reinstall database for sympa?
sympa   sympa/dbconfig-reinstall    boolean false
sympa   sympa/internal/skip-preseed boolean false
# Back up the database for sympa before upgrading?
sympa   sympa/upgrade-backup    boolean false
# Deconfigure database for sympa with dbconfig-common?
sympa   sympa/dbconfig-remove   boolean false
sympa   sympa/internal/reconfiguring    boolean false
# Do you want the sympa SOAP server to be used?
sympa   sympa/use_soap  boolean false
sympa   sympa/upgrade-error select  ignore
sympa   wwsympa/fastcgi boolean true
sympa   sympa/remove_spool  boolean false
sympa   wwsympa/remove_spool    boolean false
sympa   sympa/missing-db-package-error  select  abort
sympa   sympa/listmaster    string  listmaster@eole
sympa   sympa/hostname  string  eole
# Perform upgrade on database for sympa with dbconfig-common?
sympa   sympa/dbconfig-upgrade  boolean false
# Configure database for sympa with dbconfig-common?
sympa   sympa/dbconfig-install  boolean false
sympa   sympa/install-error select  ignore
# SQLite storage directory for sympa:
sympa   sympa/db/basepath   string  /var/lib/dbconfig-common/sqlite3/sympa
EOF
# /var/lib/dpkg/info/sympa.config
#ls -l /var/lib/dpkg/info/sympa.config

