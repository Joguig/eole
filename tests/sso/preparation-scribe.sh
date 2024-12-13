#!/bin/bash

ciAptEole eole-sso-cluster-client

CreoleSet eolesso_stunnel_server eolebase.ac-test.fr

ciMonitor reconfigure

CreoleGet --list | grep redis_
CreoleGet --list | grep eolesso_

#redis_client_cert="/etc/ssl/certs/stunnel_client.crt"
#redis_client_key="/etc/ssl/private/stunnel_client.key"
#eolesso_activer_cluster="oui"
#eolesso_adresse="scribe.ac-test.fr"
#eolesso_adresse_parent=""
#eolesso_ca_location=""
#eolesso_cas_folder=""
#eolesso_cert="/etc/ssl/certs/eole.crt"
#eolesso_cluster_server="non"
#eolesso_cookie_domain=""
#eolesso_cookie_name="EoleSSOServer"
#eolesso_css=""
#eolesso_entity_name=""
#eolesso_key="/etc/ssl/private/eole.key"
#eolesso_ldap="localhost"
#eolesso_base_ldap="o=gouv,c=fr"
#eolesso_ldap_infos=""
#eolesso_ldap_label="Annuaire de scribe.domscribe.ac-test.fr"
#eolesso_ldap_match_attribute="uid"
#eolesso_ldap_reader="cn=reader,o=gouv,c=fr"
#eolesso_ldap_reader_passfile="/root/.reader"
#eolesso_port_ldap="389"
#eolesso_ldap_apps_params="non"
#eolesso_metrics="non"
#eolesso_pam_securid="non"
#eolesso_port="8443"
#eolesso_port_parent="8443"
#eolesso_responsive="non"
#eolesso_session_timeout="7200"
#eolesso_stunnel_port="9380"
#eolesso_stunnel_server="192.168.0.24"

ls -al /etc/ssl/certs/stunnel_client.crt

ciSauvegardeCaMachine
