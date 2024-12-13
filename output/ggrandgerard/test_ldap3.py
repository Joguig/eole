#!/usr/bin/python3
#
# samba-tool ou create OU=OUTEST
# samba-tool ou create OU=OUTEST
# samba-tool user move Titi OU=OUTEST
#
import traceback
import ldap3
from ldap3.utils.log import log, set_library_log_detail_level, ERROR, BASIC, PROTOCOL, NETWORK, EXTENDED, format_ldap_message
from ldap3 import Server, Connection, ALL
from ldap3.core.exceptions import LDAPException

SERVER='ldaps://192.168.0.5'
BASEDN="DC=domseth,DC=ac-test,DC=fr"
USER="Titi@domseth.ac-test.fr"
CURREENTPWD="Eole12345!"

SEARCHFILTER='(&(userPrincipalName='+USER+')(objectClass=person))'
USER_DN=""
PWD_LAST_SET=0

try:
    ldap_server = ldap3.Server(SERVER, get_info=ldap3.ALL)
    conn = ldap3.Connection(ldap_server, USER, CURREENTPWD, auto_bind=True)
    conn.start_tls(read_server_info=True)
    conn.search(search_base = BASEDN,
                search_filter = SEARCHFILTER,
                search_scope = ldap3.SUBTREE,
                attributes = [ 'userPrincipalName', 'pwdLastSet'],
                paged_size = 5)

    for entry in conn.response:
        if entry.get("dn") and entry.get("attributes") and entry.get("attributes").get("userPrincipalName") and entry.get("attributes").get("userPrincipalName") == USER: # to ignore others result (refs)!
            USER_DN=entry.get("dn")
            PWD_LAST_SET=entry.get("attributes").get("pwdLastSet")

    if USER_DN:
        print("DN = " + USER_DN)
        print("pwdLastSet = " + str(PWD_LAST_SET))
        #NEWPWD="new_password"
        #print(ldap3.extend.microsoft.modifyPassword.ad_modify_password(conn, USER_DN, NEWPWD, CURREENTPWD,  controls=None))
    else:
        print("User DN is missing!")
except LDAPException as ldapException:
    print("ERREUR")
    print (vars(ldapException))
    traceback.print_exc()

