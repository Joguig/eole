#!/usr/bin/python3

# user needs right:
#
# english "replication diretory changes"
#
# under example-domain dc=exampledirsnyc.dc=com in ActiveDiretory User and Computers
#

from __future__ import print_function
import optparse
import sys
import base64
import copy
import getpass

import ldb
from ldb import SCOPE_BASE, SCOPE_SUBTREE
import samba
from samba.auth import system_session
from samba.credentials import Credentials
from samba.dcerpc import security
from samba.dcerpc.security import dom_sid
from samba.ndr import ndr_pack, ndr_unpack
from samba.param import LoadParm
from samba.samdb import SamDB
from samba.samba3 import param as s3param
from samba.samba3 import libsmb_samba_internal as libsmb
import samba.getopt as options
from samba import gensec
from samba.credentials import (
    Credentials,
    AUTO_USE_KERBEROS,
    DONT_USE_KERBEROS,
    MUST_USE_KERBEROS,
)

parser = optparse.OptionParser("dc1_query [options] <host>")
sambaopts = options.SambaOptions(parser)
parser.add_option_group(sambaopts)

# use command line creds if available
credopts = options.CredentialsOptions(parser)
parser.add_option_group(credopts)
opts, args = parser.parse_args()

if len(args) < 1:
    parser.print_usage()
    sys.exit(1)
print (vars(opts))
print (args)

lp = LoadParm()
lp.load_default()

#lp = sambaopts.get_loadparm()
creds = credopts.get_credentials(lp, fallback_machine=True)
debugLevel = int(sambaopts._lp.get('debug level'))


#creds = Credentials()
#creds.guess(lp)

if False:
    print("local")

if False:
    print("credential")
    creds.set_username('Administrator')
    creds.set_password('Eole12345!')

if False:
    print("kerberos")
    creds.set_username('Administrator')
    creds.set_password('Eole12345!')

print( "creds1 ***************" )
creds1 = Credentials()
creds1.guess(lp)
creds1.set_kerberos_state(DONT_USE_KERBEROS)
creds1.
#creds1.set_cmdline_callbacks()
# possibly fallback to using the machine account, if we have
# access to the secrets db

s3_lp = s3param.get_context()
s3_lp.load(lp.configfile)
conn = libsmb.Conn("dc1.domseth.ac-test.fr", "sysvol", lp=lp, creds=creds1, sign=False)
print ( str(conn)) 

sys.exit(0)

for s in lp.services():
    print( "--------------------------" )
    print( s )
    print( "--------------------------" )
    deny_list = lp.get("hosts deny", s)
    print ( str(deny_list) )
    allow_list = lp.get("hosts allow", s)
    print ( str(allow_list)  )


# record 193
# dn: CN=Partage1,OU=UO1,DC=domseth,DC=ac-test,DC=fr
# objectClass: top
# objectClass: leaf
# objectClass: connectionPoint
# objectClass: volume
# cn: Partage1
# instanceType: 4
# whenCreated: 20200319162931.0Z
# whenChanged: 20200319162931.0Z
# uSNCreated: 4235
# uSNChanged: 4235
# name: Partage1
# objectGUID: 175ab198-a6df-4841-bfd4-c642be23fe51
# uNCName: \\file.domseth.ac-test.fr\partage1
# objectCategory: CN=Volume,CN=Schema,CN=Configuration,DC=domseth,DC=ac-test,DC=fr
# distinguishedName: CN=Partage1,OU=UO1,DC=domseth,DC=ac-test,DC=fr
samdb = SamDB(url='ldap://domseth.ac-test.fr:389', session_info=system_session(),credentials=creds, lp=lp)

result = samdb.search('DC=domseth,DC=ac-test,DC=fr', expression="(objectclass=volume)", scope=ldb.SCOPE_SUBTREE)
for item in result:
    dn=str(item['dn'])
    distinguishedName=str(item['distinguishedName'])
    cn=str(item['cn'])
    name=str(item['name'])
    objectCategory=str(item['objectCategory'])
    objectClass=item['objectClass']
    keywords=item['keywords']
    uNCName=str(item['uNCName'])
    instanceType=str(item['instanceType'])
    whenCreated=str(item['whenCreated'])
    whenChanged=str(item['whenChanged'])
    uSNCreated=str(item['uSNCreated'])
    uSNChanged=str(item['uSNChanged'])
    objectGUID=str(item['objectGUID'])
    managedBy=str(item['managedBy'])
    description=str(item['description'])
    
    print( dn )
    print( distinguishedName )
    print( cn )
    print( name )
    print( objectCategory )
    print( uNCName )
    for oc in objectClass:
        print (oc)
    for k in keywords:
        print (k)
    print( instanceType )
    print( whenCreated )
    print( whenChanged )
    print( uSNCreated )
    print( uSNChanged )
    # print( objectGUID ) binaire ! 
    print( managedBy )
    print( description )
    
    
print ( "---")
