# user needs right:
#
# english "replication diretory changes"
#
# under example-domain dc=exampledirsnyc.dc=com in ActiveDiretory User and Computers
#

#!/usr/bin/python
# -*- coding: utf-8 -*-
import getpass
import ldb
from samba.auth import system_session
from samba.credentials import Credentials
from samba.dcerpc import security
from samba.dcerpc.security import dom_sid
from samba.ndr import ndr_pack, ndr_unpack
from samba.param import LoadParm
from samba.samdb import SamDB


from pyasn1.type import univ
from pyasn1.codec.ber import encoder
import pyasn1
from pyasn1.type import univ
from pyasn1.codec.ber import encoder, decoder
from pyasn1.type import tag, namedtype, univ, useful

from pyasn1 import debug

import struct
import sys
import ldap
from ldap.controls import SimplePagedResultsControl
import ldap.async

from ldap.controls import *
from ldap.controls import psearch

import re
import time

import binascii
from distutils.version import StrictVersion

import _ldap


class dirsyncasn1(univ.Sequence):
        componentType = namedtype.NamedTypes(
                namedtype.NamedType('flag', univ.Integer()),
                namedtype.NamedType('size', univ.Integer()),
                namedtype.NamedType('cookie', univ.OctetString()),
        )


# LDAP_SERVER_NOTIFICATION_OID 1.2.840.113556.1.4.528 
# LDAP_SERVER_DIRSYNC_OID      1.2.840.113556.1.4.841

class DirSync(LDAPControl):
  """
  """
  controlType = '1.2.840.113556.1.4.841'  # LDAP_SERVER_DIRSYNC_OID
  encodedControlValue=None

  def __init__(self,criticality=True,size=0,cookie=None,flag=0):
    self.criticality = criticality
    self.size,self.cookie = size,cookie
    self.flag=flag


  def encodeControlValue(self):
        a=dirsyncasn1()
        a.setComponentByName('flag',self.flag)
        a.setComponentByName('size',self.size)
        a.setComponentByName('cookie',self.cookie)

        return encoder.encode(
                       a,
        )
        pass


KNOWN_RESPONSE_CONTROLS[DirSync.controlType]=DirSync

dirsync=DirSync(criticality=True,size=0,cookie='',flag=0)
try:
        # try to read cookie from previous-search
        # if there is not a cookie so its our initialize search
        f=open('/tmp/cookie.bin','rb')
        a=f.read()
        f.close()
        sz=None
        c=None
        f=None
        dir_sync = decoder.decode(a,asn1Spec=dirsyncasn1())
        for ic in range(0,len(dir_sync[0])):
                 nc=dir_sync[0].getNameByPosition(ic)
                 if nc=='size':
                         sz=dir_sync[0].getComponentByName(nc)
                 if nc=='cookie':
                         c=dir_sync[0].getComponentByName(nc)
                 if nc=='flag':
                         f=dir_sync[0].getComponentByName(nc)

        dirsync=DirSync(criticality=True,size=sz,cookie=c,flag=f)

except Exception as e:
        pass
        # print e

LDAP24API = StrictVersion(ldap.__version__) >= StrictVersion('2.4')

url = "ldap://domseth.ac-test.fr"
base = "dc=domseth,dc=ac-test,dc=fr"

search_flt = r'(objectclass=user)'
page_size = 100
att = [ '*' ]

username="user@domseth.ac-test.fr"
password="password"

ldebug=3
level=ldap.SCOPE_SUBTREE

ldap.set_option(ldap.OPT_REFERRALS, 0)
l = None
try:
        l = ldap.initialize(url, trace_level=ldebug)
        l.protocol_version = 3
        l.set_option(ldap.OPT_NETWORK_TIMEOUT, 10.0)
        l.simple_bind_s(username, password)
except Exception as e:
        pass
        sys.exit(1)

msgid = l.search_ext( base, level, search_flt, att, serverctrls=[dirsync,], )
while True:
        try:
                res_type, res_data, res_msgid, serverctrls, a, b = l.result4( msgid, all=1, timeout=10, add_ctrls=1, )

                print (res_data)
                for r in res_data:
                        print (r[0])

                # sys.exit(i)
                for i in serverctrls:

                     if i.controlType==DirSync.controlType:
                        a = bytearray(i.encodedControlValue)
                        dir_sync = decoder.decode( i.encodedControlValue, asn1Spec=dirsyncasn1() )
                        print (a)
                        #f=open('/tmp/cookie.bin','wb')
                        #f.write(a)
                        #f.close()

                if dir_sync:
                        n = None
                        sz = None
                        f = None
                        for ic in range(0,len(dir_sync[0])):
                                nc=dir_sync[0].getNameByPosition(ic)
                                # n=dir_sync[0].getComponentByName(nc)
                                if nc=='size':
                                        sz=dir_sync[0].getComponentByName(nc)
                                if nc=='cookie':
                                        c=dir_sync[0].getComponentByName(nc)
                                if nc=='flag':
                                        f=dir_sync[0].getComponentByName(nc)

                        if f!=0:
                                dirsync=DirSync(criticality=True,size=sz,cookie=c,flag=f)
                                msgid = l.search_ext( base, level, search_flt, att, serverctrls=[dirsync] )
                        else:
                                break

                else:
                       pass
                       break

        except Exception as e:
                print (e)
                sys.exit(1)
