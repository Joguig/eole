#!/usr/bin/env python
# -*- coding: UTF-8 -*-
# pylint: disable=C0323,C0301,C0103,C0111,E0213,C0302,C0203,W0703,R0201

from sys import exit, stdout
from traceback import print_exc
import os

versionMajeur = os.environ.get('VM_VERSIONMAJEUR', '?')
utiliseConteneur = os.environ.get('VM_CONTAINER', 'non')
module = os.environ.get('VM_MODULE', '?')

print( "VM_VERSIONMAJEUR=" + versionMajeur )
print( "VM_MODULE=" + module )
print( "VM_CONTAINER=" + utiliseConteneur )

# pas de creole.loader ... en 2.3
if versionMajeur == '2.3':
    exit(0)

try:
    from creole.loader import creole_loader, config_save_values
    config = creole_loader(rw=True)
#   config.creole.general.nom_machine = u'toto'

    if versionMajeur == '2.4.0':
        pass
    if versionMajeur == '2.4.1':
        pass
    if versionMajeur == '2.4.2':
        if module == 'sphynx':
            if config.creole.vpn_pki.x509_locality_name is None:
                config.creole.vpn_pki.x509_locality_name = u'Dijon'
    if versionMajeur == '2.5.0':
        if module == 'sphynx':
            if config.creole.vpn_pki.x509_locality_name is None:
                config.creole.vpn_pki.x509_locality_name = u'Dijon'
    if versionMajeur == '2.5.1':
        if module == 'sphynx':
            if config.creole.vpn_pki.x509_locality_name is None:
                config.creole.vpn_pki.x509_locality_name = u'Dijon'
    if versionMajeur == '2.5.2':
        if module == 'sphynx':
            if config.creole.vpn_pki.x509_locality_name is None:
                config.creole.vpn_pki.x509_locality_name = u'Dijon'
    if versionMajeur == '2.6.0':
        if module == 'sphynx':
            if config.creole.vpn_pki.x509_locality_name is None:
                config.creole.vpn_pki.x509_locality_name = u'Dijon'
        if module == 'zephir':
            if config.creole.messagerie.exim_relay_smtp is None:
                config.creole.messagerie.exim_relay_smtp = u'Dijon'
    if versionMajeur.startswith('2.8'):
        if module == 'scribe':
            if config.creole.eolead.ad_local == 'non':
                config.creole.saslauthd.sasl_ldap_auth_cacert="/root/ca.pem"
                config.creole.saslauthd.sasl_ldap_reader_password="Eole12345!"

    if not config_save_values(config, 'creole', reload_config=False):
        print( "ERREUR CONFIGURATION NON migrée" )
        exit(1)
    else:
        print( "Configuration migrée" )
        exit(0)
except Exception:
    print_exc( limit=None, file=stdout)
    exit(2)
