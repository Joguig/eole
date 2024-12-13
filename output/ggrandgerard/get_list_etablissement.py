# -*- coding: utf-8 -*-
from scribe.eoleldap import Ldap
from ldap import  SCOPE_ONELEVEL, modlist
from scribe.ldapconf import SUFFIX, acad, num_etab

def get_liste_etabs_without_rne():
    conn = Ldap()
    conn.connect()
    suffix = "ou=%s,ou=education,%s" % (acad, SUFFIX)
    etabs = conn.connexion.search_s(suffix, SCOPE_ONELEVEL,'(ou=*)', ['ou'])
    conn.close()
    if etabs == None:
        raise Exception('Impossible de récuperer des établissements dans %s' % suffix)
    list_etabs = []
    for etab in etabs:
        list_etabs.extend(etab[1]['ou'])
    if num_etab not in list_etabs:
        raise Exception('Pas de branche LDAP pour le numéro établissement source %s ' % num_etab)
    list_etabs.remove(num_etab)
    return list_etabs

if __name__ == '__main__':
    print ('\n'.join( get_liste_etabs_without_rne() ) )