#!/usr/bin/env python
# -*- coding: UTF-8 -*-
# pylint: disable=E0401
import traceback
import sys
import os
import ldap
from scribe.errors import LdapExistingGroup
from scribe.eolegroup import Group

sys.path.append('/usr/share')
from ead2.backend.actions.scribe.tool.etablissements import add_etab

name =  sys.argv[1]
print("Ajout de l'établissement {}".format(name))
try:
    add_etab(name)
except ldap.ALREADY_EXISTS as existe:
    pass
except Exception as e:
    traceback.print_stack(e)

grp = Group()
try:
    print('Ajout de groupe Etablissement ' + name)
    grp.add('Etablissement', name, domaine='restreint', partage='rw', description=name)
except LdapExistingGroup as existe:
    pass
except Exception as e:
    traceback.print_stack(e)

try:
    print('Ajout de eleves-' + name)
    grp.add('Base', 'eleves-' + name, etab=name, description='eleves-' + name)
except LdapExistingGroup as existe:
    pass
except Exception as e:
    traceback.print_stack(e)

try:
    print('Ajout de profs-' + name)
    grp.add('Base', 'profs-' + name, partage='rw', etab=name, description='profs-' + name)
except LdapExistingGroup as existe:
    pass
except Exception as e:
    traceback.print_stack(e)

try:
    print('Ajout de admin-' + name)
    grp.add('Groupe', 'admin-' + name, etab=name, description='admin-' + name)
except LdapExistingGroup as existe:
    pass
except Exception as e:
    traceback.print_stack(e)

try:
    print('Ajout de invite-' + name)
    grp.add('Base', 'invite-' + name, etab=name, description='invite-' + name)
except LdapExistingGroup as existe:
    pass
except Exception as e:
    traceback.print_stack(e)


if os.path.isfile('/usr/sbin/checkmultietab'):
    os.system('/usr/sbin/checkmultietab')
