#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
# pep8: --ignore=E201,E202,E211,E501
# pylint: disable=C0323,C0301,C0103,C0111,E0213,C0302,C0203,W0703,R0201,W0105,W0107,W0702,E0401

import sys
import os
from arv.db.initialize import initialize_database
from arv.lib.usezephir import Zephir
from arv.lib.sw_config_apply import ipsec_conf_apply

try:
    from creole.config import INSTANCE_LOCKFILE
    if not os.path.isfile(INSTANCE_LOCKFILE):
        print("Serveur non instancié !!!!!")
        sys.exit(1)
except:
    ' en 2.3 !'
    pass

try:
    zephir = Zephir(user='arv', password='eole')
    initialize_database()
    ipsec_conf_apply(zephir=zephir)
except:
    initialize_database()
    ipsec_conf_apply(zephir=None)
